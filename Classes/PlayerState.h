#import <Foundation/Foundation.h>

@interface PlayerState : NSObject

@property (nonatomic, assign) int playerX;
@property (nonatomic, assign) int playerY;
@property (nonatomic, assign) int hp;
@property (nonatomic, assign) int hpMax;
@property (nonatomic, assign) int energy;
@property (nonatomic, assign) int energyMax;

@end
