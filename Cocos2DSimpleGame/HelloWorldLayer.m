//
//  HelloWorldLayer.m
//  Cocos2DSimpleGame
//
//  Created by Ray Wenderlich on 11/13/12.
//  Copyright Razeware LLC 2012. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"
#import "SimpleAudioEngine.h"
#import "GameOverLayer.h"
#import "Monster.h"
#import "LevelManager.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

#define arc4random random

#pragma mark - HelloWorldLayer

// HelloWorldLayer implementation
@implementation HelloWorldLayer

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
    // 'scene' is an autorelease object.
    CCScene *scene = [CCScene node];
    
    // 'layer' is an autorelease object.
    HelloWorldLayer *layer = [HelloWorldLayer node];
    
    // add layer as a child to scene
    [scene addChild: layer];
    
    // return the scene
    return scene;
}

- (void) addMonster {
    
    //CCSprite * monster = [CCSprite spriteWithFile:@"monster.png"];
    Monster * monster = nil;
    if (arc4random() % 2 == 0) {
        monster = [[[WeakAndFastMonster alloc] init] autorelease];
    } else {
        monster = [[[StrongAndSlowMonster alloc] init] autorelease];
    }
    
    // Determine where to spawn the monster along the Y axis
    CGSize winSize = [CCDirector sharedDirector].winSize;
    int minY = monster.contentSize.height / 2;
    int maxY = winSize.height - monster.contentSize.height/2;
    int rangeY = maxY - minY;
    int actualY = (arc4random() % rangeY) + minY;
    
    // Create the monster slightly off-screen along the right edge,
    // and along a random position along the Y axis as calculated above
    monster.position = ccp(winSize.width + monster.contentSize.width/2, actualY);
    [self addChild:monster];
    
    // Determine speed of the monster
    int minDuration = monster.minMoveDuration; //2.0;
    int maxDuration = monster.maxMoveDuration; //4.0;
    int rangeDuration = maxDuration - minDuration;
    int actualDuration = (arc4random() % rangeDuration) + minDuration;
    
    // Create the actions
    CCMoveTo * actionMove = [CCMoveTo actionWithDuration:actualDuration position:ccp(-monster.contentSize.width/2, actualY)];
    CCCallBlockN * actionMoveDone = [CCCallBlockN actionWithBlock:^(CCNode *node) {
        [_monsters removeObject:node];
        [node removeFromParentAndCleanup:YES];
        
        CCScene *gameOverScene = [GameOverLayer sceneWithWon:NO];
        [[CCDirector sharedDirector] replaceScene:gameOverScene];
    }];
    [monster runAction:[CCSequence actions:actionMove, actionMoveDone, nil]];
    
    monster.tag = 1;
    [_monsters addObject:monster];
    
}

-(void)gameLogic:(ccTime)dt {
    [self addMonster];
}
 
