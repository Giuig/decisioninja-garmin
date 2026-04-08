# Decisioninja

A Garmin port of [Decisioninja](https://github.com/Giuig/decisioninja) - a decision-making companion app for Garmin Instinct 3 Solar 45mm.

## Features

- **Binary** - Choose between two options (YES/NO, LEFT/RIGHT, HEADS/TAILS)
- **Dice** - Roll dice with customizable dice type (D4, D6, D8, D10, D12, D20)
- **Pointer** - Get a random direction
- **Settings** - Configure binary mode, dice count, dice type, and vibration

## Device Compatibility

- Garmin Instinct 3 Solar 45mm
- May work on other MI display devices (untested)

## Installation

1. Build the app using the Garmin Connect IQ SDK
2. Transfer to your device via Garmin Express or Connect app

## Development

### Prerequisites

- Garmin Connect IQ SDK 5.1.0+
- VS Code with Monkey C extension

### Build

```bash
monkeyc -f monkey.jungle -o bin/decisioninjagarmin.prg -y your-key.p12
```

## License

This project is for personal use.

## Credits

- Built with Garmin Connect IQ
