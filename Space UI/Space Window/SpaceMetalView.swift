import SwiftUI
import Metal
import MetalKit
#if canImport(UIKit)
import UIKit
#endif
#if canImport(MetalFX)
import MetalFX
#endif
import MetalPerformanceShaders
import RealityKit
import AVKit
import CoreVideo

#if canImport(UIKit)
struct SpaceMetalView: UIViewRepresentable {
    
    let cameraAngle: CameraAngle
    
    func makeUIView(context: Context) -> SpaceMetalUIView {
        SpaceMetalUIView(frame: .zero, device: MTLCreateSystemDefaultDevice()!, cameraAngle: cameraAngle)
    }

    func updateUIView(_ uiView: SpaceMetalUIView, context: Context) { }
}
#else
struct SpaceMetalView: NSViewRepresentable {
    
    let cameraAngle: CameraAngle
    
    func makeNSView(context: Context) -> SpaceMetalUIView {
        SpaceMetalUIView(frame: .zero, device: MTLCreateSystemDefaultDevice()!, cameraAngle: cameraAngle)
    }

    func updateNSView(_ uiView: SpaceMetalUIView, context: Context) { }
}
#endif

final class SpaceMetalUIView: MTKView {
    
    private var metalLayer: CAMetalLayer {
        layer as! CAMetalLayer
    }
    
    private let cameraAngle: CameraAngle
    private let renderer: MetalRenderer
    private let commandQueue: MTLCommandQueue

    /// How many frames this view may have in flight, which is how many drawables its layer owns.
    ///
    /// `currentDrawable` blocks the calling thread until the compositor hands a drawable back, and
    /// `allowsNextDrawableTimeout` makes that a *one second* wait, not a frame. This view draws on the main
    /// thread, so an empty pool doesn't cost a frame — it costs the show: every cue body is main-actor, and a
    /// run of those timeouts is the eleven-second stall that took the second and third star destroyers with it.
    /// See `Show/Docs/Late Cues.md`.
    ///
    /// So the acquisition is gated on a count we keep ourselves, waited with a zero timeout: a full pool
    /// becomes a dropped frame instead of a blocked main thread. Per view, because each window owns a separate
    /// layer and a separate pool — and in the dual rig both are acquired back to back on the one main thread,
    /// so without this the worst case is two seconds of blocking per frame rather than one.
    private lazy var inFlightFrames = DispatchSemaphore(value: metalLayer.maximumDrawableCount)

    required init(coder aDecoder: NSCoder) {
        fatalError()
    }

    override init(frame: CGRect, device: (any MTLDevice)?) {
        cameraAngle = .singleCenter
        renderer = Self.sharedRenderer(for: cameraAngle)
        commandQueue = renderer.commandQueue
        super.init(frame: frame, device: device!)
        commonInit()
    }

    init(frame: CGRect, device: any MTLDevice, cameraAngle: CameraAngle) {
        self.cameraAngle = cameraAngle
        renderer = Self.sharedRenderer(for: cameraAngle)
        commandQueue = renderer.commandQueue
        super.init(frame: frame, device: device)
        commonInit()
    }

    /// Reuse the shared renderer (and its scene) if one exists, reconfiguring its width mode in place;
    /// otherwise create it. Never discards a live `SpaceSceneController` just because the camera mode differs.
    @MainActor
    private static func sharedRenderer(for cameraAngle: CameraAngle) -> MetalRenderer {
        let widthMode: CameraWidthMode = cameraAngle == .singleCenter ? .single : .dual
        if let renderer = MetalRenderer.shared {
            renderer.setCameraWidthMode(widthMode)
            return renderer
        }
        return .init(cameraWidthMode: widthMode)
    }

    private func commonInit() {
        MetalRenderer.shared = renderer
        metalLayer.framebufferOnly = false
        metalLayer.isOpaque = true
    }
    
