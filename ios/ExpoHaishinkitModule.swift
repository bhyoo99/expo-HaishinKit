import ExpoModulesCore

public class ExpoHaishinkitModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoHaishinkit")

    // Enables the module to be used as a native view. Definition components that are accepted as part of the
    // view definition: Prop, Events.
    View(ExpoHaishinkitView.self) {
      // Defines a setter for the `url` prop.
      Prop("url") { (view: ExpoHaishinkitView, url: String?) in
        if let url = url {
          view.url = url
        }
      }
      
      Prop("streamName") { (view: ExpoHaishinkitView, streamName: String?) in
        if let streamName = streamName {
          view.streamName = streamName
        }
      }
      
      Prop("camera") { (view: ExpoHaishinkitView, camera: String?) in
        if let camera = camera, (camera == "front" || camera == "back") {
          view.camera = camera
          view.updateCamera()  // 카메라 변경
        }
      }
      
      Prop("videoSettings") { (view: ExpoHaishinkitView, settings: [String: Any]?) in
        view.videoSettingsProp = settings
      }
      
      Prop("audioSettings") { (view: ExpoHaishinkitView, settings: [String: Any]?) in
        view.audioSettingsProp = settings
      }
      
      Prop("muted") { (view: ExpoHaishinkitView, muted: Bool?) in
        view.mutedProp = muted ?? false
      }
      
      Events(
        "onConnectionStatusChange",
        "onStreamStatusChange"
      )
      
      // AsyncFunction in View definition automatically receives view instance
      AsyncFunction("startPublishing") { (view: ExpoHaishinkitView) in
        view.startPublishing()
      }
      
      AsyncFunction("stopPublishing") { (view: ExpoHaishinkitView) in
      view.stopPublishing()
    }
    }
  }
}
