//
//  VuforiaImageTarget.m
//  RefraktCore
//
//  Created by Michael Schröder on 27.08.16.
//  Copyright © 2016 Michael Schröder. All rights reserved.
//

#import "VuforiaImageTarget.h"
#import "VuforiaImageTarget_Internal.h"

@implementation VuforiaImageTarget

- (instancetype)initWithImageTarget:(Vuforia::ImageTarget *)imageTarget {
    self = [super init];
    if (self) {
        _imageTarget = imageTarget;
    }
    return self;
}

- (NSString *)name {
    return @(_imageTarget->getName());
}

- (float)width {
    Vuforia::Vec3F size = _imageTarget->getSize();
    return size.data[0];
}

- (float)height {
    Vuforia::Vec3F size = _imageTarget->getSize();
    return size.data[1];
}

@end