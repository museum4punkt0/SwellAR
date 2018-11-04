// Copyright © 2018 Refrakt <info@refrakt.org>
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause license found in the
// LICENSE file in the root directory of this source tree.

#import "VuforiaDataSet.h"
#import <Vuforia/DataSet.h>

NS_ASSUME_NONNULL_BEGIN

@interface VuforiaDataSet ()

@property (nonatomic, nonnull, readonly) Vuforia::DataSet *dataSet;

@end

NS_ASSUME_NONNULL_END
