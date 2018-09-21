//
//  VuforiaImageTarget.h
//  RefraktCore
//
//  Created by Michael Schröder on 27.08.16.
//  Copyright © 2016 Michael Schröder. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VuforiaImageTarget : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) float width;
@property (nonatomic, readonly) float height;

@end

NS_ASSUME_NONNULL_END