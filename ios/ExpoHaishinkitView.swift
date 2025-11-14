import ExpoModulesCore
import HaishinKit
import AVFoundation
import UIKit

// This view will be used as a native component. Make sure to inherit from `ExpoView`
// to apply the proper styling (e.g. border radius and shadows).
class ExpoHaishinkitView: ExpoView {
  // Flutter와 동일한 구조
  private var mixer: MediaMixer?
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
  
  // 카메라별 미러링 상태 저장
  private var mirrorStates: [String: Bool] = [
    "front": true,   // 전면 기본값: 미러링 ON
    "back": false    // 후면 기본값: 미러링 OFF
  ]
  
  // 현재 활성 미러링 상태
  private var isVideoMirrored: Bool {
    get { mirrorStates[camera] ?? false }
    set { mirrorStates[camera] = newValue }
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
      
      // 2. MediaMixer 생성
      mixer = MediaMixer(
        multiTrackAudioMixingEnabled: false,
        useManualCapture: true  // iOS 18 버그 때문에 필요
      )
      print("[ExpoHaishinkit] MediaMixer created")
      
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
        await mixer?.addOutput(texture)
        print("[ExpoHaishinkit] MTHKView added to mixer")
      }
      
      // 5. Connection과 Stream 설정 (Flutter: RtmpConnection.create() → RtmpStream.create())
      await setupConnection()
      
      // 6. attachAudio/attachVideo (Flutter: stream.attachAudio() → stream.attachVideo())
      await attachAudio()
      await attachCamera()
      print("[ExpoHaishinkit] Devices attached")
      
      // 7. 마지막에 startRunning (useManualCapture 때문에 수동 호출 필요)
      await mixer?.startRunning()
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
    await mixer?.addOutput(stream)
    print("[ExpoHaishinkit] Stream added to mixer")
    
    setupEventListeners()
  }
  
  
  private func attachCamera() async {
    let videoStatus = AVCaptureDevice.authorizationStatus(for: .video)
    guard videoStatus == .authorized else {
      print("[ExpoHaishinkit] ⚠️ Camera permission not granted")
      return
    }
    
    let position: AVCaptureDevice.Position = camera == "front" ? .front : .back
    let mirrored = self.isVideoMirrored
    
    if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
      try? await mixer?.attachVideo(camera, track: 0) { videoUnit in
        videoUnit.isVideoMirrored = mirrored
      }
      print("[ExpoHaishinkit] Camera device attached to mixer")
    }
  }
  
  private func attachAudio() async {
    let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    if audioStatus == .authorized, let audioDevice = AVCaptureDevice.default(for: .audio) {
      try? await mixer?.attachAudio(audioDevice)
      print("[ExpoHaishinkit] Audio device attached to mixer")
    }
  }
  
  // camera prop이 변경될 때 호출
  func updateCamera() {
    // 초기화가 완료되지 않았으면 무시
    guard isInitialized, mixer != nil else {
      print("[ExpoHaishinkit] Ignoring camera update - not initialized yet")
      return
    }
    
    Task {
      let position: AVCaptureDevice.Position = camera == "front" ? .front : .back
      let mirrored = self.isVideoMirrored // 로컬 변수로 캡처
      
      if let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
        try? await mixer?.attachVideo(newCamera, track: 0) { videoUnit in
          // 저장된 미러링 상태 적용
          videoUnit.isVideoMirrored = mirrored
        }
        print("[ExpoHaishinkit] Camera switched to: \(camera), mirrored: \(mirrored)")
      }
    }
  }
  
  // 미러링 토글
  func toggleMirroring() {
    Task {
      // 현재 카메라의 미러링 상태 토글
      isVideoMirrored.toggle()
      let mirrored = self.isVideoMirrored // 로컬 변수로 캡처
      
      // 현재 카메라에 새로운 미러링 설정 적용
      let position: AVCaptureDevice.Position = camera == "front" ? .front : .back
      if let currentCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) {
        try? await mixer?.attachVideo(currentCamera, track: 0) { videoUnit in
          videoUnit.isVideoMirrored = mirrored
        }
      }
      
      print("[ExpoHaishinkit] Mirroring toggled to: \(mirrored) for \(camera) camera")
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
  
  deinit {
    // Task 취소
    connectionStatusSubscription?.cancel()
    streamStatusSubscription?.cancel()
    
    // 리소스 정리는 별도 태스크로
    Task { [mixer, stream, connection, texture] in
      // Flutter와 동일한 정리 순서
      _ = try? await stream?.close()
      _ = try? await connection?.close()
      
      // Mixer 정리
      if let stream = stream {
        await mixer?.removeOutput(stream)
      }
      if let texture = texture {
        await mixer?.removeOutput(texture)
      }
      
      await mixer?.stopRunning()
    }
  }
}