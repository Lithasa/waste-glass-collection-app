using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WasteGlass.Api.Data;
using WasteGlass.Api.Dtos;
using WasteGlass.Api.Models;

namespace WasteGlass.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CollectionsController : ControllerBase
{
    private readonly AppDbContext _db;

    public CollectionsController(AppDbContext db)
    {
        _db = db;
    }

    [HttpPost]
    public async Task<IActionResult> SubmitCollection(CollectionSubmitRequest request)
    {
        var result = await ProcessCollection(request);

        if (!result.Success)
        {
            return BadRequest(new { message = result.Message });
        }

        return Ok(result.Payload);
    }

    [HttpPost("sync")]
    public async Task<IActionResult> SyncCollections(SyncCollectionsRequest request)
    {
        if (request.Records.Count == 0)
        {
            return BadRequest(new { message = "No collection records provided for sync." });
        }

        var results = new List<object>();

        foreach (var record in request.Records)
        {
            var result = await ProcessCollection(record);

            results.Add(new
            {
                record.SupplierCode,
                result.Success,
                result.Message
            });
        }

        return Ok(new
        {
            message = "Sync completed.",
            results
        });
    }

    private async Task<CollectionProcessResult> ProcessCollection(CollectionSubmitRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.SupplierCode))
        {
            return CollectionProcessResult.Fail("Supplier code is required.");
        }

        if (request.ClearKg < 0 || request.ColouredKg < 0)
        {
            return CollectionProcessResult.Fail("Collection quantities cannot be negative.");
        }

        var trip = await GetTodayTrip();

        if (trip == null)
        {
            return CollectionProcessResult.Fail("No active trip found for today. Load today's trip first.");
        }

        if (trip.Status == "Completed")
        {
            return CollectionProcessResult.Fail("Today’s trip is already completed.");
        }

        if (!string.IsNullOrWhiteSpace(request.LocalRecordId))
        {
            var existingLocalRecord = await _db.CollectionRecords
                .FirstOrDefaultAsync(c => c.LocalRecordId == request.LocalRecordId);

            if (existingLocalRecord != null)
            {
                return CollectionProcessResult.Ok("Record already synced.", new
                {
                    existingLocalRecord.Id,
                    existingLocalRecord.SupplierId
                });
            }
        }

        var nextStop = trip.Stops
            .OrderBy(s => s.SequenceNo)
            .FirstOrDefault(s => s.Status == "Next");

        if (nextStop == null)
        {
            return CollectionProcessResult.Fail("No next supplier stop found.");
        }

        var scannedCode = request.SupplierCode.Trim();

        if (!string.Equals(nextStop.Supplier!.SupplierCode, scannedCode, StringComparison.OrdinalIgnoreCase))
        {
            return CollectionProcessResult.Fail(
                $"Wrong supplier barcode. Expected {nextStop.Supplier.SupplierCode}, but scanned {scannedCode}."
            );
        }

        var existingRecord = await _db.CollectionRecords
            .FirstOrDefaultAsync(c => c.TripId == trip.Id && c.SupplierId == nextStop.SupplierId);

        if (existingRecord != null)
        {
            return CollectionProcessResult.Fail("Collection for this supplier has already been submitted.");
        }

        var collectionRecord = new CollectionRecord
        {
            TripId = trip.Id,
            SupplierId = nextStop.SupplierId,
            ClearKg = request.ClearKg,
            ColouredKg = request.ColouredKg,
            Condition = request.Condition,
            CollectedAt = request.CollectedAt ?? DateTime.UtcNow,
            IsSynced = true,
            LocalRecordId = request.LocalRecordId
        };

        _db.CollectionRecords.Add(collectionRecord);

        nextStop.Status = "Collected";

        var followingStop = trip.Stops
            .OrderBy(s => s.SequenceNo)
            .FirstOrDefault(s => s.Status == "Pending");

        if (followingStop != null)
        {
            followingStop.Status = "Next";
        }
        else
        {
            trip.Status = "Completed";
            trip.CompletedAt = DateTime.UtcNow;
        }

        await _db.SaveChangesAsync();

        return CollectionProcessResult.Ok("Collection submitted successfully.", new
        {
            collectionRecord.Id,
            SupplierCode = nextStop.Supplier.SupplierCode,
            nextStop.Supplier.Name,
            ClearKg = collectionRecord.ClearKg,
            ColouredKg = collectionRecord.ColouredKg,
            TotalKg = collectionRecord.ClearKg + collectionRecord.ColouredKg,
            TripStatus = trip.Status,
            NextSupplier = followingStop == null ? null : new
            {
                followingStop.Supplier!.SupplierCode,
                followingStop.Supplier.Name,
                followingStop.SequenceNo
            }
        });
    }

    private async Task<Trip?> GetTodayTrip()
    {
        var today = DateTime.UtcNow.Date;
        var tomorrow = today.AddDays(1);

        return await _db.Trips
            .Include(t => t.Stops)
            .ThenInclude(s => s.Supplier)
            .FirstOrDefaultAsync(t => t.TripDate >= today && t.TripDate < tomorrow);
    }

    private record CollectionProcessResult(bool Success, string Message, object? Payload)
    {
        public static CollectionProcessResult Ok(string message, object? payload)
            => new(true, message, payload);

        public static CollectionProcessResult Fail(string message)
            => new(false, message, null);
    }
}