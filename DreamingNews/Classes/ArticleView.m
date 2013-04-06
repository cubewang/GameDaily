//
//  ArticleView.m
//  DreamingNews
//
//  Created by cg on 12-10-17.
//  Copyright (c) 2012年 Dreaming Team. All rights reserved.
//

#import "ArticleView.h"
#import "UIImageView+WebCache.h"
#import "ZPhoto.h"
#import "ZPhotoSource.h"
#import "ZConversation.h"
#import "StreamingPlayer.h"
#import "DreamingAPI.h"
#import "AudioCommentCell.h"
#import "TextCommentCell.h"
#import "ZAppDelegate.h"


@interface ArticleView () {
    
    CGFloat top;
}

@property (nonatomic, retain) UIView *contentView;
@property (nonatomic, retain) UIImageView *coverImageView;
@property (nonatomic, retain) UIButton *coverButton;
@property (nonatomic, retain) UILabel *contentTextView;


@property (nonatomic, retain) StreamingPlayer *player;

@property (nonatomic, retain) ZStatus *article;

- (IBAction)imageButtonAction:(id)sender;

@end



@implementation ArticleView

@synthesize delegate;

@synthesize contentView;
@synthesize coverImageView;
@synthesize coverButton;
@synthesize contentTextView;

@synthesize player;

@synthesize article;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
                
        self.contentView = [[[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 20)] autorelease];
        self.contentView.backgroundColor = [UIColor blackColor];
        
        [self addSubview:contentView];
    }
    
    return self;
}

- (void)dealloc {
    
    self.delegate = nil;
    
    self.contentView = nil;
    self.coverImageView = nil;
    self.coverButton = nil;
    self.contentTextView = nil;
    
    self.player = nil;
    
    self.article = nil;
    
    [super dealloc];
}

