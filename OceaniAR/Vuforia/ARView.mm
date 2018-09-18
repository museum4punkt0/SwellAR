//
//  ARView.m
//  Phantomat
//
//  Created by Michael Schröder on 10.08.14.
//  Copyright (c) 2014 Michael Schröder. All rights reserved.
//

#import <GLKit/GLKit.h>
#import <stdatomic.h>

#import <Vuforia/Vuforia.h>
#import <Vuforia/Vuforia_iOS.h>
#import <Vuforia/CameraDevice.h>
#import <Vuforia/DataSet.h>
#import <Vuforia/Device.h>
#import <Vuforia/GLRenderer.h>
#import <Vuforia/ImageTarget.h>
#import <Vuforia/ObjectTracker.h>
#import <Vuforia/Matrices.h>
#import <Vuforia/Renderer.h>
#import <Vuforia/RenderingPrimitives.h>
#import <Vuforia/State.h>
#import <Vuforia/StateUpdater.h>
#import <Vuforia/Tool.h>
#import <Vuforia/TrackableResult.h>
#import <Vuforia/TrackerManager.h>
#import <Vuforia/UIGLViewProtocol.h>
#import <Vuforia/UpdateCallback.h>
#import <Vuforia/VideoBackgroundConfig.h>

#import "ARView.h"
#import "VuforiaDataSet_Internal.h"

namespace {
    ARView *ARViewInstance;
    class VuforiaApplication_UpdateCallback : public Vuforia::UpdateCallback {
        virtual void Vuforia_onUpdate(Vuforia::State& state);
    } vuforiaUpdate;
}

@implementation ARView {
    EAGLContext *_context;
    GLuint _framebuffer;
    GLuint _colorRenderbuffer;
    GLuint _depthRenderbuffer;
    BOOL _needsFramebufferInit;
    
    Vuforia::RenderingPrimitives *_currentRenderingPrimitives;
    Vuforia::VIEW _currentView;
    Vuforia::ObjectTracker *_tracker;
    GLKBaseEffect *_videoBackgroundEffect;
    
    // video background shader
    GLuint _vbShaderProgramID;
    GLint _vbVertexHandle;
    GLint _vbTexCoordHandle;
    GLint _vbTexSampler2DHandle;
    GLint _vbProjectionMatrixHandle;
    BOOL _videoBackgroundShaderNeedsInit;

    BOOL _needsDataSetUpdate;
    dispatch_queue_t _dataSetUpdateQueue;
    NSMutableSet<VuforiaDataSet *> *_nextDataSetsToActivate;
    NSMutableSet<VuforiaDataSet *> *_nextDataSetsToDeactivate;
    NSMutableSet<VuforiaDataSet *> *_activeDataSets;
    
    NSMutableSet<NSString *> *_visibleTargets;
    
    NSMutableArray *_sortedTouches;
    
    BOOL _started;
}

volatile atomic_bool _VuforiaInitialized = false;

+ (nonnull NSString *)vuforiaVersion {
    return [NSString stringWithCString:Vuforia::getLibraryVersion() encoding:NSASCIIStringEncoding];
}

+ (BOOL)isVuforiaInitialized {
    return _VuforiaInitialized;
}

+ (void)initializeVuforiaWithLicenseKey:(nonnull NSString *)key completionHandler:(nonnull void (^)(ARViewInitializationResult, int))completionHandler {
    if (_VuforiaInitialized != 0) {
        completionHandler(ARViewInitializationOK, 100);
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Vuforia::setInitParameters(Vuforia::GL_20, key.UTF8String);
        int progress;
        do {
            progress = Vuforia::init();
        }
        while (0 <= progress && progress < 100);
        ARViewInitializationResult result;
        if (progress == 100) {
            result = ARViewInitializationOK;
            atomic_fetch_or(&_VuforiaInitialized, true);
        } else if (progress == Vuforia::INIT_LICENSE_ERROR_NO_NETWORK_TRANSIENT) {
            result = ARViewInitializationServerUnavailable;
        } else if (progress == Vuforia::INIT_LICENSE_ERROR_NO_NETWORK_PERMANENT) {
            result = ARViewInitializationNetworkUnavailable;
        } else {
            result = ARViewInitializationFail;
        }
        completionHandler(result, progress);
    });
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self commonInit];
}

