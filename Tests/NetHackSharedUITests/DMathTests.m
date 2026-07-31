#import <XCTest/XCTest.h>
#import <NetHackSharedUI/DMath.h>

@interface DMathTests : XCTestCase
@end

@implementation DMathTests

- (void)testNormalizedPointScalesToUnitLength {
    CGPoint p = [DMath normalizedPoint:CGPointMake(3, 4)];
    XCTAssertEqualWithAccuracy(sqrt(p.x * p.x + p.y * p.y), 1.0, 0.0001);
    XCTAssertEqualWithAccuracy(p.x, 0.6, 0.0001);
    XCTAssertEqualWithAccuracy(p.y, 0.8, 0.0001);
}

- (void)testDirectionFromVectorRecognizesCardinalDirections {
    DMath *dmath = [[DMath alloc] init];

    XCTAssertEqual([dmath directionFromVector:CGPointMake(0, 1)], kUp);
    XCTAssertEqual([dmath directionFromVector:CGPointMake(1, 0)], kRight);
    XCTAssertEqual([dmath directionFromVector:CGPointMake(0, -1)], kDown);
    XCTAssertEqual([dmath directionFromVector:CGPointMake(-1, 0)], kLeft);
}

- (void)testDirectionFromVectorRecognizesDiagonalDirections {
    DMath *dmath = [[DMath alloc] init];

    CGPoint upRight = [DMath normalizedPoint:CGPointMake(1, 1)];
    CGPoint downLeft = [DMath normalizedPoint:CGPointMake(-1, -1)];

    XCTAssertEqual([dmath directionFromVector:upRight], kUpRight);
    XCTAssertEqual([dmath directionFromVector:downLeft], kDownLeft);
}

@end
