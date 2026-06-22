namespace WasteGlass.Api.Models;

public class CollectionRecord
{
    public int Id { get; set; }

    public int TripId { get; set; }
    public Trip? Trip { get; set; }

    public int SupplierId { get; set; }
    public Supplier? Supplier { get; set; }

    public decimal ClearKg { get; set; }
    public decimal ColouredKg { get; set; }

    public string Condition { get; set; } = string.Empty;

    public DateTime CollectedAt { get; set; } = DateTime.UtcNow;

    public bool IsSynced { get; set; } = true;

    public string? LocalRecordId { get; set; }
}