- (void)commonInit
{
    NSAssert(!ARViewInstance, @"There can only be one ARView instance.");
    ARViewInstance = self;

    _dataSetUpdateQueue = dispatch_queue_create("ARView.dataSetUpdate", DISPATCH_QUEUE_SERIAL);
    _nextDataSetsToActivate = [NSMutableSet set];
    _nextDataSetsToDeactivate = [NSMutableSet set];
    _activeDataSets = [NSMutableSet set];
    
    _visibleTargets = [NSMutableSet set];
    
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    _context.multiThreaded = YES;
    _needsFramebufferInit = YES;
    _videoBackgroundShaderNeedsInit = YES;
    _videoGravity = ARViewVideoGravityResizeAspectFill;
    self.contentScaleFactor = [UIScreen mainScreen].scale;
    
    _sortedTouches = [NSMutableArray array];
    self.multipleTouchEnabled = YES;
    
    self.backgroundColor = UIColor.blackColor;
}

- (void)start {
    if (![ARView isVuforiaInitialized]) return;
    if (_started) return;
    
    if (!_tracker) {
        Vuforia::registerCallback(&vuforiaUpdate);
        Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
        _tracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.initTracker(Vuforia::ObjectTracker::getClassType()));
    }
    _tracker->start();
    Vuforia::setHint(Vuforia::HINT_MAX_SIMULTANEOUS_IMAGE_TARGETS, 10);
    
    Vuforia::onSurfaceCreated();
    [self layoutVuforiaSurface];
    Vuforia::onResume();
    Vuforia::CameraDevice::getInstance().init(Vuforia::CameraDevice::CAMERA_DIRECTION_BACK);
    Vuforia::CameraDevice::getInstance().start();
    [self reconfigureCamera];
    
    Vuforia::Device& device = Vuforia::Device::getInstance();
    device.setMode(Vuforia::Device::MODE_AR);
    device.setViewerActive(false);
    
    [self updateRenderingPrimitives];
    
    _started = YES;
}

- (void)stop {
    if (![ARView isVuforiaInitialized]) return;
    if (!_started) return;

    Vuforia::CameraDevice::getInstance().stop();
    Vuforia::CameraDevice::getInstance().deinit();
    Vuforia::onPause();

    _tracker->stop();

    _started = NO;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stop];
}

// ----------------------------------------------------------------------------

- (void)Vuforia_onUpdate:(Vuforia::State *)state
{
    dispatch_sync(_dataSetUpdateQueue, ^{
        if (self->_needsDataSetUpdate) {
            for (VuforiaDataSet *dataSet in self->_nextDataSetsToDeactivate) {
                self->_tracker->deactivateDataSet(dataSet.dataSet);
                [self->_activeDataSets removeObject:dataSet];
            }
            [self->_nextDataSetsToDeactivate removeAllObjects];
            for (VuforiaDataSet *dataSet in self->_nextDataSetsToActivate) {
                self->_tracker->activateDataSet(dataSet.dataSet);
                [self->_activeDataSets addObject:dataSet];
            }
            [self->_nextDataSetsToActivate removeAllObjects];
            self->_needsDataSetUpdate = NO;
        }
    });
}

void VuforiaApplication_UpdateCallback::Vuforia_onUpdate(Vuforia::State& state)
{
    [ARViewInstance Vuforia_onUpdate:&state];
}

- (void)activateDataSet:(VuforiaDataSet *)dataSet {
    dispatch_async(_dataSetUpdateQueue, ^{
        [self->_nextDataSetsToDeactivate removeObject:dataSet];
        [self->_nextDataSetsToActivate addObject:dataSet];
        self->_needsDataSetUpdate = YES;
    });
}

- (void)deactivateDataSet:(VuforiaDataSet *)dataSet {
    dispatch_async(_dataSetUpdateQueue, ^{
        [self->_nextDataSetsToDeactivate addObject:dataSet];
        [self->_nextDataSetsToActivate removeObject:dataSet];
        self->_needsDataSetUpdate = YES;
    });
}

- (NSSet<VuforiaDataSet *> *)activeDataSets {
    return [_activeDataSets copy];
}

// ----------------------------------------------------------------------------

- (void)setVideoGravity:(ARViewVideoGravity)videoGravity
{
    if (_videoGravity != videoGravity) {
        _videoGravity = videoGravity;
        [self reconfigureCamera];
    }
}

