//
//  WWPlayer.h
//  WWPlayer
//
//  Created by etiantian on 2020/1/20.
//  Copyright © 2020 etiantian. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

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
@end

// MARK: player bar
@interface WWPlayerBar : UIView
@property (nonatomic, weak) id<WWPlayerBarDelegate>delegate;
@property (nonatomic, assign) float totalLoadedTime;
@property (nonatomic, assign) NSInteger totalDuration;
@property (nonatomic, assign) NSInteger currentTime;

@end




NS_ASSUME_NONNULL_END
