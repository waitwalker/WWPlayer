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

@end

@protocol WWPlayerBarDelegate <NSObject>
@required
/**
 * @description play button tap call back
 * @author waitwalker
 * @date 2020.1.20
 * @parameter tap info
 */
- (void)dTappedPlayButton:(NSDictionary *)info;
@end

// MARK: player bar
@interface WWPlayerBar : UIView
@property (nonatomic, weak) id<WWPlayerBarDelegate>delegate;

@end




NS_ASSUME_NONNULL_END
