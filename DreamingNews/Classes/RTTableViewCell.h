//
//  RTTableViewCell.h
//  Dreaming
//
//  Abstract: 富文本单元格样式
//
//  Created by Cube on 11-5-5.
//  Copyright 2011 Dreaming Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZStatus.h"
#import "StreamingPlayer.h"


#define COVER_IMAGE_HEIGHT ([[UIDevice currentDevice] userInterfaceIdiom ] == UIUserInterfaceIdiomPhone ? 58 : 58)

#define COVER_IMAGE_WIDTH ([[UIDevice currentDevice] userInterfaceIdiom ] == UIUserInterfaceIdiomPhone ? 82 : 82)

#define PLAYER_HEIGHT           40
#define PLAYER_WIDTH            320

#define AVATAR_WIDTH             32
#define AVATAR_HEIGHT      AVATAR_WIDTH


@interface RTTableViewCell : UITableViewCell 
{    
    UILabel *_descriptionLabel;
    
    UIImageView* _coverImageView;
    
    UIButton *_videoButton;
}

@property (nonatomic, readonly) UILabel *descriptionLabel;

@property (nonatomic, readonly) UIImageView *coverImageView;

@property (nonatomic, readonly) UIButton *videoButton;


- (void)setDataSource:(id)data;
- (void)setCoverImageUrl:(NSString *)url tagId:(NSInteger)tagId target:(id)target action:(SEL)selector;
- (void)setVideoUrl:(NSString *)url tagId:(NSInteger)tagId target:(id)target action:(SEL)selector;


+ (CGFloat)rowHeightForObject:(id)object;


+ (UIImage*)getDefaultCoverImage;

@end
