//
//  ArticleView.h
//  DreamingNews
//
//  Created by cg on 12-10-17.
//  Copyright (c) 2012年 Dreaming Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZStatus.h"
#import "GlobalDef.h"


@class ArticleView;

@protocol ArticleViewButtonClickedDelegate <NSObject>

- (void)imageButtonClick;
- (void)articleDetailButtonClick;

@end



@interface ArticleView : UIView <UITableViewDataSource,
UITableViewDelegate,
UIScrollViewDelegate> {
    
}

@property (nonatomic, assign) id<ArticleViewButtonClickedDelegate> delegate;

- (void)setArticleDatasource:(ZStatus *)article;

@end
