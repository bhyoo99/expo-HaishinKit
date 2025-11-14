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
├── android/                 # Android native implementation
│   ├── src/main/java/.../ExpoHaishinkitView.kt # Main Android view (293 lines)
│   ├── src/main/java/.../ExpoHaishinkitModule.kt # Module definition
│   └── build.gradle        # Dependencies with HaishinKit.kt 0.16.0
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

The iOS implementation (`ios/ExpoHaishinkitView.swift`) surpasses Flutter's basic implementation with advanced features from HaishinKit official examples:

1. **Lazy Initialization**: MediaMixer created with `useManualCapture: true` to avoid iOS 18 bugs
2. **Audio Session**: Configured before any streaming setup
3. **Permission Handling**: Checks camera/microphone permissions before device attachment
4. **Connection Management**: Async/await pattern for RTMP connection with retry logic
5. **Event System**: Native events for connection and stream status changes
6. **Multi-Camera Support**: Detects and utilizes multi-camera capability on iPhone 11+

### Critical Implementation Patterns

#### Advanced Camera Switching (Superior to Flutter)
```swift
// Multi-camera mode (iPhone 11+): No black screen during switching
if isMultiCamSupported {
    // Both cameras attached to different tracks
    // Track 0: Back camera
    // Track 1: Front camera (auto-mirrored)
    // Switching: Just change mainTrack, no re-attachment needed
    videoMixerSettings.mainTrack = camera == "front" ? 1 : 0
}

// Single camera mode (older devices): Standard switching
else {
    // Re-attach camera with position-based mirroring
    try? await mixer.attachVideo(newCamera, track: 0) { videoUnit in
        videoUnit.isVideoMirrored = (position == .front)
    }
}
```

#### Camera Mirroring Strategy
- **Front Camera**: Always mirrored automatically (selfie mode)
- **Back Camera**: Never mirrored
- **No User Control**: Mirroring is automatic based on camera position

#### Connection Sequence
1. Check permissions
2. Detect multi-camera support (`mixer.isMultiCamSessionEnabled`)
3. Attach devices based on capability:
   - Multi-cam: Attach both cameras to separate tracks
   - Single-cam: Attach current camera only
4. Connect to RTMP server
5. Auto-publish on successful connection
6. Handle reconnection on failure

## Platform Status

- **iOS**: ✅ Fully implemented with advanced features (HaishinKit 2.0.9)
  - Multi-camera support for seamless switching
  - Automatic front camera mirroring
  - Zero black-screen transitions on iPhone 11+
- **Android**: ✅ Fully implemented matching Flutter HaishinKit.dart (HaishinKit.kt 0.16.0)
  - Camera2Source API for camera management
  - MediaMixer with proper track management
  - Automatic event handling for connection/stream status
  - Coroutine-based async operations
- **Web**: 🔧 Basic iframe fallback

## Comparison with Flutter Implementation

| Feature | Flutter HaishinKit | Our Implementation | Advantage |
|---------|-------------------|-------------------|-----------|
| Camera Switching | Single track, re-attach always | Multi-track on capable devices | No black screen on iPhone 11+ |
| Multi-Camera Detection | ❌ Not implemented | ✅ `isMultiCamSessionEnabled` | Optimized per device |
| Track Management | Track 0 only | Track 0 & 1 strategically | Instant switching |
| Mirroring | Manual per camera | Automatic based on position | Better UX |
| Black Screen Issue | Present during switch | Eliminated on modern devices | Superior experience |

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
1. **iOS**: Update version in `ios/ExpoHaishinkit.podspec`
2. Run `cd example/ios && pod update HaishinKit`
3. **Android**: Update versions in `android/build.gradle`:
   ```gradle
   implementation 'com.github.HaishinKit.HaishinKit~kt:haishinkit:0.16.0'
   implementation 'com.github.HaishinKit.HaishinKit~kt:rtmp:0.16.0'
   ```
4. Test all streaming functionality on both platforms

## Key Files Reference

### iOS Implementation
- `ios/ExpoHaishinkitView.swift:28` - Multi-camera support detection
- `ios/ExpoHaishinkitView.swift:141-183` - Advanced camera attachment with multi-track
- `ios/ExpoHaishinkitView.swift:194-222` - Smart camera switching logic
- `ios/ExpoHaishinkitView.swift:224-293` - Event listeners and connection management
- `ios/ExpoHaishinkitView.swift:295-345` - Publishing control

### Android Implementation
- `android/src/.../ExpoHaishinkitView.kt:27-30` - IEventListener implementation
- `android/src/.../ExpoHaishinkitView.kt:72-113` - HaishinKit setup with MediaMixer
- `android/src/.../ExpoHaishinkitView.kt:115-149` - Event handling for RTMP status
- `android/src/.../ExpoHaishinkitView.kt:165-187` - Camera attachment with Camera2Source
- `android/src/.../ExpoHaishinkitView.kt:189-221` - Camera switching logic
- `android/src/.../ExpoHaishinkitView.kt:227-238` - Camera ID detection
- `android/src/.../ExpoHaishinkitView.kt:240-254` - Publishing control

### Example App
- `example/App.tsx:48-56` - Publishing API usage example

## Implementation Highlights

### Android Implementation Details

The Android implementation exactly matches Flutter's HaishinKit.dart package structure:

1. **Dependency Management**: Uses HaishinKit.kt version 0.16.0 from JitPack
2. **Event Handling**: Implements IEventListener directly on the view class
3. **Camera Management**: Uses Camera2Source with CameraManager for proper device selection
4. **Async Operations**: All media operations use Kotlin coroutines on Dispatchers.Main
5. **Track Management**: Uses track index 0 for both audio and video following Flutter pattern
6. **Auto-publish**: Automatically publishes stream on successful connection

### iOS Implementation Advantages

1. **Follows HaishinKit Official Examples**: Based on the latest HaishinKit iOS examples
2. **Device-Aware Optimization**: Automatically detects and uses multi-camera capabilities when available
3. **Zero Configuration**: Automatic mirroring for front camera, no user intervention needed
4. **Production Ready**: Handles edge cases like iOS 18 bugs and permission management
5. **Future Proof**: Ready for newer iOS devices with enhanced camera capabilities

### Cross-Platform Consistency

Both iOS and Android implementations:
- Use the same event structure for connection and stream status
- Support camera switching with the same prop interface
- Handle permissions consistently across platforms
- Auto-publish on successful RTMP connection
- Provide identical JavaScript API through Expo Modules