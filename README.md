# Waste Glass Collection App

A Flutter Android application and .NET Web API backend for managing a daily waste-glass collection route. The app guides a collector through an optimized supplier sequence, verifies each supplier through barcode scanning, records clear and coloured glass quantities, and produces a final trip report with shortfall warnings and server sync.

## Assignment Coverage

This project was built for the Mobile Intern technical task. It includes:

- A Flutter Android mobile app with exactly three main screens.
- A custom .NET backend designed from scratch.
- A hosted PostgreSQL database using Supabase.
- Backend route optimization using Haversine distance and Dijkstra-based route ordering.
- Barcode based supplier check in with no manual supplier override.
- Offline first collection saving using local SQLite on the mobile device.
- Final trip report and sync to server flow.

## Tech Stack

### Mobile App

- Flutter
- Dart
- Provider for state management
- `mobile_scanner` for barcode scanning
- SQLite / `sqflite` for offline local collection storage
- HTTP client for API communication

### Backend

- .NET 8
- ASP.NET Core Web API
- Entity Framework Core
- PostgreSQL via Supabase
- Swagger / OpenAPI for API testing

### Database

- Supabase PostgreSQL for hosted backend data
- SQLite on Android device for offline-first collection records

## Why Supabase PostgreSQL + SQLite?

Supabase PostgreSQL was selected as the hosted database because the assignment requires a live backend/database that can be accessed during evaluation. PostgreSQL is reliable for relational data.

SQLite is used inside the Flutter app because the collection process must continue even if mobile connectivity is unavailable during the route. Each collection record is saved locally first, then synced to the backend from the final report screen.

## Main Features

### Screen 1 - Trip Sequence

- Loads today's route from the .NET backend when the app opens.
- Displays the optimized supplier stop sequence.
- Shows each stop status: `Pending`, `Next`, or `Collected`.
- Shows total route distance and remaining stops.
- Updates after each successful collection.

### Screen 2 - Scan & Collect

- Shows the current next supplier destination.
- Scans the supplier barcode.
- Verifies that the scanned supplier ID matches the expected current stop.
- Blocks incorrect supplier barcodes.
- Unlocks the quantity form only after a correct barcode scan.
- Captures:
  - Clear glass quantity in kg
  - Coloured glass quantity in kg
  - Glass condition
- Saves the collection locally and submits it to the backend.
- Advances to the next stop after confirmation.

### Screen 3 - Analytics / Trip Report

- Locked until all stops are completed.
- Shows total kg collected.
- Shows total route distance.
- Shows trip duration.
- Shows per-supplier collection summary.
- Displays shortfall warnings when collected quantity is below expected quantity.
- Provides a `Sync to server` button to push locally saved records to the backend.

## Barcode Test Data

Supplier IDs are used as barcode values. Barcode generation is handled as an external test asset, not inside the app or backend.

Use Code 128 barcodes for these supplier codes:

| Supplier Code | Supplier Name |
|---|---|
| SUP001 | Pettah Bottle Supplier |
| SUP002 | Fort Hotel Waste Point |
| SUP003 | Maradana Glass Store |
| SUP004 | Borella Recycling Supplier |
| SUP005 | Narahenpita Bottle Collection |

The optimized route starts with `SUP003` because the backend sorts stops based on route optimization, not supplier-code order.

Expected demo order:

```text
SUP003 -> SUP004 -> SUP005 -> SUP001 -> SUP002
```

## Route Optimization

The backend calculates distances between the collector start location and supplier GPS coordinates using the Haversine formula:

```text
a = sin²(Δlat/2) + cos(lat1) * cos(lat2) * sin²(Δlon/2)
c = 2 * atan2(√a, √(1-a))
d = R * c
```

where `R = 6371 km`.

These distances are used as edge weights in a graph. A Dijkstra based approach is applied to determine the shortest ordered supplier stop sequence from the collector's starting location.

## API Endpoints

Base URL for local testing:

```text
http://localhost:5057
```

