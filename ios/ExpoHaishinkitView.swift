import ExpoModulesCore
import HaishinKit
import AVFoundation
import VideoToolbox
import UIKit

// This view will be used as a native component. Make sure to inherit from `ExpoView`
// to apply the proper styling (e.g. border radius and shadows).
class ExpoHaishinkitView: ExpoView {
  // Flutter와 동일한 구조
  private lazy var mixer: MediaMixer = {
    MediaMixer(
      multiTrackAudioMixingEnabled: false,
      useManualCapture: true  // iOS 18 버그 회피
    )
  }()
  private var connection: RTMPConnection?
  private var stream: RTMPStream?
  private var texture: MTHKView?

  let onConnectionStatusChange = ExpoModulesCore.EventDispatcher()
  let onStreamStatusChange = ExpoModulesCore.EventDispatcher()

  var url: String = ""
  var streamName: String = ""
  var camera: String = "back"  // 기본값: 후면 카메라
  var ingesting = false  // Flutter와 동일한 이름 사용
  private var isInitialized = false
  private var isMultiCamSupported = false  // 다중 카메라 지원 여부
  
  // Props for video/audio settings
  var videoSettingsProp: [String: Any]? = nil {
    didSet {
      if let settings = videoSettingsProp {
        Task {
          await setVideoSettings(settings)
        }
      }
    }
  }
  
  var audioSettingsProp: [String: Any]? = nil {
    didSet {
      if let settings = audioSettingsProp {
        Task {
          await setAudioSettings(settings)
        }
      }
    }
  }
  
  var mutedProp: Bool = false {
    didSet {
      Task {
        await setAudioMuted(mutedProp)
      }
    }
  }
  
