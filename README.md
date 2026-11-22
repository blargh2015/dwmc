# Dude Where's My Car (DWMC)

A simple Factorio mod that helps you find your last vehicle.

## Features

- **Arrow Indicator**: Displays an orange arrow on your screen pointing to the last vehicle you were in
- **Distance Alert**: Plays a car horn sound when you get too far away from your last vehicle
- **Configurable Distance**: Adjust the alert distance threshold (default: 200 tiles, range: 10-1000 tiles)

## How It Works

1. When you exit a vehicle, the mod remembers its location
2. An orange arrow appears on your screen pointing toward that vehicle
3. If you move more than the configured distance away, a car horn sound will play and a bell emoji appears at your position
4. The arrow updates in real-time as both you and the vehicle move
5. If the vehicle is destroyed, the arrow disappears and the tracking stops

## Settings

- **Alert Distance**: The distance in tiles from your last vehicle before the horn alert triggers (default: 200)

## Installation

1. Copy the DWMC folder to your Factorio `mods/` directory
2. Enable the mod in your game or mod manager
3. Adjust settings as desired

## Notes

- Only tracks the last vehicle you were in on your current surface
- Arrow is only visible to the player whose vehicle it's tracking
- The mod uses Factorio's rendering system for the arrow, so it won't be visible to other players