Before building the final APK, replace the local base URL with the hosted backend URL.

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/api/trips/today` | Returns today's optimized trip sequence with statuses and distance |
| POST | `/api/collections` | Accepts collection submission by supplier code and updates trip status |
| GET | `/api/trips/today/report` | Returns final trip report data |
| POST | `/api/collections/sync` | Syncs locally saved collection records to backend |
| POST | `/api/trips/reset-demo` | Development-only endpoint to reset demo trip data |

## Project Structure

```text
waste-glass-collection-app/
│
├── backend/
│   └── WasteGlass.Api/
│       ├── Controllers/
│       ├── Data/
│       ├── Dtos/
│       ├── Models/
│       ├── Services/
│       ├── Program.cs
│       └── appsettings.json
│
├── mobile/
│   └── waste_glass_app/
│       ├── lib/
│       │   ├── models/
│       │   ├── providers/
│       │   ├── screens/
│       │   ├── services/
│       │   ├── widgets/
│       │   └── main.dart
│       ├── assets/
│       ├── android/
│       └── pubspec.yaml
│
├── barcodes/
│   └── printable_barcodes.html
│
└── README.md
```

## Backend Setup

### Prerequisites

- .NET 8 SDK
- PostgreSQL database or Supabase project
- Entity Framework Core tools

### Run Backend Locally

```powershell
cd backend/WasteGlass.Api
dotnet restore
dotnet build
dotnet run
```

The API should run on:

```text
http://localhost:5057
```

Swagger is available at:

```text
http://localhost:5057/swagger
```

### Database Connection

Use a Supabase PostgreSQL connection string in local development.

Example format:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=YOUR_SUPABASE_HOST;Database=postgres;Username=YOUR_USERNAME;Password=YOUR_PASSWORD;SSL Mode=Require;Trust Server Certificate=true"
  }
}
```

Do not commit real database passwords to GitHub.

Recommended safe options:

- Use `.gitignore` for local secret files.
- Use environment variables in production.
- Use Render/Railway/Azure environment settings for deployed backend secrets.

## Flutter App Setup

### Prerequisites

- Flutter SDK
- Android Studio
- Android SDK
- Real Android device or emulator
- USB debugging enabled if using a real phone

### Install Packages

```powershell
cd mobile/waste_glass_app
flutter pub get
```

### Local Backend Testing With Real Android Device

Start the backend first:

```powershell
cd backend/WasteGlass.Api
dotnet run
```

Then in the Flutter project:

```powershell
cd mobile/waste_glass_app
adb reverse tcp:5057 tcp:5057
flutter run
```

The `adb reverse` command allows the Android device to access the local backend using:

```text
http://localhost:5057
```

## Building the Final APK

Before building the APK, update the Flutter API base URL in:

```text
mobile/waste_glass_app/lib/services/api_service.dart
```

Change:

```dart
static const String baseUrl = 'http://localhost:5057';
```

to the hosted backend URL, for example:

```dart
static const String baseUrl = 'https://your-hosted-api-url.onrender.com';
```

Then build the release APK:

```powershell
cd mobile/waste_glass_app
flutter clean
flutter pub get
flutter build apk --release
```

The APK will be generated at:

```text
mobile/waste_glass_app/build/app/outputs/flutter-apk/app-release.apk
```

## Demo Flow for Screen Recording

Use a real Android device or emulator. Display the barcode images on another device or from the `barcodes/printable_barcodes.html` file.

Record this complete flow:

1. Open the app.
2. Route loads from the backend.
3. Screen 1 shows the optimized stop sequence.
4. Tap `Scan` or `Scan next supplier`.
5. Scan the current supplier barcode.
6. Correct barcode unlocks the form.
7. Enter clear glass kg, coloured glass kg, and condition.
8. Confirm the collection.
9. Status updates to `Collected`.
10. Repeat until all stops are completed.
11. Open the Analytics / Trip Report screen.
12. Show total kg, route distance, duration, and supplier summaries.
13. Show at least one shortfall warning by entering less than the expected quantity for one supplier.
14. Tap `Sync to server`.
15. Show the final success message.

## Sample Demo Input

| Supplier | Clear kg | Coloured kg | Condition | Expected Result |
|---|---:|---:|---|---|
| SUP003 | 40 | 20 | Good | Shortfall warning |
| SUP004 | 45 | 25 | Mixed | Shortfall warning |
| SUP005 | 50 | 30 | Needs sorting | No shortfall if expected is 80 kg |
| SUP001 | 40 | 20 | Clean and dry | No shortfall if expected is 60 kg |
| SUP002 | 50 | 30 | Contaminated | No shortfall if expected is 80 kg |

## Final Submission Checklist

- [ ] Full Flutter frontend pushed to GitHub
- [ ] Full .NET backend pushed to GitHub
- [ ] README with setup instructions included
- [ ] Supabase PostgreSQL database live
- [ ] .NET API hosted and accessible
- [ ] APK points to hosted backend URL, not localhost
- [ ] Release APK built successfully
- [ ] Screen recording completed on real/emulated Android device
- [ ] Video shows route load, barcode scan, form unlock, confirmation, status update, completed report, shortfall warning, and sync

## Notes

- There is no login/authentication because the assignment specifies no authentication.
- Barcode generation is not included inside the app or backend because barcode images are external test assets.
- Local SQLite protects collection data if backend connectivity fails during the trip.
- The final `Sync to server` action confirms locally saved records with the backend.
