//
//  LevelManager.h
//  Cocos2DSimpleGame
//
//  Created by Ray Wenderlich on 11/14/12.
//  Copyright (c) 2012 Razeware LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Level.h"

@interface LevelManager : NSObject

+ (LevelManager *)sharedInstance;
- (Level *)curLevel;
- (void)nextLevel;
- (void)reset;

@end
