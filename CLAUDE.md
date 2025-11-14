# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

expo-haishinkit is an Expo native module that provides RTMP live streaming capabilities for React Native applications. It wraps the HaishinKit library (v2.0.9) to enable professional-grade streaming to platforms like YouTube Live, Twitch, and Facebook.

## Development Commands

### Module Development
```bash
# Build the module
npm run build

# Clean build artifacts
npm run clean

# Run linting
npm run lint

# Run tests
npm run test

# Prepare module
npm run prepare

# Open iOS project in Xcode
npm run open:ios

# Open Android project in Android Studio
npm run open:android
```

### Example App Development
```bash
cd example

# Start development server
npm start

# Run on iOS
npm run ios

# Run on Android
npm run android

# Run on web
npm run web
```

## Architecture

### Module Structure
```
expo-HaishinKit/
├── src/                     # TypeScript source files
│   ├── index.ts            # Main module exports
│   ├── ExpoHaishinkit.ts   # Native module interface
│   ├── ExpoHaishinkit.types.ts # Type definitions
│   ├── ExpoHaishinkitView.tsx  # React component wrapper
│   └── ExpoHaishinkitView.web.tsx # Web fallback
├── ios/                     # iOS native implementation
│   ├── ExpoHaishinkitView.swift # Main iOS view (369 lines)
│   ├── ExpoHaishinkitModule.swift # Module definition
│   └── ExpoHaishinkit.podspec # CocoaPods spec
├── android/                 # Android implementation (stub)
│   └── src/main/java/.../ExpoHaishinkitView.kt
└── example/                 # Demo application
    └── App.tsx             # Complete streaming UI example
```

### Data Flow Architecture

The module implements a 4-layer bridge pattern:

1. **React Layer** → TypeScript component with ref methods
2. **JSI Bridge** → Expo Modules Core handles native communication
3. **Platform Layer** → Swift (iOS) / Kotlin (Android) implementation
4. **HaishinKit** → Native RTMP streaming library

### Key iOS Implementation Details

The iOS implementation (`ios/ExpoHaishinkitView.swift`) follows Flutter's HaishinKit initialization sequence:

1. **Lazy Initialization**: MediaMixer created with `useManualCapture: true` to avoid iOS 18 bugs
2. **Audio Session**: Configured before any streaming setup
3. **Permission Handling**: Checks camera/microphone permissions before device attachment
4. **Connection Management**: Async/await pattern for RTMP connection with retry logic
5. **Event System**: Native events for connection and stream status changes

### Critical Implementation Patterns

#### Camera Switching with Mirroring
```swift
// Per-camera mirroring states maintained separately
private var mirrorStates: [String: Bool] = [
    "front": true,   // Front camera defaults to mirrored
    "back": false    // Back camera not mirrored
]
```

#### Connection Sequence
1. Check permissions
2. Attach devices (camera/microphone)
3. Connect to RTMP server
4. Auto-publish on successful connection
5. Handle reconnection on failure

## Platform Status

- **iOS**: ✅ Fully implemented (HaishinKit 2.0.9)
- **Android**: ⚠️ Stub only (needs HaishinKit integration)
- **Web**: 🔧 Basic iframe fallback

## Testing

### iOS Testing Requirements
- iOS 15.1+ device or simulator
- Valid RTMP server URL (e.g., YouTube Live stream key)
- Camera and microphone permissions

### Test RTMP Servers
- **YouTube Live**: `rtmp://a.rtmp.youtube.com/live2/[STREAM_KEY]`
- **Local Test**: Use nginx-rtmp or similar local server

## Common Development Tasks

### Adding a New Native Method
1. Add method signature in `src/ExpoHaishinkit.types.ts`
2. Implement in `ios/ExpoHaishinkitView.swift`
3. Add Android stub in `android/.../ExpoHaishinkitView.kt`
4. Export from `src/index.ts`

### Debugging Connection Issues
1. Check iOS console for `[ExpoHaishinkit]` prefixed logs
2. Verify RTMP URL format and stream key
3. Monitor connection events via `onConnectionStatusChange`
4. Check network connectivity and firewall settings

### Updating HaishinKit Version
1. Update version in `ios/ExpoHaishinkit.podspec`
2. Run `cd example/ios && pod update HaishinKit`
3. Test all streaming functionality
4. Update Android dependency when implemented

## Key Files Reference

- `ios/ExpoHaishinkitView.swift:45-58` - Connection status handling
- `ios/ExpoHaishinkitView.swift:65-104` - HaishinKit initialization sequence
- `ios/ExpoHaishinkitView.swift:181-234` - Device attachment logic
- `ios/ExpoHaishinkitView.swift:236-297` - Publishing control
- `example/App.tsx:38-46` - Publishing API usage example