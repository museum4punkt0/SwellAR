// Copyright © 2018 Refrakt <info@refrakt.org>
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause license found in the
// LICENSE file in the root directory of this source tree.

#import <Foundation/Foundation.h>
#import "VuforiaImageTarget.h"

NS_ASSUME_NONNULL_BEGIN

@interface VuforiaDataSet : NSObject

- (nullable instancetype)initWithXMLURL:(NSURL *)XMLURL error:(out NSError **)error;

@property (nonatomic, readonly) NSSet<VuforiaImageTarget *> *targets;
@property (nonatomic, readonly, getter=isActive) BOOL active;

@end

NS_ASSUME_NONNULL_END
