package expo.modules.haishinkit

import android.content.Context
import android.graphics.SurfaceTexture
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.util.Log
import android.util.Size
import android.view.Gravity
import android.view.Surface
import android.view.TextureView
import android.widget.FrameLayout
import com.haishinkit.graphics.PixelTransform
import com.haishinkit.graphics.VideoGravity
import com.haishinkit.graphics.effect.VideoEffect
import com.haishinkit.media.MediaBuffer
import com.haishinkit.media.MediaMixer
import com.haishinkit.media.MediaOutputDataSource
import com.haishinkit.media.source.AudioRecordSource
import com.haishinkit.media.source.AudioSource
import com.haishinkit.media.source.Camera2Source
import com.haishinkit.rtmp.RtmpConnection
import com.haishinkit.rtmp.RtmpStream
import com.haishinkit.rtmp.event.Event
import com.haishinkit.rtmp.event.IEventListener
import com.haishinkit.screen.ScreenObject
import com.haishinkit.view.StreamView
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.viewevent.EventDispatcher
import expo.modules.kotlin.views.ExpoView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.lang.ref.WeakReference

// Custom TextureView implementing StreamView interface - following HaishinKit.kt pattern
class ExpoTextureView(context: Context) : TextureView(context), StreamView, TextureView.SurfaceTextureListener {
    override var dataSource: WeakReference<MediaOutputDataSource>? = null
        set(value) {
            field = value
            pixelTransform.screen = value?.get()?.screen
        }

    override var videoGravity: VideoGravity
        get() = pixelTransform.videoGravity
        set(value) {
            pixelTransform.videoGravity = value
        }

    override var frameRate: Int
        get() = pixelTransform.frameRate
        set(value) {
            pixelTransform.frameRate = value
        }

    override var videoEffect: VideoEffect
        get() = pixelTransform.videoEffect
        set(value) {
            pixelTransform.videoEffect = value
        }

    private val pixelTransform: PixelTransform by lazy { PixelTransform.create(context) }

    init {
        surfaceTextureListener = this
    }

    override fun onSurfaceTextureAvailable(surface: SurfaceTexture, width: Int, height: Int) {
        pixelTransform.imageExtent = Size(width, height)
        pixelTransform.surface = Surface(surface)
    }

    override fun onSurfaceTextureSizeChanged(surface: SurfaceTexture, width: Int, height: Int) {
        pixelTransform.imageExtent = Size(width, height)
    }

    override fun onSurfaceTextureDestroyed(surface: SurfaceTexture): Boolean {
        pixelTransform.surface = null
        return false
    }

    override fun onSurfaceTextureUpdated(surface: SurfaceTexture) {
        // Frame updated
    }

    override fun append(buffer: MediaBuffer) {
        // Not needed for preview
    }
}

class ExpoHaishinkitView(context: Context, appContext: AppContext) : ExpoView(context, appContext), IEventListener {
    companion object {
        private const val TAG = "ExpoHaishinkit"
    }

    // RTMP components - EXACTLY following Flutter structure
    private var connection: RtmpConnection? = null
    private var rtmpStream: RtmpStream? = null
        set(value) {
            field?.dispose()
            field = value
        }
    private var mixer: MediaMixer? = null
        set(value) {
            field?.dispose()
            field = value
        }

    // Preview component - following Flutter pattern (texture is separate)
    private var textureView: ExpoTextureView? = null

    // Audio/Video sources - EXACTLY following Flutter
    private var camera: Camera2Source? = null
    private var audio: AudioSource? = null

    // Properties
    var url: String = ""
    var streamName: String = ""
    var cameraPosition: String = "back"
    private var isInitialized = false
    private var ingesting = false

    // Event dispatchers
    val onConnectionStatusChange by EventDispatcher()
    val onStreamStatusChange by EventDispatcher()