  // Status subscriptions (Flutter와 동일한 방식)
  private var connectionStatusSubscription: Task<(), Error>?
  private var streamStatusSubscription: Task<(), Error>?
  
  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    clipsToBounds = true
    backgroundColor = .black
  }
  
  override func willMove(toWindow newWindow: UIWindow?) {
    super.willMove(toWindow: newWindow)
    
    if newWindow != nil && !isInitialized {
      setupHaishinKit()
      isInitialized = true
    }
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    texture?.frame = bounds
  }
  
  private func setupHaishinKit() {
    print("[ExpoHaishinkit] Starting HaishinKit setup")
    
    // Flutter와 100% 동일한 초기화 순서
    Task {
      // 1. 오디오 세션 설정 (Flutter: audio_session 패키지)
      setupAudioSession()
      
      // 2. MediaMixer는 lazy 생성 (첫 사용 시)
      print("[ExpoHaishinkit] Starting setup with lazy MediaMixer")
      
      // 3. MTHKView 생성 및 설정
      await MainActor.run {
        texture = MTHKView(frame: self.bounds)
        guard let texture = texture else { return }
        
        texture.translatesAutoresizingMaskIntoConstraints = false
        texture.videoGravity = .resizeAspect
        texture.backgroundColor = .black
        self.addSubview(texture)
        
        NSLayoutConstraint.activate([
          texture.topAnchor.constraint(equalTo: self.topAnchor),
          texture.leadingAnchor.constraint(equalTo: self.leadingAnchor),
          texture.trailingAnchor.constraint(equalTo: self.trailingAnchor),
          texture.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        print("[ExpoHaishinkit] MTHKView setup completed")
      }
      
      // 4. MTHKView를 mixer에 추가
      if let texture = texture {
        await mixer.addOutput(texture)  // lazy 초기화 발생!
        print("[ExpoHaishinkit] MTHKView added to mixer (lazy initialized)")
      }
      
      // 5. Connection과 Stream 설정 (Flutter: RtmpConnection.create() → RtmpStream.create())
      await setupConnection()
      
      // 6. attachAudio/attachVideo (Flutter: stream.attachAudio() → stream.attachVideo())
      await attachAudio()
      await attachCamera()
      print("[ExpoHaishinkit] Devices attached")
      
      // 7. 마지막에 startRunning (useManualCapture 때문에 수동 호출 필요)
      await mixer.startRunning()
      print("[ExpoHaishinkit] Mixer started running - ready!")
    }
  }
  
  private func setupAudioSession() {
    // Flutter audio_session 패키지와 동일한 설정
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playAndRecord, options: [.allowBluetooth])
      try session.setActive(true)
      print("[ExpoHaishinkit] Audio session configured")
    } catch {
      print("[ExpoHaishinkit] Failed to setup audio session: \(error)")
    }
  }

  private func setupConnection() async {
    // Flutter와 동일한 연결 설정
    connection = RTMPConnection()
    guard let connection = connection else {
      print("[ExpoHaishinkit] Failed to create RTMPConnection")
      return
    }
    print("[ExpoHaishinkit] RTMPConnection created")
    
    stream = RTMPStream(connection: connection)
    guard let stream = stream else {
      print("[ExpoHaishinkit] Failed to create RTMPStream")
      return
    }
    print("[ExpoHaishinkit] RTMPStream created")
    
    // Flutter와 동일하게 mixer에 stream 추가
    await mixer.addOutput(stream)
    print("[ExpoHaishinkit] Stream added to mixer")
    
    setupEventListeners()
  }
  
  
  private func attachCamera() async {
    let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)
    guard videoStatus == .authorized else {
      print("[ExpoHaishinkit] ⚠️ Camera permission not granted")
      return
    }

    // HaishinKit 예제 방식: 다중 카메라 지원 확인
    isMultiCamSupported = await mixer.isMultiCamSessionEnabled

    if isMultiCamSupported {
      // 다중 카메라 모드: 두 카메라 모두 attach (검정 화면 방지)
      if let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
        try? await mixer.attachVideo(backCamera, track: 0) { videoUnit in
          videoUnit.isVideoMirrored = false
        }
      }

      if let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
        try? await mixer.attachVideo(frontCamera, track: 1) { videoUnit in
          videoUnit.isVideoMirrored = true
        }
      }

      // 초기 카메라에 따라 메인 트랙 설정
      var videoMixerSettings = await mixer.videoMixerSettings
      videoMixerSettings.mainTrack = camera == "front" ? 1 : 0
      await mixer.setVideoMixerSettings(videoMixerSettings)

      print("[ExpoHaishinkit] Multi-camera mode enabled, both cameras attached")
    } else {
      // 단일 카메라 모드: 현재 카메라만 attach
      let position: AVCaptureDevice.Position = camera == "front" ? .front : .back
      let isFrontCamera = position == .front

      if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
        try? await mixer.attachVideo(camera, track: 0) { videoUnit in
          videoUnit.isVideoMirrored = isFrontCamera
        }
        print("[ExpoHaishinkit] Single camera mode, attached \(self.camera) camera")
      }
    }
  }
  
  private func attachAudio() async {
    let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    if audioStatus == .authorized, let audioDevice = AVCaptureDevice.default(for: .audio) {
      try? await mixer.attachAudio(audioDevice)
      print("[ExpoHaishinkit] Audio device attached to mixer")
    }
  }
  
  // camera prop이 변경될 때 호출
  func updateCamera() {
    // 초기화가 완료되지 않았으면 무시
    guard isInitialized else {
      print("[ExpoHaishinkit] Ignoring camera update - not initialized yet")
      return
    }

    Task {
      if isMultiCamSupported {
        // 다중 카메라 모드: 메인 트랙만 전환 (검정 화면 없음!)
        var videoMixerSettings = await mixer.videoMixerSettings
        videoMixerSettings.mainTrack = camera == "front" ? 1 : 0
        await mixer.setVideoMixerSettings(videoMixerSettings)

        print("[ExpoHaishinkit] Switched main track to: \(camera) (track \(videoMixerSettings.mainTrack))")
      } else {
        // 단일 카메라 모드: 카메라 재연결 필요
        let position: AVCaptureDevice.Position = camera == "front" ? .front : .back
        let isFrontCamera = position == .front

        if let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
          try? await mixer.attachVideo(newCamera, track: 0) { videoUnit in
            videoUnit.isVideoMirrored = isFrontCamera
          }
          print("[ExpoHaishinkit] Camera switched to: \(camera) (mirrored: \(isFrontCamera))")
        }
      }
    }
  }
  
  private func setupEventListeners() {
    print("[ExpoHaishinkit] Setting up event listeners")
    
    // HaishinKit 2.0.9 방식: status 스트림 구독 (Flutter와 동일)
    if let connection = connection {
      connectionStatusSubscription = Task { [weak self] in
        for await status in await connection.status {
          await MainActor.run { [weak self] in
            self?.handleConnectionStatus(status)
          }
        }
      }
      print("[ExpoHaishinkit] Connection status subscription started")
    }
    
    // Stream status subscription
    if let stream = stream {
      streamStatusSubscription = Task { [weak self] in
        for await status in await stream.status {
          await MainActor.run { [weak self] in
            self?.handleStreamStatus(status)
          }
        }
      }
      print("[ExpoHaishinkit] Stream status subscription started")
    }
  }
  
  private func handleConnectionStatus(_ status: RTMPStatus) {
    let code = status.code
    let level = status.level
    let description = status.description
    
    print("[ExpoHaishinkit] Connection event - code: \(code), level: \(level), description: \(description)")
    
    onConnectionStatusChange([
      "code": code,
      "level": level,
      "description": description
    ])
    
    // Flutter 방식: 연결 성공 시 자동으로 publish
    if code == "NetConnection.Connect.Success" && !streamName.isEmpty && !ingesting {
      print("[ExpoHaishinkit] Auto-publishing on connection success")
      Task {
        _ = try? await stream?.publish(streamName)
        await MainActor.run {
          self.ingesting = true
        }
      }
    } else if code == "NetConnection.Connect.Closed" {
      print("[ExpoHaishinkit] Connection closed event received")
      ingesting = false
    } else if code == "NetConnection.Connect.Failed" {
      print("[ExpoHaishinkit] Connection failed: \(description)")
      ingesting = false
    }
  }
  
  private func handleStreamStatus(_ status: RTMPStatus) {
    let code = status.code
    let level = status.level
    let description = status.description
    
    print("[ExpoHaishinkit] Stream event - code: \(code), level: \(level), description: \(description)")
    
    onStreamStatusChange([
      "code": code,
      "level": level,
      "description": description
    ])
  }
  
  func startPublishing() {
    Task {
      guard !streamName.isEmpty, 
            !url.isEmpty,
            let connection = connection else { 
        print("[ExpoHaishinkit] Missing required parameters for publishing")
        return 
      }
      
      print("[ExpoHaishinkit] startPublishing called")
      print("[ExpoHaishinkit] URL: \(url), Stream name: \(streamName)")
      
      do {
        // Flutter 방식: connect만 호출, publish는 연결 성공 이벤트에서 자동으로
        print("[ExpoHaishinkit] Calling connection.connect(\(url))")
        _ = try await connection.connect(url)
      } catch {
        print("[ExpoHaishinkit] Connection error: \(error)")
        await MainActor.run {
          onConnectionStatusChange([
            "code": "NetConnection.Connect.Failed",
            "level": "error",
            "description": error.localizedDescription
          ])
        }
      }
    }
  }
  
  func stopPublishing() {
    Task {
      print("[ExpoHaishinkit] stopPublishing called")
      
      guard let connection = connection else {
        print("[ExpoHaishinkit] No connection to close")
        return
      }
      
      print("[ExpoHaishinkit] Current ingesting: \(ingesting)")
      
      // Flutter와 완전히 동일하게: connection.close()만 호출
      print("[ExpoHaishinkit] Closing connection")
      _ = try? await connection.close()
      // stream은 그대로 유지 (프리뷰 계속 보임)
      
      // 재연결을 위해 ingesting을 false로 설정
      // 이미 이벤트 핸들러에서 처리되지만 안전을 위해 여기서도 설정
      ingesting = false
      
      print("[ExpoHaishinkit] Connection closed")
    }
  }
  
  // Flutter의 setVideoSettings와 동일
  func setVideoSettings(_ settings: [String: Any]) async {
    guard let stream = stream else { return }
    
    var videoSettings = await stream.videoSettings
    
    if let width = settings["width"] as? Int,
       let height = settings["height"] as? Int {
      videoSettings.videoSize = CGSize(width: CGFloat(width), height: CGFloat(height))
    }
    
    if let bitrate = settings["bitrate"] as? Int {
      videoSettings.bitRate = bitrate
    }
    
    if let frameInterval = settings["frameInterval"] as? Int {
      videoSettings.maxKeyFrameIntervalDuration = Int32(frameInterval)
    }
    
    if let profileLevelStr = settings["profileLevel"] as? String {
      // Flutter ProfileLevel.swift와 동일한 매핑 로직
      let profileLevel = ProfileLevel.getProfileLevelConstant(from: profileLevelStr)
      if let profileLevel = profileLevel {
        videoSettings.profileLevel = profileLevel
      }
    }
    
    await stream.setVideoSettings(videoSettings)
    print("[ExpoHaishinkit] Video settings updated: \(settings)")
  }
  
  // Flutter의 setAudioSettings와 동일
  func setAudioSettings(_ settings: [String: Any]) async {
    guard let stream = stream else { return }
    
    var audioSettings = await stream.audioSettings
    
    if let bitrate = settings["bitrate"] as? Int {
      audioSettings.bitRate = bitrate
    }
    
    await stream.setAudioSettings(audioSettings)
    print("[ExpoHaishinkit] Audio settings updated: \(settings)")
  }
  
  // 오디오 뮤트 설정
  func setAudioMuted(_ muted: Bool) async {
    var audioMixerSettings = await mixer.audioMixerSettings
    audioMixerSettings.isMuted = muted
    await mixer.setAudioMixerSettings(audioMixerSettings)
    print("[ExpoHaishinkit] Audio muted: \(muted)")
  }
  
  
  deinit {
    // Task 취소
    connectionStatusSubscription?.cancel()
    streamStatusSubscription?.cancel()
    
    // 리소스 정리는 별도 태스크로
    let mixerToCleanup = mixer
    Task { [stream, connection, texture] in
      // Flutter와 동일한 정리 순서
      _ = try? await stream?.close()
      _ = try? await connection?.close()
      
      // Mixer 정리
      if let stream = stream {
        await mixerToCleanup.removeOutput(stream)
      }
      if let texture = texture {
        await mixerToCleanup.removeOutput(texture)
      }
      
      await mixerToCleanup.stopRunning()
    }
  }
}