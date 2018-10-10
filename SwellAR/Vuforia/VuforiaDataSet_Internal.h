//
//  VuforiaDataSet_Internal.h
//  RefraktCore
//
//  Created by Michael Schröder on 27.08.16.
//  Copyright © 2016 Michael Schröder. All rights reserved.
//

#import "VuforiaDataSet.h"
#import <Vuforia/DataSet.h>

NS_ASSUME_NONNULL_BEGIN

@interface VuforiaDataSet ()

@property (nonatomic, nonnull, readonly) Vuforia::DataSet *dataSet;

@end

NS_ASSUME_NONNULL_END