- (void)setVideoOrientation:(ARViewVideoOrientation)videoOrientation
{
    if (_videoOrientation != videoOrientation) {
        _videoOrientation = videoOrientation;
        [self reconfigureCamera];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_started) {
        [self reconfigureCamera];
    }
}

- (void)reconfigureCamera
{
    [self layoutVuforiaSurface];
    [self configureVideoBackground];
    [self updateRenderingPrimitives];
    _needsFramebufferInit = YES;
}

- (CGSize)physicalViewSize
{
    return CGSizeMake(self.bounds.size.width * self.contentScaleFactor, self.bounds.size.height * self.contentScaleFactor);
}

- (CGSize)renderViewSize {
    return self.physicalViewSize;
}

-(void)layoutVuforiaSurface {
    CGSize size = [self physicalViewSize];
    Vuforia::onSurfaceChanged(size.width, size.height);
    switch (_videoOrientation) {
        case ARViewVideoOrientationLandscapeRight:      Vuforia::setRotation(Vuforia::ROTATE_IOS_0);   break;
        case ARViewVideoOrientationPortrait:            Vuforia::setRotation(Vuforia::ROTATE_IOS_90);  break;
        case ARViewVideoOrientationLandscapeLeft:       Vuforia::setRotation(Vuforia::ROTATE_IOS_180); break;
        case ARViewVideoOrientationPortraitUpsideDown:  Vuforia::setRotation(Vuforia::ROTATE_IOS_270); break;
    }
}

- (void)configureVideoBackground
{
    Vuforia::CameraDevice& cameraDevice = Vuforia::CameraDevice::getInstance();
    Vuforia::VideoMode videoMode = cameraDevice.getVideoMode(Vuforia::CameraDevice::MODE_DEFAULT);
    CGSize videoSize = CGSizeMake(videoMode.mWidth, videoMode.mHeight);
    CGSize viewSize = [self physicalViewSize];
    CGSize finalSize;
    
    if (_videoGravity == ARViewVideoGravityResize) {
        finalSize = viewSize;
    }
    
    else {
        CGFloat videoRatio = videoSize.width / videoSize.height;
        
        if (_videoOrientation == ARViewVideoOrientationPortrait ||
            _videoOrientation == ARViewVideoOrientationPortraitUpsideDown)
        {
            float viewRatio = viewSize.height / viewSize.width;
            if ((_videoGravity == ARViewVideoGravityResizeAspect && videoRatio > viewRatio) ||
                (_videoGravity == ARViewVideoGravityResizeAspectFill && videoRatio < viewRatio))
            {
                finalSize.width = videoSize.height * (viewSize.height / videoSize.width);
                finalSize.height = viewSize.height;
            } else {
                finalSize.width = viewSize.width;
                finalSize.height = videoSize.width * (viewSize.width / videoSize.height);
            }
        } else {
            float viewRatio = viewSize.width / viewSize.height;
            if ((_videoGravity == ARViewVideoGravityResizeAspect && videoRatio > viewRatio) ||
                (_videoGravity == ARViewVideoGravityResizeAspectFill && videoRatio < viewRatio))
            {
                finalSize.width = viewSize.width;
                finalSize.height = videoSize.height * (viewSize.width / videoSize.width);
            } else {
                finalSize.width = videoSize.width * (viewSize.height / videoSize.height);
                finalSize.height = viewSize.height;
            }
        }
    }
   
    Vuforia::VideoBackgroundConfig config;
    config.mEnabled = true;
    config.mPosition.data[0] = 0;
    config.mPosition.data[1] = 0;
    config.mSize.data[0] = finalSize.width;
    config.mSize.data[1] = finalSize.height;
    Vuforia::Renderer::getInstance().setVideoBackgroundConfig(config);
}

// ----------------------------------------------------------------------------

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)updateRenderingPrimitives {
    delete _currentRenderingPrimitives;
    _currentRenderingPrimitives = new Vuforia::RenderingPrimitives(Vuforia::Device::getInstance().getRenderingPrimitives());
}

