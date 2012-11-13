//
//  Level.h
//  Cocos2DSimpleGame
//
//  Created by Ray Wenderlich on 11/14/12.
//  Copyright (c) 2012 Razeware LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface Level : NSObject

@property (nonatomic, assign) int levelNum;
@property (nonatomic, assign) float secsPerSpawn;
@property (nonatomic, assign) ccColor4B backgroundColor;

- (id)initWithLevelNum:(int)levelNum secsPerSpawn:(float)secsPerSpawn backgroundColor:(ccColor4B)backgroundColor;

@end
