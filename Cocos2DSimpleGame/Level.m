//
//  Level.m
//  Cocos2DSimpleGame
//
//  Created by Ray Wenderlich on 11/14/12.
//  Copyright (c) 2012 Razeware LLC. All rights reserved.
//

#import "Level.h"

@implementation Level

- (id)initWithLevelNum:(int)levelNum secsPerSpawn:(float)secsPerSpawn backgroundColor:(ccColor4B)backgroundColor {
    if ((self = [super init])) {
        self.levelNum = levelNum;
        self.secsPerSpawn = secsPerSpawn;
        self.backgroundColor = backgroundColor;
    }
    return self;
}

@end
