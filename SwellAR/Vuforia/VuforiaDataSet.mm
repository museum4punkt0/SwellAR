// Copyright © 2018 Refrakt <info@refrakt.org>
// All rights reserved.
//
// This source code is licensed under the BSD 3-Clause license found in the
// LICENSE file in the root directory of this source tree.

#include "TargetConditionals.h"

#if !TARGET_IPHONE_SIMULATOR

#import "VuforiaDataSet.h"
#import "VuforiaDataSet_Internal.h"
#import "VuforiaImageTarget_Internal.h"
#import <Vuforia/ImageTarget.h>
#import <Vuforia/ObjectTracker.h>
#import <Vuforia/Trackable.h>
#import <Vuforia/TrackerManager.h>

@implementation VuforiaDataSet

- (nullable instancetype)initWithXMLURL:(NSURL *)XMLURL error:(out NSError *__autoreleasing *)error {
    self = [super init];
    if (self) {
        Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
        Vuforia::ObjectTracker *objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
        _dataSet = objectTracker->createDataSet();
        if (!_dataSet->load(XMLURL.path.UTF8String, Vuforia::STORAGE_ABSOLUTE)) {
            if (error != nil) {
                *error = [[NSError alloc] initWithDomain:@"RefraktCoreErrorDomain" code:3 userInfo:@{NSLocalizedDescriptionKey: @"Could not load Vuforia data set.", NSURLErrorKey: XMLURL}];
                objectTracker->destroyDataSet(_dataSet);
                return nil;
            }
        }
        NSMutableSet<VuforiaImageTarget *> *targets = [NSMutableSet set];
        int count = _dataSet->getNumTrackables();
        for (int i = 0; i < count; i++) {
            Vuforia::Trackable *trackable = _dataSet->getTrackable(i);
            if (trackable->getType().isOfType(Vuforia::ImageTarget::getClassType())) {
                VuforiaImageTarget *imageTarget = [[VuforiaImageTarget alloc] initWithImageTarget:(Vuforia::ImageTarget *)trackable];
                [targets addObject:imageTarget];
            } else {
                NSLog(@"%s: ignoring non-image target %s", __PRETTY_FUNCTION__, trackable->getName());
                continue;
            }
        }
        _targets = targets;
    }
    return self;
}

- (void)dealloc {
    Vuforia::TrackerManager& trackerManager = Vuforia::TrackerManager::getInstance();
    Vuforia::ObjectTracker *objectTracker = static_cast<Vuforia::ObjectTracker*>(trackerManager.getTracker(Vuforia::ObjectTracker::getClassType()));
    objectTracker->destroyDataSet(_dataSet);
}

- (BOOL)isActive {
    return _dataSet->isActive();
}

@end

#endif