- (void)setArticleDatasource:(ZStatus *)aArticle {

    top = 0;
    
    if ([[ZStatus getCoverImageUrl:aArticle] length] > 0) {
        
        self.coverImageView = [[[UIImageView alloc] init] autorelease];
        
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.coverImageView setClipsToBounds:YES];
        self.coverImageView.frame = CGRectMake(0,
                                               top,
                                               COVER_IMAGE_WIDTH,
                                               COVER_IMAGE_HEIGHT);
        
        [self.contentView addSubview:self.coverImageView];
        
        [self.coverImageView setImageWithURL:[NSURL URLWithString:[ZStatus getCoverImageUrl:aArticle]]
                            placeholderImage:[ArticleView getDefaultCoverImage]];
        
        self.coverButton = [[[UIButton alloc] init] autorelease];
        [self.coverButton addTarget:self action:@selector(imageButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        if ([[ZStatus getVideoUrl:aArticle] length] > 0) {
            
            if ([[UIDevice currentDevice] userInterfaceIdiom ] == UIUserInterfaceIdiomPhone) {
                [self.coverButton setImage:[UIImage imageNamed:@"video_button@2x.png"] forState:UIControlStateNormal];
            }
            else {
                [self.coverButton setImage:[UIImage imageNamed:@"video_button_iPad.png"] forState:UIControlStateNormal];
            }
        }
        
        self.coverButton.frame = CGRectMake(0,
                                            top + (COVER_IMAGE_HEIGHT - 200)/2,
                                            COVER_IMAGE_WIDTH,
                                            200);
        
        [self.contentView addSubview:self.coverButton];
        
        top += COVER_IMAGE_HEIGHT + kTableCellSmallMargin;
    }
    
    UIImageView *descriptionImageView = [[[UIImageView alloc] init] autorelease];
    
    descriptionImageView.frame = CGRectMake(0,
                                        top - kTableCellSmallMargin,
                                        SCREEN_WIDTH,
                                        300);
    
    [descriptionImageView setImage:[UIImage imageNamed:@"description_bg@2x"]];
    
    [self.contentView addSubview:descriptionImageView];
    
    self.contentTextView = [[[UILabel alloc] init] autorelease];
    
    [self.contentView addSubview:self.contentTextView];
    
    self.contentTextView.textColor = ZBSTYLE_tableSubTextColor;
    self.contentTextView.font = English_font_des;
    self.contentTextView.backgroundColor = [UIColor clearColor];
    self.contentTextView.textAlignment = UITextAlignmentLeft;
    self.contentTextView.contentMode = UIViewContentModeTop;
    self.contentTextView.lineBreakMode = UILineBreakModeTailTruncation;
    self.contentTextView.numberOfLines = 0;
    
    CGSize descriptionLabelSize = [aArticle.text sizeWithFont:English_font_des
                                            constrainedToSize:CGSizeMake(SCREEN_WIDTH - 4*kTableCellMargin, CGFLOAT_MAX)
                                                lineBreakMode:UILineBreakModeWordWrap];
    
    if (descriptionLabelSize.height > SCREEN_HEIGHT - 20 - top - 3*kTableCellMargin)
        descriptionLabelSize.height = SCREEN_HEIGHT - 20 - top - 3*kTableCellMargin;
    
    //设置高度
    self.contentTextView.frame = CGRectMake(2*kTableCellMargin,
                                            top + kTableCellMargin,
                                            SCREEN_WIDTH - 4*kTableCellMargin,
                                            descriptionLabelSize.height);
    
    self.contentTextView.text = aArticle.text;
    
    self.article = aArticle;
    
    UIButton *articleViewButton = [[[UIButton alloc] init] autorelease];
    [articleViewButton addTarget:self action:@selector(articleDetailButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    articleViewButton.frame = CGRectMake(0,
                                         top,
                                         SCREEN_WIDTH,
                                         SCREEN_HEIGHT - 20 - top);
    
    [self.contentView addSubview:articleViewButton];
    
    UIImageView *commentImageView = [[UIImageView alloc] init];
    
    commentImageView.frame = CGRectMake(SCREEN_WIDTH - 80,
                                        SCREEN_HEIGHT - 20 - 30,
                                        80,
                                        30);
    
    [self.contentView addSubview:commentImageView];
    
    [commentImageView setImage:[[UIImage imageNamed:@"comment_count_bg@2x"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0]];
    
    UILabel *commentCountLabel = [[UILabel alloc] init];
    commentCountLabel.font = English_font_small;
    commentCountLabel.textColor = CELLTEXT_COLOR;
    commentCountLabel.backgroundColor = [UIColor clearColor];
    commentCountLabel.textAlignment = UITextAlignmentCenter;
    commentCountLabel.contentMode = UIViewContentModeTop;
    commentCountLabel.lineBreakMode = UILineBreakModeTailTruncation;
    commentCountLabel.numberOfLines = 1;
    commentCountLabel.text = [NSString stringWithFormat:@"%d条评论", aArticle.commentsCount];
    
    commentCountLabel.frame = CGRectMake(SCREEN_WIDTH - 80,
                                         SCREEN_HEIGHT - 20 - 30,
                                         80,
                                         30);
    
    [self.contentView addSubview:commentCountLabel];
}

- (IBAction)articleDetailButtonAction:(id)sender {
    
    if ([delegate respondsToSelector:@selector(articleDetailButtonClick)]) {
        
        [delegate articleDetailButtonClick];
    }
}

- (IBAction)imageButtonAction:(id)sender {
    
    if ([delegate respondsToSelector:@selector(imageButtonClick)]) {
        
        [delegate imageButtonClick];
    }
}

static UIImage* defaultCoverImage = nil;

+ (UIImage*)getDefaultCoverImage {
    
    if (defaultCoverImage == nil) {
        defaultCoverImage = [[UIImage imageNamed:@"DefaultCover.png"] retain];
    }
    
    return defaultCoverImage;
}


@end
