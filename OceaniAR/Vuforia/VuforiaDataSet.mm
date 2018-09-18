//
//  VuforiaDataSet.m
//  RefraktCore
//
//  Created by Michael Schröder on 27.08.16.
//  Copyright © 2016 Michael Schröder. All rights reserved.
//

#import "VuforiaDataSet.h"
#import "VuforiaDataSet_Internal.h"
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
