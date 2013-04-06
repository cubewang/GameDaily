//
//  ViewController.h
//  DreamingNews
//
//  Created by cg on 12-9-28.
//  Copyright (c) 2012年 Dreaming Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>
#import <MessageUI/MessageUI.h>
#import "ArticleView.h"


@protocol ArticlesSwitchingDelegate <NSObject>

- (void)showArticles:(NSMutableArray *)articleArray articleIndex:(NSInteger)index;

@end

@protocol AutoRefreshingDelegate <NSObject>

- (void)loadArticlesNow:(BOOL)useCache;

@end


@interface MainViewController : UIViewController 
<UIScrollViewDelegate,
UIActionSheetDelegate,
MFMailComposeViewControllerDelegate,
ArticleViewButtonClickedDelegate,
ArticlesSwitchingDelegate,
RKObjectLoaderDelegate,
AutoRefreshingDelegate> {
    
}


@end
