using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using WasteGlass.Api.Data;
using WasteGlass.Api.Models;
using WasteGlass.Api.Services;

namespace WasteGlass.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TripsController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly IRouteService _routeService;

    private const double StartLatitude = 6.9271;
    private const double StartLongitude = 79.8612;

    public TripsController(AppDbContext db, IRouteService routeService)
    {
        _db = db;
        _routeService = routeService;
    }

    [HttpGet("today")]
    public async Task<IActionResult> GetTodayTrip()
    {
        var trip = await GetOrCreateTodayTrip();

        return Ok(ToTripResponse(trip));
    }

    [HttpGet("today/report")]
    public async Task<IActionResult> GetTodayTripReport()
    {
        var trip = await GetTodayTripWithDetails();

        if (trip == null)
        {
            return NotFound(new { message = "No trip found for today." });
        }

        var records = await _db.CollectionRecords
            .Include(c => c.Supplier)
            .Where(c => c.TripId == trip.Id)
            .ToListAsync();

        var supplierSummaries = trip.Stops
            .OrderBy(s => s.SequenceNo)
            .Select(stop =>
            {
                var supplier = stop.Supplier!;
                var record = records.FirstOrDefault(r => r.SupplierId == supplier.Id);

                var collectedClearKg = record?.ClearKg ?? 0;
                var collectedColouredKg = record?.ColouredKg ?? 0;
                var totalCollectedKg = collectedClearKg + collectedColouredKg;
                var expectedTotalKg = supplier.ExpectedClearKg + supplier.ExpectedColouredKg;

                return new
                {
                    stop.SequenceNo,
                    supplier.SupplierCode,
                    supplier.Name,
                    supplier.Address,
                    ExpectedTotalKg = expectedTotalKg,
                    ClearKg = collectedClearKg,
                    ColouredKg = collectedColouredKg,
                    TotalCollectedKg = totalCollectedKg,
                    Condition = record?.Condition,
                    stop.Status,
                    ShortfallWarning = totalCollectedKg < expectedTotalKg
                };
            })
            .ToList();

        var totalKg = supplierSummaries.Sum(x => x.TotalCollectedKg);
        var durationMinutes = trip.CompletedAt.HasValue
            ? Math.Round((trip.CompletedAt.Value - trip.StartedAt).TotalMinutes, 2)
            : Math.Round((DateTime.UtcNow - trip.StartedAt).TotalMinutes, 2);

        return Ok(new
        {
            trip.Id,
            trip.TripDate,
            trip.Status,
            RouteDistanceKm = Math.Round(trip.TotalDistanceKm, 2),
            DurationMinutes = durationMinutes,
            TotalKgCollected = totalKg,
            Suppliers = supplierSummaries
        });
    }

    [HttpPost("reset-demo")]
    public async Task<IActionResult> ResetDemoTrip()
    {
        var today = DateTime.UtcNow.Date;
        var tomorrow = today.AddDays(1);

        var todayTrips = await _db.Trips
            .Where(t => t.TripDate >= today && t.TripDate < tomorrow)
            .ToListAsync();

        _db.Trips.RemoveRange(todayTrips);
        await _db.SaveChangesAsync();

        var trip = await GetOrCreateTodayTrip();

        return Ok(new
        {
            message = "Demo trip reset successfully.",
            trip = ToTripResponse(trip)
        });
    }

    private async Task<Trip> GetOrCreateTodayTrip()
    {
        var existingTrip = await GetTodayTripWithDetails();

        if (existingTrip != null)
        {
            return existingTrip;
        }

        var suppliers = await _db.Suppliers
            .OrderBy(s => s.Id)
            .ToListAsync();

        var routePlan = _routeService.BuildOptimalRoute(StartLatitude, StartLongitude, suppliers);

        var trip = new Trip
        {
            TripDate = DateTime.UtcNow.Date,
            StartLatitude = StartLatitude,
            StartLongitude = StartLongitude,
            TotalDistanceKm = routePlan.Sum(r => r.DistanceFromPreviousKm),
            StartedAt = DateTime.UtcNow,
            Status = "InProgress"
        };

        _db.Trips.Add(trip);
        await _db.SaveChangesAsync();

        var sequence = 1;

        foreach (var stopPlan in routePlan)
        {
            _db.TripStops.Add(new TripStop
            {
                TripId = trip.Id,
                SupplierId = stopPlan.SupplierId,
                SequenceNo = sequence,
                DistanceFromPreviousKm = stopPlan.DistanceFromPreviousKm,
                Status = sequence == 1 ? "Next" : "Pending"
            });

            sequence++;
        }

        await _db.SaveChangesAsync();

        return await GetTodayTripWithDetails()
               ?? throw new InvalidOperationException("Unable to create today's trip.");
    }

    private async Task<Trip?> GetTodayTripWithDetails()
    {
        var today = DateTime.UtcNow.Date;
        var tomorrow = today.AddDays(1);

        return await _db.Trips
            .Include(t => t.Stops)
            .ThenInclude(s => s.Supplier)
            .FirstOrDefaultAsync(t => t.TripDate >= today && t.TripDate < tomorrow);
    }

    private static object ToTripResponse(Trip trip)
    {
        var orderedStops = trip.Stops.OrderBy(s => s.SequenceNo).ToList();

        return new
        {
            trip.Id,
            trip.TripDate,
            trip.Status,
            StartLocation = new
            {
                Latitude = trip.StartLatitude,
                Longitude = trip.StartLongitude
            },
            TotalRouteDistanceKm = Math.Round(trip.TotalDistanceKm, 2),
            RemainingStops = orderedStops.Count(s => s.Status != "Collected"),
            Stops = orderedStops.Select(stop => new
            {
                stop.Id,
                stop.SequenceNo,
                stop.Status,
                stop.DistanceFromPreviousKm,
                Supplier = new
                {
                    stop.Supplier!.SupplierCode,
                    stop.Supplier.Name,
                    stop.Supplier.Address,
                    stop.Supplier.Latitude,
                    stop.Supplier.Longitude,
                    stop.Supplier.ExpectedClearKg,
                    stop.Supplier.ExpectedColouredKg,
                    ExpectedTotalKg = stop.Supplier.ExpectedClearKg + stop.Supplier.ExpectedColouredKg,
                    stop.Supplier.BarcodeValue
                }
            })
        };
    }
}