// Copyright © 2018 Refrakt <info@refrakt.org>
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause license found in the
// LICENSE file in the root directory of this source tree.

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
