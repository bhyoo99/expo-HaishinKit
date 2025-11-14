import ExpoModulesCore
import HaishinKit
import AVFoundation
import UIKit

// This view will be used as a native component. Make sure to inherit from `ExpoView`
// to apply the proper styling (e.g. border radius and shadows).
class ExpoHaishinkitView: ExpoView {
  private var hkView: MTHKView?
  private var connection: RTMPConnection?
  private var stream: RTMPStream?
  
  let onConnectionStatusChange = ExpoModulesCore.EventDispatcher()
  let onStreamStatusChange = ExpoModulesCore.EventDispatcher()
  
  var url: String = ""
  var streamName: String = ""
  var isPublishing = false
  private var isInitialized = false
  
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
    hkView?.frame = bounds
  }
  
  private func setupHaishinKit() {
    print("[ExpoHaishinkit] Starting HaishinKit setup")
    
    // Initialize components
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
    
    // Request permissions first
    Task {
      await requestPermissions()
      
      await MainActor.run {
        // Setup view on main thread
        let view = MTHKView(frame: self.bounds)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.videoGravity = .resizeAspect
        view.backgroundColor = .black
        self.addSubview(view)
        
        NSLayoutConstraint.activate([
          view.topAnchor.constraint(equalTo: self.topAnchor),
          view.leadingAnchor.constraint(equalTo: self.leadingAnchor),
          view.trailingAnchor.constraint(equalTo: self.trailingAnchor),
          view.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
        
        self.hkView = view
        print("[ExpoHaishinkit] MTHKView created and added")
        
        // Attach stream
        view.attachStream(stream)
        print("[ExpoHaishinkit] Stream attached to view")
        
        self.setupEventListeners()
        self.attachDevices()
      }
    }
  }

  
  private func attachDevices() {
    // Attach camera and microphone
    if let audioDevice = AVCaptureDevice.default(for: .audio),
       let stream = self.stream {
      stream.attachAudio(audioDevice)
      print("[ExpoHaishinkit] Audio device attached")
    }
    
    if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
       let stream = self.stream {
      stream.attachCamera(camera)
      print("[ExpoHaishinkit] Camera device attached")
    }
  }
  
  private func requestPermissions() async {
    print("[ExpoHaishinkit] Requesting permissions")
    
    let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    if cameraStatus != .authorized {
      let granted = await AVCaptureDevice.requestAccess(for: .video)
      print("[ExpoHaishinkit] Camera permission: \(granted)")
    } else {
      print("[ExpoHaishinkit] Camera already authorized")
    }
    
    let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    if audioStatus != .authorized {
      let granted = await AVCaptureDevice.requestAccess(for: .audio)
      print("[ExpoHaishinkit] Microphone permission: \(granted)")
    } else {
      print("[ExpoHaishinkit] Microphone already authorized")
    }
  }
  
  private func setupEventListeners() {
    print("[ExpoHaishinkit] Setting up event listeners")
    
    // Connection status
    if let connection = connection {
      connection.addEventListener(.rtmpStatus, selector: #selector(connectionStatusHandler), observer: self)
      print("[ExpoHaishinkit] Connection event listener added")
    }
    
    // Stream status - add when stream is created
    setupStreamEventListener()
  }
  
  private func setupStreamEventListener() {
    if let stream = stream {
      stream.addEventListener(.rtmpStatus, selector: #selector(streamStatusHandler), observer: self)
      print("[ExpoHaishinkit] Stream event listener added")
    }
  }
  
  @objc
  private func connectionStatusHandler(_ notification: Notification) {
    guard let userInfo = notification.userInfo as? [AnyHashable: Any],
          let event = userInfo["event"] as? Event,
          let data = event.data as? [String: Any],
          let code = data["code"] as? String else { 
      print("[ExpoHaishinkit] Connection event parsing failed: \(notification.userInfo ?? [:])")
      return 
    }
    
    print("[ExpoHaishinkit] Connection event - code: \(code), level: \(data["level"] ?? ""), description: \(data["description"] ?? "")")
    
    onConnectionStatusChange([
      "code": code,
      "level": data["level"] as? String ?? "",
      "description": data["description"] as? String ?? ""
    ])
    
    // Flutter 방식: 연결 성공 시 자동으로 publish
    if code == "NetConnection.Connect.Success" && !streamName.isEmpty && !isPublishing {
      print("[ExpoHaishinkit] Auto-publishing on connection success")
      stream?.publish(streamName)
      isPublishing = true
    } else if code == "NetConnection.Connect.Closed" {
      print("[ExpoHaishinkit] Connection closed event received")
      isPublishing = false
    } else if code == "NetConnection.Connect.Failed" {
      print("[ExpoHaishinkit] Connection failed: \(data["description"] ?? "")")
      isPublishing = false
    }
  }
  
  @objc
  private func streamStatusHandler(_ notification: Notification) {
    guard let userInfo = notification.userInfo as? [AnyHashable: Any],
          let event = userInfo["event"] as? Event,
          let data = event.data as? [String: Any],
          let code = data["code"] as? String else {
      print("[ExpoHaishinkit] Stream event parsing failed: \(notification.userInfo ?? [:])")
      return 
    }
    
    print("[ExpoHaishinkit] Stream event - code: \(code), level: \(data["level"] ?? ""), description: \(data["description"] ?? "")")
    
    onStreamStatusChange([
      "code": code,
      "level": data["level"] as? String ?? "",
      "description": data["description"] as? String ?? ""
    ])
  }
  
  func startPublishing() {
    guard !streamName.isEmpty, 
          !url.isEmpty,
          let connection = connection else { 
      print("[ExpoHaishinkit] Missing required parameters for publishing")
      return 
    }
    
    print("[ExpoHaishinkit] startPublishing called")
    print("[ExpoHaishinkit] URL: \(url), Stream name: \(streamName)")
    print("[ExpoHaishinkit] Connection state: \(connection.connected)")
    print("[ExpoHaishinkit] isPublishing: \(isPublishing)")
    
    // 이미 연결되어 있으면 바로 publish
    if connection.connected {
      print("[ExpoHaishinkit] Already connected, publishing directly")
      stream?.publish(streamName)
      isPublishing = true
    } else {
      // Flutter 방식: connect만 호출, publish는 연결 성공 이벤트에서 자동으로
      print("[ExpoHaishinkit] Calling connection.connect(\(url))")
      connection.connect(url)
      
      // 재연결 시 타이밍 문제 해결을 위해 약간의 딜레이 후 상태 확인
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
        guard let self = self else { return }
        print("[ExpoHaishinkit] Connection state after 100ms: \(connection.connected)")
      }
    }
  }
  
  func stopPublishing() {
    print("[ExpoHaishinkit] stopPublishing called")
    print("[ExpoHaishinkit] Current connection state: \(connection?.connected ?? false)")
    print("[ExpoHaishinkit] Current isPublishing: \(isPublishing)")
    
    // Flutter와 완전히 동일하게: connection.close()만 호출
    print("[ExpoHaishinkit] Closing connection")
    connection?.close()
    // stream은 그대로 유지 (프리뷰 계속 보임)
    
    // 재연결을 위해 isPublishing을 false로 설정
    isPublishing = false
    
    // 연결 상태 확인
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      guard let self = self else { return }
      print("[ExpoHaishinkit] Connection state after close: \(self.connection?.connected ?? false)")
    }
  }
  
  deinit {
    connection?.removeEventListener(.rtmpStatus, selector: #selector(connectionStatusHandler), observer: self)
    stream?.removeEventListener(.rtmpStatus, selector: #selector(streamStatusHandler), observer: self)
    stream?.close()
    connection?.close()
  }
}
