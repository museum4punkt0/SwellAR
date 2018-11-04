// Copyright © 2018 Refrakt <info@refrakt.org>
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause license found in the
// LICENSE file in the root directory of this source tree.

#import "VuforiaImageTarget.h"
#import <Vuforia/ImageTarget.h>

NS_ASSUME_NONNULL_BEGIN

@interface VuforiaImageTarget ()

- (instancetype)initWithImageTarget:(Vuforia::ImageTarget *)imageTarget;

@property (nonatomic, readonly) Vuforia::ImageTarget *imageTarget;

@end

NS_ASSUME_NONNULL_END