    override func draw(_ rect: CGRect) {
        #if canImport(UIKit)
        // Same guard, and the same reason, as `MetalRenderer.draw()`: a backgrounded app may not submit GPU
        // work, and this view's draws are driven by `MTKView`'s own display link, which nothing pauses. Without
        // this every frame spent in the background would commit a buffer the GPU rejects — and, worse for the
        // gate below, take a drawable that is then never presented.
        guard UIApplication.shared.applicationState != .background else { return }
        #endif

        // Zero timeout: this must never wait. If every drawable is still out, drop the frame and give the main
        // thread straight back to the show.
        guard inFlightFrames.wait(timeout: .now()) == .success else { return }
        guard let drawable = currentDrawable else {
            inFlightFrames.signal()
            return
        }

        #if !targetEnvironment(simulator)
        // Release the slot when the frame reaches the *screen*, because that is when its drawable rejoins the
        // pool. GPU completion is the wrong signal here and not merely an early one: the failure this gate
        // exists to stop is presented frames not retiring, and the blit into a stuck drawable still completes
        // happily — so a completion-clocked gate would keep opening through the exact stall it is meant to
        // catch, and go on calling `currentDrawable` into the one-second wait.
        //
        // Device-only: `MTLDrawable.addPresentedHandler` is declared in the device SDKs but not the simulator
        // ones, so the simulator clocks the gate on completion below instead.
        drawable.addPresentedHandler { [inFlightFrames] _ in
            inFlightFrames.signal()
        }
        #endif

        let commandBuffer = commandQueue.makeCommandBuffer()!
        #if targetEnvironment(simulator)
        // The simulator's substitute for the presented handler. Nothing is lost: the stall the presented-clocked
        // gate guards against is a real display pipeline holding drawables, which the simulator doesn't have.
        commandBuffer.addCompletedHandler { [inFlightFrames] _ in
            inFlightFrames.signal()
        }
        #else
        // A frame that fails never reaches the screen, so its presented handler never runs and its slot would
        // be gone for the life of the process — after `maximumDrawableCount` of those the gate never opens and
        // the window is dark for good. Release it here instead. The two handlers can both fire for one frame,
        // and that asymmetry is deliberate: over-signalling only risks acquiring against an empty pool and
        // blocking a frame, while under-signalling strands the window permanently.
        commandBuffer.addCompletedHandler { [inFlightFrames] buffer in
            if buffer.error != nil {
                inFlightFrames.signal()
            }
        }
        #endif
        let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
        let renderedWidth = renderer.mainTexture.width
        let renderedHeight = renderer.mainTexture.height

        // Blit the mainTexture to the drawable texture
        blitEncoder.copy(
            from: renderer.mainTexture,
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: MTLOrigin(x: cameraAngle == .dualRight ? (renderer.screenWidthPixels + renderer.interScreenSpacingPixels) : 0, y: 0, z: 0),
            sourceSize: MTLSize(
                width: min(drawable.texture.width, renderer.screenWidthPixels),
                height: min(drawable.texture.height, renderedHeight),
                depth: 1),
            to: drawable.texture,
            destinationSlice: 0,
            destinationLevel: 0,
            destinationOrigin: MTLOrigin(
                x: max(0, (drawable.texture.width - renderedWidth) / 2),
                y: max(0, (drawable.texture.height - renderedHeight) / 2),
                z: 0))
        blitEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

#if canImport(UIKit)
/// Forwards `CADisplayLink` ticks to the renderer. The link retains its target, so it holds this proxy (not the
/// renderer) and the proxy references the renderer weakly — otherwise the renderer could never deinit.
@MainActor
private final class DisplayLinkProxy: NSObject {
    weak var renderer: MetalRenderer?
    @objc func tick() {
        renderer?.draw()
    }
}
#endif

/// A shared renderer that can render extra-wide and/or upscaled frames for 1 or 2 views to display
@MainActor
final class MetalRenderer {
    
    static weak var shared: MetalRenderer?
    
    let scene = SpaceSceneController()
    
    var cameraWidthMode: CameraWidthMode
    var mainTexture: MTLTexture!
    var screenWidthPixels: Int {
        screenWidthPoints * pixelsPerPoint
    }
    var interScreenSpacingPixels: Int {
        interScreenSpacingPoints * pixelsPerPoint
    }
    
    private let device = MTLCreateSystemDefaultDevice()
    /// Views must encode their blits to drawables on this queue, so they cannot run mid-frame and show a partially post-processed `mainTexture`
    private(set) var commandQueue: MTLCommandQueue!
    private var textureDesc = MTLTextureDescriptor()
    private var assetReader: AVAssetReader?
    private var videoFrameProvider: AVAssetReaderOutput.Provider<CMReadySampleBuffer<CMSampleBuffer.DynamicContent>>?
    /// The frame `readNextVideoFrame()` has finished decoding, waiting for the `draw()` that will consume it.
    private var decodedVideoFrame: CMReadySampleBuffer<CMSampleBuffer.DynamicContent>?
    private var videoFrameTask: Task<Void, Never>?
    private var videoReachedEnd = false
    /// Created once and reused for every hyperspace video frame — rebuilding it per frame is expensive and pointless.
    private var videoTextureCache: CVMetalTextureCache?
    #if canImport(MetalFX)
    private var scaler: MTLFXSpatialScaler?
    #endif
    private let frameTime: TimeInterval = 1/60
    #if canImport(UIKit)
    private let displayLinkProxy = DisplayLinkProxy()
    private var displayLink: CADisplayLink?
    private var lifecycleObservers: [NSObjectProtocol] = []
    #else
    private var renderTask: Task<Void, Never>?
    #endif
    private var bloomBrightTexture: MTLTexture!
    private var bloomBlurredTexture: MTLTexture!
    private var bloomBrightPass: MTLComputePipelineState!
    private var bloomBlur: MPSImageGaussianBlur!
    private var bloomAdd: MPSImageAdd!
    private let pixelFormat: MTLPixelFormat = .bgra8Unorm
    private let screenWidthPoints = 1920
    private let interScreenSpacingPoints = 32
    private var pixelsPerPoint: Int {
        #if DEBUG
        1
        #else
        2
        #endif
    }

    init(cameraWidthMode: CameraWidthMode) {
        self.cameraWidthMode = cameraWidthMode
        makeMainTexture(cameraWidthMode: cameraWidthMode)
        makeBloomResources()
        commandQueue = device!.makeCommandQueue()

        #if canImport(UIKit)
        // Drive the scene from the display link rather than a main-actor `Task.sleep` loop: when the app is idle
        // the main run loop parks and those continuations aren't serviced, so the scene froze until the next
        // event (e.g. moving the mouse). A display link in `.common` mode keeps firing while the loop is idle.
        // Capped to 60fps to preserve the fixed `frameTime` deltaTime and the hyperspace video's one-frame-per-draw cadence.
        displayLinkProxy.renderer = self
        let displayLink = CADisplayLink(target: displayLinkProxy, selector: #selector(DisplayLinkProxy.tick))
        displayLink.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink

        // Park the link while backgrounded so it isn't waking the CPU 60×/s to draw nothing (the app stays alive
        // in the background for its audio session). The `draw()` guard already blocks GPU submission; this just
        // stops the pointless ticks.
        for name in [UIApplication.didEnterBackgroundNotification, UIApplication.willEnterForegroundNotification] {
            let paused = name == UIApplication.didEnterBackgroundNotification
            let token = NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.displayLink?.isPaused = paused
                }
            }
            lifecycleObservers.append(token)
        }
        #else
        renderTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self.frameTime))
                if Task.isCancelled { return }
                self.draw()
            }
        }
        #endif
    }

    isolated deinit {
        #if canImport(UIKit)
        displayLink?.invalidate()
        lifecycleObservers.forEach { NotificationCenter.default.removeObserver($0) }
        #endif
        videoFrameTask?.cancel()
        assetReader?.cancelReading()
    }
    
    /// Open the video, then start the jump. Throws without having touched the scene if the video can't be read.
    ///
    /// Opening first is what makes the jump all-or-nothing: the camera animation into hyperspace is only ever
    /// undone by the video reaching its end, so a jump whose video fails half way in would leave the camera —
    /// and, through `ShipState.isInHyperspace`, the room's HomeKit lights — stuck there until the app relaunched.
    /// `ShipState.hyperspaceJump` only commits `isInHyperspace` once this returns.
    func jumpToHyperspace() async throws {
        let reader = try await makeVideoReader()

        AudioController.shared.play(.hyperspaceJumpInternal)
        scene.playHyperspaceJumpCameraAnimation(intoHyperspace: true)
        // The camera spends half a second flying into the jump before the video takes over the screen. The reader
        // is already decoding by now, so it spends the wait filling its buffer rather than starting cold.
        try? await ShowClock.shared.sleep(for: .seconds(0.5))
        play(reader)
    }
    
    /// Switch between single- and dual-width rendering without tearing down the scene. A second view (e.g. the
    /// right half of a dual setup) can join the shared renderer and just resize its textures, preserving the
    /// `SpaceSceneController` and all its loaded entities / in-flight story state.
    func setCameraWidthMode(_ cameraWidthMode: CameraWidthMode) {
        guard self.cameraWidthMode != cameraWidthMode else { return }
        self.cameraWidthMode = cameraWidthMode
        makeMainTexture(cameraWidthMode: cameraWidthMode)
        makeBloomResources()
    }

    private func makeMainTexture(cameraWidthMode: CameraWidthMode) {
        textureDesc.pixelFormat = pixelFormat
        textureDesc.width = screenWidthPixels * (cameraWidthMode == .single ? 1 : 2) + (cameraWidthMode == .single ? 0 : interScreenSpacingPixels)
        textureDesc.height = 1080 * pixelsPerPoint
        textureDesc.usage = [.renderTarget, .shaderRead]
        textureDesc.storageMode = .private
        mainTexture = device!.makeTexture(descriptor: textureDesc)!
    }
    
    fileprivate func draw() {
        #if canImport(UIKit)
        // iOS/visionOS forbid submitting GPU work while the app is backgrounded. This app keeps running in the
        // background (its audio session drives the ambience), so without this guard the display link would keep
        // committing a command buffer every frame and the GPU would reject each one every frame
        // (kIOGPUCommandBufferCallbackErrorBackgroundExecutionNotPermitted). A foregrounded immersive space is
        // never `.background`, so this never freezes the live scene.
        guard UIApplication.shared.applicationState != .background else { return }
        #endif
        let commandBuffer = commandQueue.makeCommandBuffer()!
        
        switch nextHyperspaceFrame() {
        case .frame(let frame):
            frame.withUnsafeSampleBuffer { copyVideoFrame(from: $0, commandBuffer: commandBuffer) }
        case .stalled:
            // The next frame hasn't finished decoding in time for this vsync. Leave `mainTexture` alone so the
            // previous video frame stays up for one more frame — cutting back to the scene mid-jump would read
            // as a glitch, and re-rendering the scene underneath the video is work nobody would see.
            break
        case .notPlaying:
            let event = device!.makeEvent()!
            let realityRenderer = scene.realityRenderer
            let descriptor = RealityKit.RealityRenderer.CameraOutput.Descriptor.singleProjection(
                colorTexture: mainTexture // can I render this directly into the drawable?
            )
            do {
                try realityRenderer.updateAndRender(
                    deltaTime: frameTime,
                    cameraOutput: .init(descriptor),
                    actionsAfterRender: [
                        .signal(event, value: 1)
                    ])
                // Only wait for/consume the render if it was actually issued — otherwise the event never
                // signals and the GPU would stall.
                commandBuffer.encodeWaitForEvent(event, value: 1)
                // Bloom turns the bright opening crawl into an unreadable smear — skip it while the crawl shows.
                if !scene.isShowingCrawl {
                    postProcess(commandBuffer: commandBuffer)
                }
            } catch {
                print("RealityRenderer updateAndRender failed: \(error)") // Drop the frame rather than crash the show
            }
        }

        commandBuffer.commit()
    }

    /// What the hyperspace video has for this `draw()`, if it is playing at all.
    private enum HyperspaceFrame {
        case frame(CMReadySampleBuffer<CMSampleBuffer.DynamicContent>)
        /// Playing, but the next frame is still decoding.
        case stalled
        case notPlaying
    }

    /// Take the decoded hyperspace frame this draw should show, and start decoding the one after it.
    ///
    /// Reaching the end of the video is what ends the jump, so that teardown lives here.
    private func nextHyperspaceFrame() -> HyperspaceFrame {
        guard videoFrameProvider != nil else { return .notPlaying }
        if let frame = decodedVideoFrame {
            decodedVideoFrame = nil
            readNextVideoFrame()
            return .frame(frame)
        }
        guard videoReachedEnd else { return .stalled }
        endHyperspaceVideo()
        return .notPlaying
    }

    /// Start decoding the frame after the one `draw()` is about to show.
    ///
    /// `AVAssetReaderOutput.Provider.next()` is async but `draw()` is a synchronous display-link callback, so the
    /// two are decoupled through a one-frame slot: every draw takes the frame the reader has finished and
    /// immediately asks for the next. Decoding a 60fps clip comfortably outruns the 60fps display link, so this
    /// keeps the video's one-frame-per-draw cadence; a draw that beats the decoder gets `.stalled` instead.
    private func readNextVideoFrame() {
        guard videoFrameTask == nil, !videoReachedEnd else { return }
        videoFrameTask = Task { [weak self] in
            guard let provider = self?.videoFrameProvider else { return }
            // A thrown error means the reader failed or was cancelled; both end the jump, same as running out of
            // frames does, so they share the `nil` path.
            let frame = try? await provider.next()
            guard let self, !Task.isCancelled else { return }
            videoFrameTask = nil
            if let frame {
                decodedVideoFrame = frame
            } else {
                videoReachedEnd = true
            }
        }
    }

    /// Tear the reader down and fly the camera back out of hyperspace.
    private func endHyperspaceVideo() {
        videoFrameTask?.cancel()
        videoFrameTask = nil
        videoFrameProvider = nil
        decodedVideoFrame = nil
        videoReachedEnd = false
        assetReader?.cancelReading()
        assetReader = nil
        scene.playHyperspaceJumpCameraAnimation(intoHyperspace: false)
        Task {
            try? await ShipState.shared.hyperspaceJump(intoHyperspace: false)
        }
    }
    
    private func makeBloomResources() {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: textureDesc.width,
            height: textureDesc.height,
            mipmapped: false)
        descriptor.usage = [.shaderRead, .shaderWrite]
        descriptor.storageMode = .private
        bloomBrightTexture = device!.makeTexture(descriptor: descriptor)!
        bloomBlurredTexture = device!.makeTexture(descriptor: descriptor)!

        let library = device!.makeDefaultLibrary()!
        bloomBrightPass = try! device!.makeComputePipelineState(function: library.makeFunction(name: "bloomBrightPass")!)
        bloomBlur = MPSImageGaussianBlur(device: device!, sigma: 15.0 * Float(pixelsPerPoint))
        bloomBlur.edgeMode = .clamp
        bloomAdd = MPSImageAdd(device: device!)
    }

    /// Apply a bloom effect: isolate the bright areas, blur them, and add them back over the frame
    private func postProcess(commandBuffer: MTLCommandBuffer) {
        // Reference: https://developer.apple.com/videos/play/wwdc2025/288/
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        computeEncoder.setComputePipelineState(bloomBrightPass)
        computeEncoder.setTexture(mainTexture, index: 0)
        computeEncoder.setTexture(bloomBrightTexture, index: 1)
        let threadWidth = bloomBrightPass.threadExecutionWidth
        computeEncoder.dispatchThreads(
            MTLSize(width: mainTexture.width, height: mainTexture.height, depth: 1),
            threadsPerThreadgroup: MTLSize(width: threadWidth, height: bloomBrightPass.maxTotalThreadsPerThreadgroup / threadWidth, depth: 1))
        computeEncoder.endEncoding()
        bloomBlur.encode(commandBuffer: commandBuffer, sourceTexture: bloomBrightTexture, destinationTexture: bloomBlurredTexture)
        bloomAdd.encode(commandBuffer: commandBuffer, primaryTexture: mainTexture, secondaryTexture: bloomBlurredTexture, destinationTexture: bloomBrightTexture)

        let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
        blitEncoder.copy(from: bloomBrightTexture, to: mainTexture)
        blitEncoder.endEncoding()
    }
    
    /// Copy a frame from a video file into the main texture
    private func copyVideoFrame(from sampleBuffer: CMSampleBuffer, commandBuffer: MTLCommandBuffer)  {
        // Runs per-frame during the hyperspace video: drop the frame on any failure rather than crash the show.
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        if videoTextureCache == nil {
            CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device!, nil, &videoTextureCache)
        }
        guard let videoTextureCache else { return }

        var cvTexture: CVMetalTexture? = nil
        CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            videoTextureCache,
            imageBuffer,
            nil,
            textureDesc.pixelFormat,
            CVPixelBufferGetWidth(imageBuffer),
            CVPixelBufferGetHeight(imageBuffer),
            0,
            &cvTexture)

        guard let cvTexture else { return }

        let mtlTexture = CVMetalTextureGetTexture(cvTexture)

        // Keep the CVMetalTexture alive until the GPU has finished reading it. Letting it release at the end of
        // this function (as before) freed the backing IOSurface while the scaler was still reading it — undefined
        // behavior that showed up as flicker during the hyperspace climax.
        let keepAlive = TextureKeepAlive(texture: cvTexture)
        commandBuffer.addCompletedHandler { _ in
            _ = keepAlive
        }

        #if canImport(MetalFX)
        // Upscale
        if let scaler {
            scaler.colorTexture = mtlTexture
            scaler.inputContentWidth = CVPixelBufferGetWidth(imageBuffer)
            scaler.inputContentHeight = CVPixelBufferGetHeight(imageBuffer)
            scaler.outputTexture = mainTexture
            scaler.encode(commandBuffer: commandBuffer)
        }
        #endif
    }
    
    /// A reader that has been opened and started, but is not yet the one `draw()` is pulling frames from.
    private struct VideoReader {
        let assetReader: AVAssetReader
        let provider: AVAssetReaderOutput.Provider<CMReadySampleBuffer<CMSampleBuffer.DynamicContent>>
    }

    /// Open the hyperspace video and start reading it. Nothing on screen changes until `play(_:)` takes the result.
    private func makeVideoReader() async throws -> VideoReader {
        let sourceMovieAsset = AVURLAsset(url: Bundle.main.url(forResource: "hyperspace", withExtension: "mp4")!)
        let assetReader = try AVAssetReader(asset: sourceMovieAsset)
        let track = try await sourceMovieAsset.loadTracks(withMediaType: .video)[0]

        // Create the asset reader track output for this video track, requesting ‘y416’ output
        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferMetalCompatibilityKey as String: true
        ]

        let assetReaderTrackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)

        // Attaching a provider is what connects the track output to the reader — it replaces `add(_:)`, and the
        // samples then arrive through `Provider.next()` instead of `copyNextSampleBuffer()`.
        let provider = assetReader.outputProvider(for: assetReaderTrackOutput)
        try assetReader.start()

        return VideoReader(assetReader: assetReader, provider: provider)
    }

    /// Hand a started reader to `draw()`, which shows video instead of the scene from its next tick.
    private func play(_ reader: VideoReader) {
        // Drop any previous reader first, including an in-flight decode — otherwise it could land in the slot
        // after this one is installed and play a frame of the last jump.
        videoFrameTask?.cancel()
        videoFrameTask = nil
        assetReader?.cancelReading()

        assetReader = reader.assetReader
        videoFrameProvider = reader.provider
        decodedVideoFrame = nil
        videoReachedEnd = false
        // Prime the slot so the next `draw()` has a frame waiting rather than stalling on the first one.
        readNextVideoFrame()

        #if canImport(MetalFX)
        // Setup scaler
        let scalerDesc = MTLFXSpatialScalerDescriptor()
        scalerDesc.inputWidth = 3840
        scalerDesc.inputHeight = 1606
        scalerDesc.colorTextureFormat = pixelFormat
        scalerDesc.outputWidth = textureDesc.width
        scalerDesc.outputHeight = textureDesc.height
        scalerDesc.outputTextureFormat = pixelFormat
        scaler = scalerDesc.makeSpatialScaler(device: device!)
        #endif
    }

    /// Holds a `CVMetalTexture` — a CoreFoundation type with no `Sendable` annotation — across a Metal completion
    /// handler, which is `@Sendable`. Nothing reads the texture there; the handler exists only to drop it once the
    /// GPU is done, so the unchecked conformance covers a lifetime, not shared access.
    private struct TextureKeepAlive: @unchecked Sendable {
        let texture: CVMetalTexture
    }
    
}
