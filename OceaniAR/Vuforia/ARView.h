//
//  ARView.h
//  Phantomat
//
//  Created by Michael Schröder on 10.08.14.
//  Copyright (c) 2014 Michael Schröder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "VuforiaDataSet.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ARViewVideoGravity) {
    ARViewVideoGravityResize,
    ARViewVideoGravityResizeAspect,
    ARViewVideoGravityResizeAspectFill
};

typedef NS_ENUM(NSUInteger, ARViewVideoOrientation) {
    ARViewVideoOrientationPortrait,
    ARViewVideoOrientationPortraitUpsideDown,
    ARViewVideoOrientationLandscapeLeft,
    ARViewVideoOrientationLandscapeRight
};

@class ARView;
@protocol ARViewDelegate <NSObject>

/// This is guaranteed to be called after the target has appeared but before `arView:renderTarget:withModelviewMatrix:atDistance:` is called. It is only called once for every appearance of a target.
- (void)arView:(ARView *)arView targetDidAppear:(NSString *)name atDate:(NSDate *)date;

- (void)arView:(ARView *)arView renderTarget:(NSString *)name withModelviewMatrix:(GLKMatrix4)matrix atDistance:(GLfloat)distance date:(NSDate *)date;

/// This is guaranteed to be called after the target has disappeared and the last call to `arView:renderTarget:withModelviewMatrix:atDistance:` was made. It is only called once for every appearance of a target.
- (void)arView:(ARView *)arView targetDidDisappear:(NSString *)name atDate:(NSDate *)date;

@end

typedef NS_ENUM(NSUInteger, ARViewInitializationResult) {
    ARViewInitializationOK,
    ARViewInitializationNetworkUnavailable,
    ARViewInitializationServerUnavailable,
    ARViewInitializationFail,
};

@interface ARView : UIView

+ (nonnull NSString *)vuforiaVersion;

+ (void)initializeVuforiaWithLicenseKey:(NSString *)key completionHandler:(void (^)(ARViewInitializationResult result, int errorCode))completionHandler;
+ (BOOL)isVuforiaInitialized;

/// The default value is ARViewVideoGravityResizeAspectFill.
@property (nonatomic) ARViewVideoGravity videoGravity;

@property (nonatomic) ARViewVideoOrientation videoOrientation;

@property (nonatomic, readonly) CGSize physicalViewSize;

- (void)start;
- (void)stop;
@property (nonatomic, readonly, getter=isStarted) BOOL started;

- (void)activateDataSet:(VuforiaDataSet *)dataSet;
- (void)deactivateDataSet:(VuforiaDataSet *)dataSet;
@property (nonatomic, readonly) NSSet<VuforiaDataSet *> *activeDataSets;

@property (nonatomic, readonly) NSSet<NSString *> *visibleTargets;

- (CGPoint)convertPoint:(CGPoint)point toModelviewMatrix:(GLKMatrix4)modelviewMatrix size:(GLKVector2)size;

@property (nonatomic, readonly) NSArray *sortedTouches;

@property (nonatomic, readonly) GLuint framebuffer;
@property (nonatomic, readonly) CGRect viewport;
@property (nonatomic, readonly) GLKMatrix4 projectionMatrix;
@property (nonatomic, readonly) float ambientColorTemperature;  // default: 6500 Kelvin
@property (nonatomic, readonly) float ambientIntensity;         // default: 1000 lumens

@property (nonatomic, weak, nullable) id<ARViewDelegate> delegate;

@property (nonatomic, readonly) EAGLContext *context;
@property (nonatomic, getter=isRenderingPaused) BOOL renderingPaused;

- (void)focus;

@end

NS_ASSUME_NONNULL_END
