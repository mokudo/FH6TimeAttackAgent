# FH6 Time Attack Agent

macOS SwiftUI app for Forza Horizon 6 Data Out telemetry.

## Important

This project is coded with AI assistance. Review and test changes carefully before using the app for serious telemetry analysis or distributing builds.

## Features

- Receives FH6 Data Out UDP packets on macOS.
- Parses the fixed 324-byte FH6 packet format, including lap time, vehicle position, player inputs, tire slip, `NormalizedDrivingLine`, and `NormalizedAIBrakeDifference`.
- Records detailed lap samples for time attack sessions.
- Reviews each completed lap with:
  - speed-colored driving line map
  - detected braking zones
  - line offset events
  - tire slip events
  - coaching suggestions for braking points, racing line, throttle timing, and stability
- Exports saved session data as JSON from the review sheet.

## Forza Horizon 6 Settings

In Forza Horizon 6, open `Settings > HUD and Gameplay` and configure:

- `Data Out`: On
- `Data Out IP Address`: the Mac IP address shown in the app
- `Data Out IP Port`: `5301` by default

FH6 sends one-way UDP packets only while the player is actively driving. The official documentation recommends avoiding ports `5200` through `5300`, so the app defaults to `5301`.

Reference: [Forza Horizon 6 "Data Out" Documentation](https://support.forza.net/hc/en-us/articles/51744149102611-Forza-Horizon-6-Data-Out-Documentation)

## Development

Open `FH6TimeAttackAgent.xcodeproj` in Xcode and run the `FH6TimeAttackAgent` scheme on `My Mac`.

The app targets macOS 14.0 or later.
