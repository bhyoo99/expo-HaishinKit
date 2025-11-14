package expo.modules.haishinkit

import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class ExpoHaishinkitModule : Module() {
    override fun definition() = ModuleDefinition {
        Name("ExpoHaishinkit")

        // View definition with props and events
        View(ExpoHaishinkitView::class) {
            // Props
            Prop("url") { view: ExpoHaishinkitView, url: String ->
                view.url = url
            }

            Prop("streamName") { view: ExpoHaishinkitView, streamName: String ->
                view.streamName = streamName
            }

            Prop("camera") { view: ExpoHaishinkitView, camera: String ->
                if (camera == "front" || camera == "back") {
                    view.cameraPosition = camera
                    view.updateCamera()
                }
            }

            // Events
            Events(
                "onConnectionStatusChange",
                "onStreamStatusChange"
            )

            // Async functions for ref methods
            AsyncFunction("startPublishing") { view: ExpoHaishinkitView ->
                view.startPublishing()
            }

            AsyncFunction("stopPublishing") { view: ExpoHaishinkitView ->
                view.stopPublishing()
            }
        }
    }
}