- (void)renderFrameVuforia {
    if (_renderingPaused) return;
    if (!_started) return;
    
    Vuforia::Renderer& renderer = Vuforia::Renderer::getInstance();
    
    const Vuforia::State state = Vuforia::TrackerManager::getInstance().getStateUpdater().updateState();
    renderer.begin(state);
    
    if (Vuforia::Renderer::getInstance().getVideoBackgroundConfig().mReflection == Vuforia::VIDEO_BACKGROUND_REFLECTION_ON) {
        glFrontFace(GL_CW);  // front camera
    } else {
        glFrontFace(GL_CCW);  // back camera
    }
    
    if (_currentRenderingPrimitives == nullptr) {
        [self updateRenderingPrimitives];
    }
    
    Vuforia::ViewList& viewList = _currentRenderingPrimitives->getRenderingViews();
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    
    for (int viewIdx = 0; viewIdx < viewList.getNumViews(); viewIdx++) {
        _currentView = viewList.getView(viewIdx);
        
        Vuforia::Vec4I viewport = _currentRenderingPrimitives->getViewport(_currentView);
        glViewport(viewport.data[0], viewport.data[1], viewport.data[2], viewport.data[3]);
        glScissor(viewport.data[0], viewport.data[1], viewport.data[2], viewport.data[3]);
        _viewport = CGRectMake(viewport.data[0], viewport.data[1], viewport.data[2], viewport.data[3]);
        
        if (_currentView != Vuforia::VIEW_POSTPROCESS) {
            Vuforia::Matrix34F projMatrix = _currentRenderingPrimitives->getProjectionMatrix(_currentView, Vuforia::COORDINATE_SYSTEM_CAMERA, state.getCameraCalibration());
            GLKMatrix4 rawProjectionMatrixGL = GLKMatrix4MakeWithArray(Vuforia::Tool::convertPerspectiveProjection2GLMatrix(projMatrix, 5, 5000).data);
            GLKMatrix4 eyeAdjustmentGL = GLKMatrix4MakeWithArray(Vuforia::Tool::convert2GLMatrix(_currentRenderingPrimitives->getEyeDisplayAdjustmentMatrix(_currentView)).data);
            GLKMatrix4 projectionMatrix = GLKMatrix4Multiply(rawProjectionMatrixGL, eyeAdjustmentGL);
            
            [self renderFrameWithState:state projectionMatrix:projectionMatrix];
        }
        
        glDisable(GL_SCISSOR_TEST);
    }
    
    renderer.end();
}