    init {
        layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT,
            Gravity.CENTER
        )
        setupView()
        setupHaishinKit()
    }

    private fun setupView() {
        // Create preview TextureView
        textureView = ExpoTextureView(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            videoGravity = VideoGravity.RESIZE_ASPECT_FILL
        }
        addView(textureView)
    }

    private fun setupHaishinKit() {
        Log.d(TAG, "Starting HaishinKit setup - Following Flutter exactly")

        // Initialize connection first - EXACTLY like Flutter
        connection = RtmpConnection()

        // Setup connection if exists - EXACTLY like Flutter init block
        connection?.let {
            rtmpStream = RtmpStream(context, it)
            rtmpStream?.addEventListener(Event.RTMP_STATUS, this)

            mixer = MediaMixer(context)

            mixer?.screen?.let { screen ->
                screen.horizontalAlignment = ScreenObject.HORIZONTAL_ALIGNMENT_CENTER
                screen.verticalAlignment = ScreenObject.VERTICAL_ALIGNMENT_MIDDLE
            }

            // Only register rtmpStream output initially - EXACTLY like Flutter
            mixer?.registerOutput(rtmpStream!!)
        }

        // Register texture for preview - like Flutter's registerTexture
        textureView?.let { view ->
            mixer?.registerOutput(view)
        }

        // Add connection event listener after setup
        connection?.addEventListener(Event.RTMP_STATUS, this)

        // EXACTLY like Flutter example: attach audio/video at initialization
        attachAudio()
        attachCamera()

        isInitialized = true
        Log.d(TAG, "HaishinKit setup completed with devices attached")
    }

    // Implement IEventListener interface - EXACTLY following Flutter
    override fun handleEvent(event: Event) {
        val data = event.data as? Map<*, *>
        val code = data?.get("code")?.toString() ?: ""
        val level = data?.get("level")?.toString() ?: ""
        val description = data?.get("description")?.toString() ?: ""

        // Create event map for React Native
        val eventMap = mapOf(
            "type" to (event.type as Any),
            "code" to (code as Any),
            "level" to (level as Any),
            "description" to (description as Any)
        )

        // Dispatch event to React Native
        when (event.type) {
            Event.RTMP_STATUS -> {
                if (code.startsWith("NetConnection")) {
                    onConnectionStatusChange(eventMap)
                    
                    // Auto-publish for iOS/Android consistency (iOS does this too)
                    if (code == "NetConnection.Connect.Success" && streamName.isNotEmpty() && !ingesting) {
                        Log.d(TAG, "Auto-publishing on connection success")
                        rtmpStream?.publish(streamName)
                        ingesting = true
                    } else if (code == "NetConnection.Connect.Closed" || code == "NetConnection.Connect.Failed") {
                        ingesting = false
                    }
                } else if (code.startsWith("NetStream")) {
                    onStreamStatusChange(eventMap)
                }
            }
        }
    }

    // EXACTLY following Flutter's attachAudio implementation
    fun attachAudio() {
        CoroutineScope(Dispatchers.Main).launch {
            // Cleanup current attached source
            mixer?.attachAudio(0, null)
            audio?.close()
            audio = null

            // Attach new audio source if needed
            audio = AudioRecordSource(context)
            mixer?.attachAudio(0, audio)

            Log.d(TAG, "Audio attached")
        }
    }

    // Following HaishinKit.kt's native attachVideo pattern for smooth switching
    fun attachCamera() {
        val desiredFacing = if (cameraPosition == "front") {
            CameraCharacteristics.LENS_FACING_FRONT
        } else {
            CameraCharacteristics.LENS_FACING_BACK
        }

        val cameraId = getCameraId(context, desiredFacing)
        val cameraSource = if (cameraId != null) {
            Camera2Source(context, cameraId)
        } else {
            Camera2Source(context)
        }

        // Store old camera for cleanup
        val oldCamera = this.camera
        this.camera = cameraSource

        CoroutineScope(Dispatchers.Main).launch {
            // EXACTLY following Flutter: detach first, then attach
            mixer?.attachVideo(0, null)
            mixer?.attachVideo(0, cameraSource)
            oldCamera?.close()
            Log.d(TAG, "Camera attached: $cameraPosition")
        }
    }

    fun updateCamera() {
        if (!isInitialized) {
            Log.d(TAG, "Ignoring camera update - not initialized yet")
            return
        }

        // Just re-attach camera with new position - EXACTLY like Flutter
        attachCamera()
    }

    /**
     * EXACTLY following Flutter's getCameraId implementation
     */
    private fun getCameraId(context: Context, desiredFacing: Int): String? {
        val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        for (cameraId in cameraManager.cameraIdList) {
            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
            val facing = characteristics.get(CameraCharacteristics.LENS_FACING)
            Log.d(TAG, "Camera ID: $cameraId; facing: $facing")
            if (facing != null && facing == desiredFacing) {
                return cameraId
            }
        }
        return null
    }

    fun startPublishing() {
        if (url.isEmpty() || streamName.isEmpty()) {
            Log.w(TAG, "Missing URL or stream name")
            return
        }

        Log.d(TAG, "Starting publishing to: $url/$streamName")

        // EXACTLY like Flutter: just connect (devices already attached in init)
        connection?.connect(url)
    }

    fun stopPublishing() {
        Log.d(TAG, "Stopping publishing")
        // EXACTLY like Flutter: only close connection, not stream
        connection?.close()
        ingesting = false
    }

    // EXACTLY following Flutter's dispose pattern
    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        cleanup()
    }

    private fun cleanup() {
        CoroutineScope(Dispatchers.Main).launch {
            // EXACTLY following Flutter's disposal order
            mixer?.attachVideo(0, null)
            mixer?.attachAudio(0, null)

            // Properly disconnect mixer from RTMP stream before disposal
            rtmpStream?.let { stream ->
                mixer?.unregisterOutput(stream)
            }

            textureView?.let { texture ->
                mixer?.unregisterOutput(texture)
            }

            textureView = null
            mixer?.dispose()
            rtmpStream?.dispose()

            mixer = null
            camera = null
            audio = null
            rtmpStream = null
            connection = null

            Log.d(TAG, "Cleanup completed")
        }
    }
}