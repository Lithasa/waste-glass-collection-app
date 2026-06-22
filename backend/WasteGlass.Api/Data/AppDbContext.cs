using Microsoft.EntityFrameworkCore;
using WasteGlass.Api.Models;

namespace WasteGlass.Api.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<Supplier> Suppliers => Set<Supplier>();
    public DbSet<Trip> Trips => Set<Trip>();
    public DbSet<TripStop> TripStops => Set<TripStop>();
    public DbSet<CollectionRecord> CollectionRecords => Set<CollectionRecord>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Supplier>().ToTable("suppliers");
        modelBuilder.Entity<Trip>().ToTable("trips");
        modelBuilder.Entity<TripStop>().ToTable("trip_stops");
        modelBuilder.Entity<CollectionRecord>().ToTable("collection_records");

        modelBuilder.Entity<Supplier>()
            .HasIndex(s => s.SupplierCode)
            .IsUnique();

        modelBuilder.Entity<Supplier>()
            .HasIndex(s => s.BarcodeValue)
            .IsUnique();

        modelBuilder.Entity<Supplier>()
            .Property(s => s.ExpectedClearKg)
            .HasPrecision(10, 2);

        modelBuilder.Entity<Supplier>()
            .Property(s => s.ExpectedColouredKg)
            .HasPrecision(10, 2);

        modelBuilder.Entity<CollectionRecord>()
            .Property(c => c.ClearKg)
            .HasPrecision(10, 2);

        modelBuilder.Entity<CollectionRecord>()
            .Property(c => c.ColouredKg)
            .HasPrecision(10, 2);

        modelBuilder.Entity<TripStop>()
            .HasOne(ts => ts.Trip)
            .WithMany(t => t.Stops)
            .HasForeignKey(ts => ts.TripId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<TripStop>()
            .HasOne(ts => ts.Supplier)
            .WithMany(s => s.TripStops)
            .HasForeignKey(ts => ts.SupplierId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<CollectionRecord>()
            .HasOne(c => c.Trip)
            .WithMany(t => t.CollectionRecords)
            .HasForeignKey(c => c.TripId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<CollectionRecord>()
            .HasOne(c => c.Supplier)
            .WithMany(s => s.CollectionRecords)
            .HasForeignKey(c => c.SupplierId)
            .OnDelete(DeleteBehavior.Restrict);

        var seedDate = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        modelBuilder.Entity<Supplier>().HasData(
            new Supplier
            {
                Id = 1,
                SupplierCode = "SUP001",
                Name = "Pettah Bottle Supplier",
                Address = "Pettah, Colombo",
                Latitude = 6.9366,
                Longitude = 79.8497,
                ExpectedClearKg = 40,
                ExpectedColouredKg = 20,
                BarcodeValue = "SUP001",
                CreatedAt = seedDate
            },
            new Supplier
            {
                Id = 2,
                SupplierCode = "SUP002",
                Name = "Fort Hotel Waste Point",
                Address = "Fort, Colombo",
                Latitude = 6.9344,
                Longitude = 79.8428,
                ExpectedClearKg = 35,
                ExpectedColouredKg = 25,
                BarcodeValue = "SUP002",
                CreatedAt = seedDate
            },
            new Supplier
            {
                Id = 3,
                SupplierCode = "SUP003",
                Name = "Maradana Glass Store",
                Address = "Maradana, Colombo",
                Latitude = 6.9259,
                Longitude = 79.8648,
                ExpectedClearKg = 50,
                ExpectedColouredKg = 30,
                BarcodeValue = "SUP003",
                CreatedAt = seedDate
            },
            new Supplier
            {
                Id = 4,
                SupplierCode = "SUP004",
                Name = "Borella Recycling Supplier",
                Address = "Borella, Colombo",
                Latitude = 6.9147,
                Longitude = 79.8778,
                ExpectedClearKg = 45,
                ExpectedColouredKg = 35,
                BarcodeValue = "SUP004",
                CreatedAt = seedDate
            },
            new Supplier
            {
                Id = 5,
                SupplierCode = "SUP005",
                Name = "Narahenpita Bottle Collection",
                Address = "Narahenpita, Colombo",
                Latitude = 6.8897,
                Longitude = 79.8794,
                ExpectedClearKg = 55,
                ExpectedColouredKg = 25,
                BarcodeValue = "SUP005",
                CreatedAt = seedDate
            }
        );
    }
}