- (void)renderFrameWithState:(const Vuforia::State &)state projectionMatrix:(GLKMatrix4)projectionMatrix {
    _projectionMatrix = projectionMatrix;
    
    auto illumination = state.getIllumination();
    if (illumination == nullptr) {
        _ambientIntensity = 1000;
        _ambientColorTemperature = 6500;
    } else {
        float ambientIntensity = illumination->getAmbientIntensity();
        if (ambientIntensity == Vuforia::Illumination::AMBIENT_INTENSITY_UNAVAILABLE) {
            _ambientIntensity = 1000;
        } else {
            _ambientIntensity = ambientIntensity;
        }
        float ambientColorTemperature = illumination->getAmbientColorTemperature();
        if (ambientColorTemperature == Vuforia::Illumination::AMBIENT_COLOR_TEMPERATURE_UNAVAILABLE) {
            _ambientColorTemperature = 6500;
        } else {
            _ambientColorTemperature = ambientColorTemperature;
        }
    }
    
    [EAGLContext setCurrentContext:_context];
    if (_needsFramebufferInit) {
        [self performSelectorOnMainThread:@selector(initFramebuffer) withObject:self waitUntilDone:YES];
    }
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self renderVideoBackground];
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);

    if (Vuforia::Renderer::getInstance().getVideoBackgroundConfig().mReflection == Vuforia::VIDEO_BACKGROUND_REFLECTION_ON) {
        glFrontFace(GL_CW);
    } else {
        glFrontFace(GL_CCW);
    }

    NSDate *now = [NSDate date];
    NSMutableSet<NSString *> *previouslyVisibleTargets = [_visibleTargets mutableCopy];
    NSMutableSet<NSString *> *currentlyVisibleTargets = [NSMutableSet set];
    
    for (int i = 0; i < state.getNumTrackableResults(); ++i) {
        const Vuforia::TrackableResult *result = state.getTrackableResult(i);
        const Vuforia::ImageTarget &vuforiaTarget = (Vuforia::ImageTarget&)result->getTrackable();

        NSString *name = @(vuforiaTarget.getName());
        [currentlyVisibleTargets addObject:name];
        if (![previouslyVisibleTargets containsObject:name]) {
            [_visibleTargets addObject:name];
            [self.delegate arView:self targetDidAppear:name atDate:now];
        }
        
        Vuforia::Matrix34F pose = result->getPose();
        GLKMatrix4 modelviewMatrix = GLKMatrix4MakeWithArray(Vuforia::Tool::convertPose2GLMatrix(pose).data);
        Vuforia::Vec3F position(pose.data[3], pose.data[7], pose.data[11]);
        GLfloat distance = sqrt(position.data[0] * position.data[0] + position.data[1] * position.data[1] + position.data[2] * position.data[2]);
        [self.delegate arView:self renderTarget:name withModelviewMatrix:modelviewMatrix atDistance:distance date:now];
    }
    
    [previouslyVisibleTargets minusSet:currentlyVisibleTargets];
    for (NSString *name in previouslyVisibleTargets) {
        [_visibleTargets removeObject:name];
        [self.delegate arView:self targetDidDisappear:name atDate:now];
    }
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_BLEND);
    glDisable(GL_CULL_FACE);
    
    Vuforia::Renderer::getInstance().end();
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)renderVideoBackground {
    if (_currentView == Vuforia::VIEW_POSTPROCESS) {
        return;
    }
    
    if (_videoBackgroundShaderNeedsInit) {
        [self initVideoBackgroundShader];
    }
    
    Vuforia::GLTextureUnit tex;
    tex.mTextureUnit = 0;
    
    if (!Vuforia::Renderer::getInstance().updateVideoBackgroundTexture(&tex)) {
        NSLog(@"error: unable to bind video background texture");
        return;
    }
    
    Vuforia::Matrix44F vbProjectionMatrix = Vuforia::Tool::convert2GLMatrix(_currentRenderingPrimitives->getVideoBackgroundProjectionMatrix(_currentView, Vuforia::COORDINATE_SYSTEM_CAMERA));
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    glDisable(GL_SCISSOR_TEST);
    
    const Vuforia::Mesh& vbMesh = _currentRenderingPrimitives->getVideoBackgroundMesh(_currentView);
    glUseProgram(_vbShaderProgramID);
    glVertexAttribPointer(_vbVertexHandle, 3, GL_FLOAT, false, 0, vbMesh.getPositionCoordinates());
    glVertexAttribPointer(_vbTexCoordHandle, 2, GL_FLOAT, false, 0, vbMesh.getUVCoordinates());
    glUniform1i(_vbTexSampler2DHandle, tex.mTextureUnit);
    glEnableVertexAttribArray(_vbVertexHandle);
    glEnableVertexAttribArray(_vbTexCoordHandle);
    glUniformMatrix4fv(_vbProjectionMatrixHandle, 1, GL_FALSE, vbProjectionMatrix.data);
    glDrawElements(GL_TRIANGLES, vbMesh.getNumTriangles() * 3, GL_UNSIGNED_SHORT, vbMesh.getTriangles());
    glDisableVertexAttribArray(_vbVertexHandle);
    glDisableVertexAttribArray(_vbTexCoordHandle);
}

- (void)initVideoBackgroundShader {
    GLuint vertexShader = [ARView compileShader:@"attribute vec4 vertexPosition;attribute vec2 vertexTexCoord;uniform mat4 projectionMatrix;varying vec2 texCoord;void main(){gl_Position = projectionMatrix * vertexPosition;texCoord = vertexTexCoord;}" ofType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [ARView compileShader:@"precision mediump float;varying vec2 texCoord;uniform sampler2D texSampler2D;void main (){gl_FragColor = texture2D(texSampler2D, texCoord);}" ofType:GL_FRAGMENT_SHADER];
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    _vbShaderProgramID = programHandle;
    _vbVertexHandle = glGetAttribLocation(_vbShaderProgramID, "vertexPosition");
    _vbTexCoordHandle = glGetAttribLocation(_vbShaderProgramID, "vertexTexCoord");
    _vbProjectionMatrixHandle = glGetUniformLocation(_vbShaderProgramID, "projectionMatrix");
    _vbTexSampler2DHandle = glGetUniformLocation(_vbShaderProgramID, "texSampler2D");
    _videoBackgroundShaderNeedsInit = NO;
}

+ (GLuint)compileShader:(NSString *)source ofType:(GLenum)type {
    GLuint handle = glCreateShader(type);
    const char *sourceUTF8 = [source UTF8String];
    GLint sourceLength = (GLint)[source length];
    glShaderSource(handle, 1, &sourceUTF8, &sourceLength);
    glCompileShader(handle);
    return handle;
}

- (void)initFramebuffer {
    [EAGLContext setCurrentContext:_context];
    if (!_framebuffer) {
        glGenFramebuffers(1, &_framebuffer);
        glGenRenderbuffers(1, &_colorRenderbuffer);
        glGenRenderbuffers(1, &_depthRenderbuffer);
    }
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    GLint width;
    GLint height;
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &width);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &height);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    _needsFramebufferInit = NO;
}

