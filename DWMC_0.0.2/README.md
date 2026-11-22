# Dude Where's My Car (DWMC)

A simple Factorio mod that helps you find your last vehicle.

## Features

- **Vehicle Pin**: Shows a marker on your car once you're beyond the alert distance, with a directional arrow at the screen edge when the car is off-screen
- **Distance Alert**: Plays a car horn sound when you get too far away from your last vehicle
- **Configurable Distance**: Adjust the alert distance threshold (default: 25 tiles, range: 10-1000 tiles)

## How It Works

1. When you exit a vehicle, the mod remembers its location
2. Once you move farther than the configured distance away, a horn plays and a temporary map pin appears on the vehicle
3. If the vehicle goes off-screen, its pin turns into a directional marker at the screen edge
4. Returning within the alert distance removes the pin; the pin follows the vehicle if it moves
5. If the vehicle is destroyed, the pin disappears and tracking stops

## Settings

- **Alert Distance**: The distance in tiles from your last vehicle before the horn alert triggers (default: 25)

## Installation

1. Copy the DWMC folder to your Factorio `mods/` directory
2. Enable the mod in your game or mod manager
3. Adjust settings as desired

## Notes

- Only tracks the last vehicle you were in on your current surface
- Arrow is only visible to the player whose vehicle it's tracking
- The pin belongs to the player whose car is tracked, so it won't be visible to other players