- (id) init
{
    if ((self = [super initWithColor:[LevelManager sharedInstance].curLevel.backgroundColor])) {

        CGSize winSize = [CCDirector sharedDirector].winSize;
        _player = [CCSprite spriteWithFile:@"player2.png"];
        _player.position = ccp(_player.contentSize.width/2, winSize.height/2);
        [self addChild:_player];
        
        [self schedule:@selector(gameLogic:) interval:[LevelManager sharedInstance].curLevel.secsPerSpawn];
        
        [self setTouchEnabled:YES];
        
        _monsters = [[NSMutableArray alloc] init];
        _projectiles = [[NSMutableArray alloc] init];

        [self schedule:@selector(update:)];
        
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"background-music-aac.caf"];
        
    }
    return self;
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (_nextProjectile != nil) return;
    
    // Choose one of the touches to work with
    UITouch *touch = [touches anyObject];
    CGPoint location = [self convertTouchToNodeSpace:touch];
    
    // Set up initial location of projectile
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    _nextProjectile = [[CCSprite spriteWithFile:@"projectile2.png"] retain];
    _nextProjectile.position = ccp(20, winSize.height/2);
    
    // Determine offset of location to projectile
    CGPoint offset = ccpSub(location, _nextProjectile.position);
    
    // Bail out if you are shooting down or backwards
    if (offset.x <= 0) return;
    
    // Determine where you wish to shoot the projectile to
    int realX = winSize.width + (_nextProjectile.contentSize.width/2);
    float ratio = (float) offset.y / (float) offset.x;
    int realY = (realX * ratio) + _nextProjectile.position.y;
    CGPoint realDest = ccp(realX, realY);
    
    // Determine the length of how far you're shooting
    int offRealX = realX - _nextProjectile.position.x;
    int offRealY = realY - _nextProjectile.position.y;
    float length = sqrtf((offRealX*offRealX)+(offRealY*offRealY));
    float velocity = 480/1; // 480pixels/1sec
    float realMoveDuration = length/velocity;
    
    // Determine angle to face
    float angleRadians = atanf((float)offRealY / (float)offRealX);
    float angleDegrees = CC_RADIANS_TO_DEGREES(angleRadians);
    float cocosAngle = -1 * angleDegrees;
    float rotateDegreesPerSecond = 180 / 0.5; // Would take 0.5 seconds to rotate 180 degrees, or half a circle
    float degreesDiff = _player.rotation - cocosAngle;
    float rotateDuration = fabs(degreesDiff / rotateDegreesPerSecond);
    [_player runAction:
     [CCSequence actions:
      [CCRotateTo actionWithDuration:rotateDuration angle:cocosAngle],
      [CCCallBlock actionWithBlock:^{
         // OK to add now - rotation is finished!
         [self addChild:_nextProjectile];
         [_projectiles addObject:_nextProjectile];
         
         // Release
         [_nextProjectile release];
         _nextProjectile = nil;
     }],
      nil]];
    
    // Move projectile to actual endpoint
    [_nextProjectile runAction:
     [CCSequence actions:
      [CCMoveTo actionWithDuration:realMoveDuration position:realDest],
      [CCCallBlockN actionWithBlock:^(CCNode *node) {
         [_projectiles removeObject:node];
         [node removeFromParentAndCleanup:YES];
    }],
      nil]];
    
    _nextProjectile.tag = 2;
    
    [[SimpleAudioEngine sharedEngine] playEffect:@"pew-pew-lei.caf"];
}

- (void)update:(ccTime)dt {
    
    NSMutableArray *projectilesToDelete = [[NSMutableArray alloc] init];
    for (CCSprite *projectile in _projectiles) {
        
        BOOL monsterHit = FALSE;
        NSMutableArray *monstersToDelete = [[NSMutableArray alloc] init];
        for (Monster *monster in _monsters) {
            
            if (CGRectIntersectsRect(projectile.boundingBox, monster.boundingBox)) {
                monsterHit = TRUE;
                monster.hp --;
                if (monster.hp <= 0) {
                    [monstersToDelete addObject:monster];
                }
                break;
            }
        }
        
        for (CCSprite *monster in monstersToDelete) {
            
            [_monsters removeObject:monster];
            [self removeChild:monster cleanup:YES];
            
            _monstersDestroyed++;
            if (_monstersDestroyed > 30) {
                CCScene *gameOverScene = [GameOverLayer sceneWithWon:YES];
                [[CCDirector sharedDirector] replaceScene:gameOverScene];
            }
        }
        
        if (monsterHit) {
            [projectilesToDelete addObject:projectile];
            [[SimpleAudioEngine sharedEngine] playEffect:@"explosion.caf"];
        }
        [monstersToDelete release];
    }
    
    for (CCSprite *projectile in projectilesToDelete) {
        [_projectiles removeObject:projectile];
        [self removeChild:projectile cleanup:YES];
    }
    [projectilesToDelete release];
}


// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
    [_monsters release];
    _monsters = nil;
    [_projectiles release];
    _projectiles = nil;
    [super dealloc];
}

#pragma mark GameKit delegate

-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
    AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
    [[app navController] dismissModalViewControllerAnimated:YES];
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
    AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
    [[app navController] dismissModalViewControllerAnimated:YES];
}
@end
