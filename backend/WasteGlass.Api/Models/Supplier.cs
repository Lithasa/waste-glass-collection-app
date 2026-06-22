namespace WasteGlass.Api.Models;

public class Supplier
{
    public int Id { get; set; }

    public string SupplierCode { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;

    public double Latitude { get; set; }
    public double Longitude { get; set; }

    public decimal ExpectedClearKg { get; set; }
    public decimal ExpectedColouredKg { get; set; }

    public string BarcodeValue { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<TripStop> TripStops { get; set; } = new List<TripStop>();
    public ICollection<CollectionRecord> CollectionRecords { get; set; } = new List<CollectionRecord>();
}