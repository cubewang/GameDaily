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
#import "ArticleViewController_iPad.h"
#import "ZTextField.h"


@interface MainViewController_iPad : UIViewController
<UIScrollViewDelegate,
UIActionSheetDelegate,
MFMailComposeViewControllerDelegate,
ArticleViewButtonClickedDelegate,
ArticlesSwitchingDelegate,
RKObjectLoaderDelegate,
ZTextFieldDelegate,
AutoRefreshingDelegate> {
    
}

@end
