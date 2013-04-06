//
//  ArticleViewController_iPad.h
//  DreamingNews
//
//  Created by cg on 12-10-17.
//  Copyright (c) 2012年 Dreaming Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZStatus.h"
#import "GlobalDef.h"
#import "ArticleView.h"


@class ArticleViewController_iPad;


@protocol ArticleViewScrollToTopDelegate <NSObject>

- (void)scrollToTop;
- (void)scrollToComment;

@end

@interface ArticleViewController_iPad : UIViewController <RKObjectLoaderDelegate, 
UITableViewDataSource, UITableViewDelegate,
UIScrollViewDelegate, ArticleViewScrollToTopDelegate> {
    
}

@property (nonatomic, assign) id<ArticleViewButtonClickedDelegate> delegate;

- (void)setArticleDatasource:(ZStatus *)article;

@end
