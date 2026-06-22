using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace WasteGlass.Api.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "suppliers",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    SupplierCode = table.Column<string>(type: "text", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Address = table.Column<string>(type: "text", nullable: false),
                    Latitude = table.Column<double>(type: "double precision", nullable: false),
                    Longitude = table.Column<double>(type: "double precision", nullable: false),
                    ExpectedClearKg = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    ExpectedColouredKg = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    BarcodeValue = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_suppliers", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "trips",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    TripDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    StartLatitude = table.Column<double>(type: "double precision", nullable: false),
                    StartLongitude = table.Column<double>(type: "double precision", nullable: false),
                    TotalDistanceKm = table.Column<double>(type: "double precision", nullable: false),
                    StartedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CompletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Status = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_trips", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "collection_records",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    TripId = table.Column<int>(type: "integer", nullable: false),
                    SupplierId = table.Column<int>(type: "integer", nullable: false),
                    ClearKg = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    ColouredKg = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    Condition = table.Column<string>(type: "text", nullable: false),
                    CollectedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsSynced = table.Column<bool>(type: "boolean", nullable: false),
                    LocalRecordId = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_collection_records", x => x.Id);
                    table.ForeignKey(
                        name: "FK_collection_records_suppliers_SupplierId",
                        column: x => x.SupplierId,
                        principalTable: "suppliers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_collection_records_trips_TripId",
                        column: x => x.TripId,
                        principalTable: "trips",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "trip_stops",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    TripId = table.Column<int>(type: "integer", nullable: false),
                    SupplierId = table.Column<int>(type: "integer", nullable: false),
                    SequenceNo = table.Column<int>(type: "integer", nullable: false),
                    DistanceFromPreviousKm = table.Column<double>(type: "double precision", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_trip_stops", x => x.Id);
                    table.ForeignKey(
                        name: "FK_trip_stops_suppliers_SupplierId",
                        column: x => x.SupplierId,
                        principalTable: "suppliers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_trip_stops_trips_TripId",
                        column: x => x.TripId,
                        principalTable: "trips",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "suppliers",
                columns: new[] { "Id", "Address", "BarcodeValue", "CreatedAt", "ExpectedClearKg", "ExpectedColouredKg", "Latitude", "Longitude", "Name", "SupplierCode" },
                values: new object[,]
                {
                    { 1, "Pettah, Colombo", "SUP001", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 40m, 20m, 6.9366000000000003, 79.849699999999999, "Pettah Bottle Supplier", "SUP001" },
                    { 2, "Fort, Colombo", "SUP002", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 35m, 25m, 6.9344000000000001, 79.842799999999997, "Fort Hotel Waste Point", "SUP002" },
                    { 3, "Maradana, Colombo", "SUP003", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 50m, 30m, 6.9259000000000004, 79.864800000000002, "Maradana Glass Store", "SUP003" },
                    { 4, "Borella, Colombo", "SUP004", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 45m, 35m, 6.9146999999999998, 79.877799999999993, "Borella Recycling Supplier", "SUP004" },
                    { 5, "Narahenpita, Colombo", "SUP005", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), 55m, 25m, 6.8897000000000004, 79.879400000000004, "Narahenpita Bottle Collection", "SUP005" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_collection_records_SupplierId",
                table: "collection_records",
                column: "SupplierId");

            migrationBuilder.CreateIndex(
                name: "IX_collection_records_TripId",
                table: "collection_records",
                column: "TripId");

            migrationBuilder.CreateIndex(
                name: "IX_suppliers_BarcodeValue",
                table: "suppliers",
                column: "BarcodeValue",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_suppliers_SupplierCode",
                table: "suppliers",
                column: "SupplierCode",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_trip_stops_SupplierId",
                table: "trip_stops",
                column: "SupplierId");

            migrationBuilder.CreateIndex(
                name: "IX_trip_stops_TripId",
                table: "trip_stops",
                column: "TripId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "collection_records");

            migrationBuilder.DropTable(
                name: "trip_stops");

            migrationBuilder.DropTable(
                name: "suppliers");

            migrationBuilder.DropTable(
                name: "trips");
        }
    }
}
