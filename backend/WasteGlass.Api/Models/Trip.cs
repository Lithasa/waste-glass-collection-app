namespace WasteGlass.Api.Models;

public class Trip
{
    public int Id { get; set; }

    public DateTime TripDate { get; set; }

    public double StartLatitude { get; set; }
    public double StartLongitude { get; set; }

    public double TotalDistanceKm { get; set; }

    public DateTime StartedAt { get; set; } = DateTime.UtcNow;
    public DateTime? CompletedAt { get; set; }

    public string Status { get; set; } = "InProgress";

    public ICollection<TripStop> Stops { get; set; } = new List<TripStop>();
    public ICollection<CollectionRecord> CollectionRecords { get; set; } = new List<CollectionRecord>();
}