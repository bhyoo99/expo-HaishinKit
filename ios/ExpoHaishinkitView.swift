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
    
    // Connection status - only add once in setupHaishinKit
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
    guard let data = notification.userInfo as? [String: Any],
          let code = data["code"] as? String else { return }
    
    onConnectionStatusChange([
      "code": code,
      "level": data["level"] as? String ?? "",
      "description": data["description"] as? String ?? ""
    ])
  }
  
  @objc
  private func streamStatusHandler(_ notification: Notification) {
    guard let data = notification.userInfo as? [String: Any],
          let code = data["code"] as? String else { return }
    
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
    
    print("[ExpoHaishinkit] Starting publish to \(url)/\(streamName)")
    
    // Always reconnect (since we close connection on stop)
    connection.connect(url)
    
    // Create new stream if needed or reuse existing
    if stream == nil || !isPublishing {
      stream = RTMPStream(connection: connection)
      
      // Re-setup stream
      if let stream = stream {
        setupStreamEventListener()
        attachDevices()
        
        // Re-attach to view
        DispatchQueue.main.async { [weak self] in
          self?.hkView?.attachStream(stream)
        }
      }
    }
    
    // Publish the stream
    stream?.publish(streamName)
    isPublishing = true
  }
  
  func stopPublishing() {
    print("[ExpoHaishinkit] Stopping publish")
    
    // Remove event listeners before closing
    stream?.removeEventListener(.rtmpStatus, selector: #selector(streamStatusHandler), observer: self)
    
    // Close and clean up stream
    stream?.close()
    stream = nil
    
    // Close connection completely
    connection?.close()
    
    isPublishing = false
  }
  
  deinit {
    connection?.removeEventListener(.rtmpStatus, selector: #selector(connectionStatusHandler), observer: self)
    stream?.removeEventListener(.rtmpStatus, selector: #selector(streamStatusHandler), observer: self)
  }
}
