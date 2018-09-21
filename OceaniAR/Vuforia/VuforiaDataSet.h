//
//  VuforiaDataSet.h
//  RefraktCore
//
//  Created by Michael Schröder on 27.08.16.
//  Copyright © 2016 Michael Schröder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VuforiaImageTarget.h"

NS_ASSUME_NONNULL_BEGIN

@interface VuforiaDataSet : NSObject

- (nullable instancetype)initWithXMLURL:(NSURL *)XMLURL error:(out NSError **)error;

@property (nonatomic, readonly) NSSet<VuforiaImageTarget *> *targets;
@property (nonatomic, readonly, getter=isActive) BOOL active;

@end

NS_ASSUME_NONNULL_END