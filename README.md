# Weather App - iOS Final Project

A fully functional iOS weather application built with Swift and UIKit, demonstrating core iOS development concepts including UI components, Auto Layout, networking, and data persistence.

## Features

### Core Functionality
- **Current Weather**: Display detailed current weather conditions for your location or selected city
- **Daily Forecast**: View weather forecast for up to 16 days
- **City Search**: Search and discover cities worldwide
- **Favorites**: Save and manage favorite cities
- **Custom Titles**: Personalize city names with custom titles
- **Notes**: Add personal notes for each city

## Project Structure

```
final/
├── Weather/
│   ├── App/
│   │   ├── WeatherAppConfig.swift      # API configuration
│   │   ├── WeatherServices.swift       # Service instances
│   │   └── LocationService.swift       # CoreLocation wrapper
│   ├── Models/
│   │   ├── City.swift                  # City data model
│   │   ├── WeatherSettings.swift       # App settings model
│   │   ├── OpenMeteoGeocodingResponse.swift
│   │   └── OpenMeteoForecastResponse.swift
│   ├── Services/
│   │   └── OpenMeteoAPI.swift          # Networking layer
│   ├── Storage/
│   │   └── WeatherStorage.swift        # UserDefaults wrapper
│   └── UI/
│       ├── TodayViewController.swift   # Home tab
│       ├── ExploreViewController.swift # Search & Favorites
│       ├── SettingsViewController.swift
│       ├── CityDetailsViewController.swift
│       ├── CityTableViewCell.swift     # Custom table cell
│       ├── ShimmerView.swift           # Loading skeleton
│       └── WeatherCode.swift           # Weather icon mapping
├── Base.lproj/
│   └── Main.storyboard                 # UI layout
└── finalTests/
    ├── finalTests.swift                # API decoding tests
    └── WeatherStorageTests.swift       # Storage tests
```

## Setup & Running

1. **Open Project**
   ```bash
   open final.xcodeproj
   ```

2. **Select Scheme**
   - Choose `final` scheme
   - Select target device or simulator

3. **Build & Run**
   - Press `Cmd + R` or click Run button
   - App will request location permissions on first launch

## API

The app uses [Open-Meteo](https://open-meteo.com/) API (no API key required):
- **Geocoding API**: Search cities by name
- **Forecast API**: Current weather, hourly, and daily forecasts

Base URLs are configured in `WeatherAppConfig.swift`.

## Testing

Run unit tests:
```bash
Cmd + U
```

Tests cover:
- API response decoding (geocoding and forecast)
- Storage operations (favorites, settings, notes)

## License

Educational project for iOS Development course.
