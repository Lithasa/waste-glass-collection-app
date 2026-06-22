namespace WasteGlass.Api.Models;

public class TripStop
{
    public int Id { get; set; }

    public int TripId { get; set; }
    public Trip? Trip { get; set; }

    public int SupplierId { get; set; }
    public Supplier? Supplier { get; set; }

    public int SequenceNo { get; set; }

    public double DistanceFromPreviousKm { get; set; }

    public string Status { get; set; } = "Pending";
}