//
//  WWPlayer.h
//  WWPlayer
//
//  Created by etiantian on 2020/1/20.
//  Copyright © 2020 etiantian. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WWPlayerDelegate <NSObject>
@required
/**
* @description play error 
* @author waitwalker
* @date 2020.1.28
* @parameter
*/
- (void)playerDidError:(NSDictionary *)info;

@end

// MARK: player
@interface WWPlayer : UIView
/**
 * @description play
 * @author waitwalker
 * @date 2020.1.20
 * @parameter 
 */
- (void)play;

/**
* @description pause
* @author waitwalker
* @date 2020.1.20
* @parameter 
*/
- (void)pause;

@property (nonatomic, weak) id<WWPlayerDelegate>delegate;
@end




@protocol WWPlayerBarDelegate <NSObject>
@required
/**
 * @description play button tap call back
 * @author waitwalker
 * @date 2020.1.20
 * @parameter tap info
 */
- (void)dTappedPlayButton:(NSDictionary  * _Nullable)info;

@optional
/**
* @description drag began progress
* @author waitwalker
* @date 2020.1.25
* @parameter progress info
*/
- (void)dDragBeganProgress:(NSDictionary * _Nullable)info;

/**
* @description drag ended progress
* @author waitwalker
* @date 2020.1.25
* @parameter progress info
*/
- (void)dDragEndedProgress:(NSDictionary * _Nullable)info;

/**
 * @description full button tap call back
 * @author waitwalker
 * @date 2020.1.25
 * @parameter tap info
 */
- (void)dTappedFullButton:(NSDictionary  * _Nullable)info;
@end

// MARK: player bar
@interface WWPlayerBar : UIView
@property (nonatomic, weak) id<WWPlayerBarDelegate>delegate;
@property (nonatomic, assign) float totalLoadedTime;
@property (nonatomic, assign) NSInteger totalDuration;
@property (nonatomic, assign) NSInteger currentTime;

/**
* @description enter full screen
* @author waitwalker
* @date 2020.1.27
* @parameter
*/
- (void)enterFullScreen;

/**
* @description exit full screen
* @author waitwalker
* @date 2020.1.27
* @parameter
*/
- (void)exitFullScreen;

/**
* @description seek to begin
* @author waitwalker
* @date 2020.1.27
* @parameter
*/
- (void)seekToBegin;

/**
 * @description play
 * @author waitwalker
 * @date 2020.1.27
 * @parameter
 */
- (void)play;
@end

// MARK: UIView Category
@interface UIView (Category)
@property (nonatomic, assign) CGFloat frameX;
@property (nonatomic, assign) CGFloat frameY;
@property (nonatomic, assign) CGFloat frameWidth;
@property (nonatomic, assign) CGFloat frameHeight;
@property (nonatomic, assign) CGPoint frameOrigin;
@property (nonatomic, assign) CGSize  frameSize;
@property (nonatomic, assign) CGFloat boundsX;
@property (nonatomic, assign) CGFloat boundsY;
@property (nonatomic, assign) CGFloat boundsWidth;
@property (nonatomic, assign) CGFloat boundsHeight;
@property (nonatomic, assign) CGFloat centerX;
@property (nonatomic, assign) CGFloat centerY;
@end




NS_ASSUME_NONNULL_END
