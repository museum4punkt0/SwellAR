//
//  VuforiaImageTarget_Internal.h
//  RefraktCore
//
//  Created by Michael Schröder on 27.08.16.
//  Copyright © 2016 Michael Schröder. All rights reserved.
//

#import "VuforiaImageTarget.h"
#import <Vuforia/ImageTarget.h>

NS_ASSUME_NONNULL_BEGIN

@interface VuforiaImageTarget ()

- (instancetype)initWithImageTarget:(Vuforia::ImageTarget *)imageTarget;

@property (nonatomic, readonly) Vuforia::ImageTarget *imageTarget;

@end

NS_ASSUME_NONNULL_END
