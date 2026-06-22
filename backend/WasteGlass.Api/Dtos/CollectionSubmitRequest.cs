namespace WasteGlass.Api.Dtos;

public class CollectionSubmitRequest
{
    public string SupplierCode { get; set; } = string.Empty;
    public decimal ClearKg { get; set; }
    public decimal ColouredKg { get; set; }
    public string Condition { get; set; } = string.Empty;
    public string? LocalRecordId { get; set; }
    public DateTime? CollectedAt { get; set; }
}