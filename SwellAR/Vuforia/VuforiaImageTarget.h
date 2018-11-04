// Copyright © 2018 Refrakt <info@refrakt.org>
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause license found in the
// LICENSE file in the root directory of this source tree.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VuforiaImageTarget : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) float width;
@property (nonatomic, readonly) float height;

@end

NS_ASSUME_NONNULL_END