- (GLKVector2)normalizedDeviceCoordinates:(CGPoint)point
{
    CGSize viewSize = [self physicalViewSize];
    Vuforia::VideoBackgroundConfig config = Vuforia::Renderer::getInstance().getVideoBackgroundConfig();
    float x = (point.x * self.contentScaleFactor - viewSize.width/2) / (config.mSize.data[0]/2);
    float y = (point.y * self.contentScaleFactor - viewSize.height/2) / (config.mSize.data[1]/2) * -1;
    return GLKVector2Make(x, y);
}

- (CGPoint)convertPoint:(CGPoint)point toModelviewMatrix:(GLKMatrix4)modelviewMatrix size:(GLKVector2)size
{
    // Window Coordinates to Normalized Device Coordinates
    GLKVector2 coords = [self normalizedDeviceCoordinates:point];
    
    // Normalized Device Coordinates to Eye Coordinates
    GLKVector4 ndcNear = GLKVector4Make(coords.x, coords.y, -1, 1);
    GLKVector4 ndcFar = GLKVector4Make(coords.x, coords.y, 1, 1);
    GLKMatrix4 invProjMatrix = GLKMatrix4Invert(_projectionMatrix, NULL);
    GLKVector4 pointOnNearPlane = GLKMatrix4MultiplyVector4(invProjMatrix, ndcNear);
    GLKVector4 pointOnFarPlane = GLKMatrix4MultiplyVector4(invProjMatrix, ndcFar);
    pointOnNearPlane = GLKVector4DivideScalar(pointOnNearPlane, pointOnNearPlane.w);
    pointOnFarPlane = GLKVector4DivideScalar(pointOnFarPlane, pointOnFarPlane.w);
    
    // Eye Coordinates to Object Coordinates
    GLKMatrix4 invModelViewMatrix = GLKMatrix4Invert(modelviewMatrix, NULL);
    GLKVector4 nearWorld = GLKMatrix4MultiplyVector4(invModelViewMatrix, pointOnNearPlane);
    GLKVector4 farWorld = GLKMatrix4MultiplyVector4(invModelViewMatrix, pointOnFarPlane);
    
    // line plane intersection
    GLKVector3 lineStart = GLKVector3Make(nearWorld.x, nearWorld.y, nearWorld.z);
    GLKVector3 lineEnd = GLKVector3Make(farWorld.x, farWorld.y, farWorld.z);
    GLKVector3 lineDir = GLKVector3Normalize(GLKVector3Subtract(lineEnd, lineStart));
    GLKVector3 planeCenter = GLKVector3Make(0, 0, 0);
    GLKVector3 planeNormal = GLKVector3Make(0, 0, 1);
    GLKVector3 planeDir = GLKVector3Subtract(planeCenter, lineStart);
    float n = GLKVector3DotProduct(planeNormal, planeDir);
    float d = GLKVector3DotProduct(planeNormal, lineDir);
    float dist = fabsf(d) < FLT_EPSILON ? 0 : n/d;
    GLKVector3 offset = GLKVector3MultiplyScalar(lineDir, dist);
    GLKVector3 intersection = GLKVector3Add(lineStart, offset);
    
    // move origin from center to bottom left
    CGPoint hit = CGPointMake(intersection.x + size.x/2, intersection.y + size.y/2);

    return hit;
}

- (NSSet *)visibleTargets
{
    return [_visibleTargets copy];
}

- (NSArray *)sortedTouches
{
    return [_sortedTouches copy];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSArray *newSortedTouches = [[touches allObjects] sortedArrayUsingSelector:@selector(timestamp)];
    [_sortedTouches addObjectsFromArray:newSortedTouches];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [_sortedTouches removeObjectsInArray:[touches allObjects]];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [_sortedTouches removeObjectsInArray:[touches allObjects]];
}

- (void)focus
{
    if (_started) {
        Vuforia::CameraDevice::getInstance().setFocusMode(Vuforia::CameraDevice::FOCUS_MODE_TRIGGERAUTO);        
    }
}

@end
