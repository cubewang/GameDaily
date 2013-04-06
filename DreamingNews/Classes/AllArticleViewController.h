//
//  AllArticleViewController.h
//  DreamingNews
//
//  Created by cg on 12-10-9.
//  Copyright (c) 2012年 Dreaming Team. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MainViewController.h"
#import "BaseTableViewController.h"


#define kLastNewAppCheckDate  @"lastNewAppCheckDate"
#define kAdBarClosed          @"adBarClosed"


@interface AllArticleViewController : BaseTableViewController<RKObjectLoaderDelegate> {
    
}

@property (nonatomic, retain) id<ArticlesSwitchingDelegate> delegate;

- (IBAction)back:(id)sender;
- (IBAction)showSettingView:(id)sender;

@end
