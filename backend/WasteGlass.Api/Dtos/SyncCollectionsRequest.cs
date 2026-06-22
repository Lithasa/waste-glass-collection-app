namespace WasteGlass.Api.Dtos;

public class SyncCollectionsRequest
{
    public List<CollectionSubmitRequest> Records { get; set; } = new();
}