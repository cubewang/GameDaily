/*
 *  GlobalDef.h
 *  Dreaming
 *
 *  Created by Cube on 11-7-12.
 *  Copyright 2011 Dreaming Team. All rights reserved.
 *
 */

//当前设备的屏幕宽度
#define SCREEN_WIDTH   [[UIScreen mainScreen] bounds].size.width

//当前设备的屏幕高度
#define SCREEN_HEIGHT   [[UIScreen mainScreen] bounds].size.height

//当前设备的屏幕高度
#define IS_IPHONE_5   ([[UIScreen mainScreen] bounds].size.height == 568)


//音频播放器大小
#define PLAYER_HEIGHT           40
#define PLAYER_WIDTH            320


#define COVER_IMAGE_HEIGHT      ([[UIDevice currentDevice] userInterfaceIdiom ] == UIUserInterfaceIdiomPhone ? 280 : 450)
#define COVER_IMAGE_WIDTH       SCREEN_WIDTH


//广告条高度
#define AD_BAR_HEIGHT       50


//默认背景颜色
#define CELL_BACKGROUND  [UIColor blackColor]

#define SELECTED_BACKGROUND [UIColor colorWithRed:35.0/255.0 green:35.0/255.0 blue:35.0/255.0 alpha:1.0]

//官方回复颜色
#define OFFICIAL_COLOR [UIColor colorWithRed:255.0/255.0 green:155.0/255.0 blue:57.0/255.0 alpha:1.0]
#define REPLY_TO_BACKGROUND [UIColor colorWithRed:220.0/255.0 green:220.0/255.0 blue:220.0/255.0 alpha:1.0]

#define NAV_BAR_ITEM_COLOR [UIColor grayColor]

//正文字体颜色
#define CELLTEXT_COLOR [UIColor colorWithRed:175.0/255.0 green:196.0/255.0 blue:193.0/255.0 alpha:1.0]

//STYLE
#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]


#define ZBSTYLE_tableSubTextColor CELLTEXT_COLOR
#define ZBSTYLE_textColor CELLTEXT_COLOR


#define English_font_des ([[UIDevice currentDevice] userInterfaceIdiom ] == UIUserInterfaceIdiomPhone ? \
[UIFont fontWithName:@"Georgia" size:15] : [UIFont fontWithName:@"Georgia" size:17])

#define English_font_title ([[UIDevice currentDevice] userInterfaceIdiom ] == UIUserInterfaceIdiomPhone ? \
[UIFont fontWithName:@"Georgia" size:17] : [UIFont fontWithName:@"Georgia" size:19])

#define English_font_body ([[UIDevice currentDevice] userInterfaceIdiom ] == UIUserInterfaceIdiomPhone ? \
[UIFont fontWithName:@"Helvetica Neue" size:15] : [UIFont fontWithName:@"Helvetica Neue" size:17])

#define English_font_small ([[UIDevice currentDevice] userInterfaceIdiom ] == UIUserInterfaceIdiomPhone ? \
[UIFont systemFontOfSize:14] : [UIFont systemFontOfSize:15])

#define English_font_smallest ([[UIDevice currentDevice] userInterfaceIdiom ] == UIUserInterfaceIdiomPhone ? \
[UIFont systemFontOfSize:11] : [UIFont systemFontOfSize:12])

#define kTableCellSmallMargin   6.0f
#define kTableCellMargin        10.0f


//字符串
#define SAFE_STRING(str) ([(str) length] ? (str) : @"")
#define RELEASE_SAFELY(__POINTER) { [__POINTER release]; __POINTER = nil; }

#define ENABLE_SDWEBIMAGE_DECODER


#define DOCUMENT_FOLDER	   [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]
#define AUDIO_CACHE_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/AudioCache"]

