using WasteGlass.Api.Models;

namespace WasteGlass.Api.Services;

public record RouteStopPlan(int SupplierId, double DistanceFromPreviousKm);

public interface IRouteService
{
    double HaversineKm(double lat1, double lon1, double lat2, double lon2);
    List<RouteStopPlan> BuildOptimalRoute(double startLat, double startLon, List<Supplier> suppliers);
}

public class RouteService : IRouteService
{
    private const double EarthRadiusKm = 6371;

    public double HaversineKm(double lat1, double lon1, double lat2, double lon2)
    {
        double ToRadians(double angle) => Math.PI * angle / 180.0;

        var dLat = ToRadians(lat2 - lat1);
        var dLon = ToRadians(lon2 - lon1);

        lat1 = ToRadians(lat1);
        lat2 = ToRadians(lat2);

        var a = Math.Pow(Math.Sin(dLat / 2), 2)
                + Math.Cos(lat1) * Math.Cos(lat2) * Math.Pow(Math.Sin(dLon / 2), 2);

        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));

        return EarthRadiusKm * c;
    }

    public List<RouteStopPlan> BuildOptimalRoute(double startLat, double startLon, List<Supplier> suppliers)
    {
        if (suppliers.Count == 0)
        {
            return new List<RouteStopPlan>();
        }

        var nodeCount = suppliers.Count + 1;
        var graph = new double[nodeCount, nodeCount];

        for (var i = 0; i < nodeCount; i++)
        {
            for (var j = 0; j < nodeCount; j++)
            {
                if (i == j)
                {
                    graph[i, j] = 0;
                    continue;
                }

                var firstLat = i == 0 ? startLat : suppliers[i - 1].Latitude;
                var firstLon = i == 0 ? startLon : suppliers[i - 1].Longitude;
                var secondLat = j == 0 ? startLat : suppliers[j - 1].Latitude;
                var secondLon = j == 0 ? startLon : suppliers[j - 1].Longitude;

                graph[i, j] = HaversineKm(firstLat, firstLon, secondLat, secondLon);
            }
        }

        var route = new List<RouteStopPlan>();
        var unvisitedSupplierNodeIndexes = new HashSet<int>(Enumerable.Range(1, suppliers.Count));
        var currentNodeIndex = 0;

        while (unvisitedSupplierNodeIndexes.Count > 0)
        {
            var distances = Dijkstra(graph, currentNodeIndex);

            var nextNodeIndex = unvisitedSupplierNodeIndexes
                .OrderBy(index => distances[index])
                .First();

            var supplier = suppliers[nextNodeIndex - 1];

            route.Add(new RouteStopPlan(
                supplier.Id,
                Math.Round(distances[nextNodeIndex], 2)
            ));

            unvisitedSupplierNodeIndexes.Remove(nextNodeIndex);
            currentNodeIndex = nextNodeIndex;
        }

        return route;
    }

    private static double[] Dijkstra(double[,] graph, int source)
    {
        var nodeCount = graph.GetLength(0);
        var distances = new double[nodeCount];
        var visited = new bool[nodeCount];

        for (var i = 0; i < nodeCount; i++)
        {
            distances[i] = double.MaxValue;
        }

        distances[source] = 0;

        for (var count = 0; count < nodeCount - 1; count++)
        {
            var u = MinDistance(distances, visited);

            if (u == -1)
            {
                break;
            }

            visited[u] = true;

            for (var v = 0; v < nodeCount; v++)
            {
                if (!visited[v]
                    && graph[u, v] > 0
                    && distances[u] != double.MaxValue
                    && distances[u] + graph[u, v] < distances[v])
                {
                    distances[v] = distances[u] + graph[u, v];
                }
            }
        }

        return distances;
    }

    private static int MinDistance(double[] distances, bool[] visited)
    {
        var min = double.MaxValue;
        var minIndex = -1;

        for (var i = 0; i < distances.Length; i++)
        {
            if (!visited[i] && distances[i] <= min)
            {
                min = distances[i];
                minIndex = i;
            }
        }

        return minIndex;
    }
}