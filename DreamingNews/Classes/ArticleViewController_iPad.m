//
//  ArticleView.m
//  DreamingNews
//
//  Created by cg on 12-10-17.
//  Copyright (c) 2012年 Dreaming Team. All rights reserved.
//

#import "ArticleViewController_iPad.h"
#import "UIImageView+WebCache.h"
#import "ZPhoto.h"
#import "ZPhotoSource.h"
#import "ZConversation.h"
#import "StreamingPlayer.h"
#import "DreamingAPI.h"
#import "AudioCommentCell.h"
#import "TextCommentCell.h"
#import "ZAppDelegate.h"
#import "UserAccount.h"
#import "UserLoginViewController_iPad.h"


@interface ArticleViewController_iPad () {
    
    CGFloat top;
    CGPoint articleContentSize;
    
    int commentCountBeforeLoading; //分段请求前的评论数，用于记录是否请求完所有评论
}

@property (nonatomic, retain) UIScrollView *contentScrollView;
@property (nonatomic, retain) UIImageView *coverImageView;
@property (nonatomic, retain) UIButton *coverButton;
@property (nonatomic, retain) UITextView *contentTextView;
@property (nonatomic, retain) UITableView  *commentTableView;


@property (nonatomic, retain) ZStatus *operatingComment;

@property (nonatomic, retain) StreamingPlayer *player;

@property (nonatomic, retain) ZStatus *article;
@property (nonatomic, retain) ZConversation *conversation;

@property (nonatomic, retain) NSMutableArray *commentListCached;

- (IBAction)imageButtonAction:(id)sender;

@end



@implementation ArticleViewController_iPad

@synthesize delegate;

@synthesize contentScrollView;
@synthesize coverImageView;
@synthesize coverButton;
@synthesize contentTextView;
@synthesize commentTableView;

@synthesize operatingComment;

@synthesize player;

@synthesize article;
@synthesize conversation;

@synthesize commentListCached;

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)dealloc {
    
    [[RKClient sharedClient].requestQueue cancelRequestsWithDelegate:self];
    
    self.delegate = nil;
    
    self.contentScrollView = nil;
    self.coverImageView = nil;
    self.coverButton = nil;
    self.contentTextView = nil;
    self.commentTableView = nil;
    
    self.player = nil;
    
    self.operatingComment = nil;
    self.commentListCached = nil;
    
    self.article = nil;
    self.conversation = nil;
    
    [super dealloc];
}

- (void)setArticleDatasource:(ZStatus *)aArticle {

    self.contentScrollView = [[[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 20 - 48)] autorelease];
    self.contentScrollView.backgroundColor = CELL_BACKGROUND;
    self.contentScrollView.delegate = self;
    self.contentScrollView.scrollsToTop = YES;
    self.contentScrollView.alwaysBounceHorizontal = NO;
    
    [self.view addSubview:contentScrollView];
    
    top = 0;
    
    if ([[ZStatus getCoverImageUrl:aArticle] length] > 0) {
        
        self.coverImageView = [[[UIImageView alloc] init] autorelease];
        
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.coverImageView setClipsToBounds:YES];
        self.coverImageView.frame = CGRectMake(0,
                                               top,
                                               COVER_IMAGE_WIDTH,
                                               COVER_IMAGE_HEIGHT);
        
        [self.contentScrollView addSubview:self.coverImageView];
        
        [self.coverImageView setImageWithURL:[NSURL URLWithString:[ZStatus getCoverImageUrl:aArticle]] 
                            placeholderImage:[ArticleViewController_iPad getDefaultCoverImage]];
        
        self.coverButton = [[[UIButton alloc] init] autorelease];
        [self.coverButton addTarget:self action:@selector(imageButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        if ([[ZStatus getVideoUrl:article] length] > 0) {
            
            if ([[UIDevice currentDevice] userInterfaceIdiom ] == UIUserInterfaceIdiomPhone) {
                [self.coverButton setImage:[UIImage imageNamed:@"video_button@2x.png"] forState:UIControlStateNormal];
            }
            else {
                [self.coverButton setImage:[UIImage imageNamed:@"video_button_iPad.png"] forState:UIControlStateNormal];
            }
        }
        
        self.coverButton.frame = CGRectMake(0,
                                            top,
                                            COVER_IMAGE_WIDTH,
                                            COVER_IMAGE_HEIGHT);
        
        [self.contentScrollView addSubview:self.coverButton];
        
        top += COVER_IMAGE_HEIGHT + kTableCellSmallMargin;
    }
    
    if ([[ZStatus getAudioUrl:aArticle] length] > 0) {
        
        self.player = [[[StreamingPlayer alloc] initWithFrame:CGRectMake(0, 20, PLAYER_HEIGHT, PLAYER_WIDTH)] autorelease];
        
        [self.contentScrollView addSubview:self.player];
        
        self.player.frame = CGRectMake((SCREEN_WIDTH - PLAYER_WIDTH)/2,
                                       top,
                                       PLAYER_WIDTH,
                                       PLAYER_HEIGHT);
        
        top += PLAYER_HEIGHT + kTableCellSmallMargin;
        
        [self.player setAudioUrl:[ZStatus getAudioUrl:aArticle]];
    }
    
    self.contentTextView = [[[UITextView alloc] init] autorelease];
    
    [self.contentScrollView addSubview:self.contentTextView];
    
    self.contentTextView.textColor = ZBSTYLE_tableSubTextColor;
    self.contentTextView.font = English_font_des;
    self.contentTextView.backgroundColor = [UIColor clearColor];
    self.contentTextView.editable = NO;
    
    //计算articleView高度
    self.contentTextView.frame = CGRectMake(kTableCellSmallMargin,
                                            top,
                                            SCREEN_WIDTH - 2*kTableCellSmallMargin,
                                            SCREEN_HEIGHT);
    
    self.contentTextView.text = aArticle.text;
    
    //设置高度
    self.contentTextView.frame = CGRectMake(kTableCellSmallMargin,
                                            top,
                                            SCREEN_WIDTH - 2*kTableCellSmallMargin,
                                            self.contentTextView.contentSize.height);
    
    self.contentScrollView.contentSize = CGSizeMake(SCREEN_WIDTH, top + self.contentTextView.frame.size.height + 2*kTableCellSmallMargin);
    
    UIImageView *articleBackground = [[[UIImageView alloc]initWithFrame:
                                       CGRectMake(0, self.contentScrollView.contentSize.height, 320, 30)] autorelease];
    [articleBackground setImage:[UIImage imageNamed:@"comment_title_newest@2x"]];
    
    [self.contentScrollView addSubview:articleBackground];
    
    CGSize articleBackgroundSize = articleBackground.frame.size;
    
    self.contentScrollView.contentSize = 
    CGSizeMake(SCREEN_WIDTH, self.contentScrollView.contentSize.height + kTableCellSmallMargin + articleBackgroundSize.height + 10);
    
    articleContentSize.y = self.contentScrollView.contentSize.height;
    
    self.article = aArticle;
    
    [DreamingAPI getConversation:[NSString stringWithFormat:@"%d", aArticle.conversationID]
                             page:0
                           length:10
                         delegate:self
                    useCacheFirst:NO]; 
}

- (void)initCommentTableView:(ZConversation*)aConversation
{
    if ([aConversation.statusList count] == 0)
        return;
    
    CGFloat tableHeight = [self tableHeightForObject:conversation];
    
    CGSize size = self.contentScrollView.contentSize;
    
    if (self.commentTableView != nil) {
        
        size.height -= self.commentTableView.frame.size.height;
        [self.commentTableView removeFromSuperview];
    }
    
    CGRect rc = CGRectMake(0, kTableCellSmallMargin + size.height, SCREEN_WIDTH, tableHeight);
    
    self.commentTableView = [[[UITableView alloc] initWithFrame:rc 
                                                          style:UITableViewStylePlain] autorelease];
    self.commentTableView.dataSource = self;
    self.commentTableView.delegate = self;
    self.commentTableView.scrollEnabled = NO;
    self.commentTableView.backgroundColor = [UIColor clearColor];
    
    [self.contentScrollView addSubview:self.commentTableView];
    
    size.height += (tableHeight + kTableCellMargin);
    
    self.contentScrollView.contentSize = size;
}

- (void)resizeCommentTableView:(ZConversation*)theConversation
{
    CGFloat tableHeight = [self tableHeightForObject:theConversation];
    
    CGSize size = self.contentScrollView.contentSize;
    size.height -= (self.commentTableView.frame.size.height + kTableCellMargin);
    
    CGRect rc = CGRectMake(0, kTableCellSmallMargin + size.height, SCREEN_WIDTH, tableHeight);
    
    self.commentTableView.frame = rc;
    
    size.height += tableHeight + kTableCellMargin;
    
    self.contentScrollView.contentSize = size;
    
    [self.commentTableView reloadData];
}
#pragma mark -
#pragma mark Comment Cell Action

- (IBAction)commentCellButtonAction:(UIButton *)sender {
    
    if ([UserAccount getUserName] == nil) {
        
        UserLoginViewController_iPad *userLoginVC = [[[UserLoginViewController_iPad alloc] init]autorelease];
        userLoginVC.delegate = nil;
        [self presentModalViewController:userLoginVC animated:YES];
        
        return;
    }
    
    UIButton *clickedButton = (UIButton*)sender;
    
    self.operatingComment = [self.conversation.statusList count] > clickedButton.tag ? [self.conversation.statusList objectAtIndex:clickedButton.tag] : nil;
    
    if (self.operatingComment == nil)
        return;
    
    if ([[UserAccount getUserId] isEqualToString:[NSString stringWithFormat:@"%d",self.operatingComment.user.userID]]) {
        
        [self deleteComment];
    }
    else {
        
        UILabel *label = nil;
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:clickedButton.tag inSection:0];
        id cell = [self.commentTableView cellForRowAtIndexPath:indexPath];
        
        if ([cell isKindOfClass:[AudioCommentCell class]])
        {
            AudioCommentCell *audioCommentCell = (AudioCommentCell *)cell;
            label = audioCommentCell.favoriteCountLabel;
        }
        else if ([cell isKindOfClass:[TextCommentCell class]]) {
            TextCommentCell *textCommentCell = (TextCommentCell *)cell;
            label = textCommentCell.favoriteCountLabel;
        }
        
        [self commentCellFavoriteButtonClicked:clickedButton label:label];
    }
}

- (void)commentCellFavoriteButtonClicked:(UIButton *)sender label:(UILabel *)label {
    
}

- (void)deleteComment
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"你要删除评论吗？", @"")
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"取消", @"") 
                                               destructiveButtonTitle:NSLocalizedString(@"确认删除", @"") 
                                                    otherButtonTitles:nil];
    [actionSheet showInView:self.view];
    [actionSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([[UserAccount getUserId] isEqualToString:[NSString stringWithFormat:@"%d",self.operatingComment.user.userID]]) {
        
        if (buttonIndex == 0) 
        {
            NSString *statusId = [NSString stringWithFormat:@"%d",self.operatingComment.statusID];
            [DreamingAPI deleteStatus:statusId delegate:self];
        }
    }
}

- (void)resetCommentList
{
    if (self.commentListCached)
    {
        [self.commentListCached removeAllObjects];
        commentCountBeforeLoading = 0;
    }
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    // Return the number of rows in the section.
    return self.conversation.statusList.count == 0 ? 0 : self.conversation.statusList.count + 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == [self.conversation.statusList count]) {
        
        UITableViewCell *cell = [[[UITableViewCell alloc] 
                                  initWithStyle:UITableViewCellStyleDefault 
                                  reuseIdentifier:nil] autorelease];
        
        cell.textLabel.text = NSLocalizedString(@"显示更多", @"");
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:16];
        cell.textLabel.highlightedTextColor = CELLTEXT_COLOR;
        
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activityView.frame = CGRectMake(95.0f, 18.0f, 25.0f, 25.0f);
        activityView.hidesWhenStopped = YES;
        activityView.tag = 200;
        [cell addSubview:activityView];
        [activityView release];
        
        // set selection color 
        UIView *backgroundView = [[UIView alloc] initWithFrame:cell.frame]; 
        backgroundView.backgroundColor = SELECTED_BACKGROUND;
        cell.selectedBackgroundView = backgroundView; 
        [backgroundView release];
        
        return cell;
    }
    
    // Configure the cell.
    ZStatus *comment = [self.conversation.statusList count] == 0 ? nil : [self.conversation.statusList objectAtIndex:indexPath.row];
    
    if ([self isAudioComment:comment]) 
    {
        AudioCommentCell *commentCell = [tableView dequeueReusableCellWithIdentifier:@"AudioCommentCell"];
        
        if (commentCell == nil) {
            NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:@"AudioCommentCell" owner:nil options:nil];
            
            for (id item in nibs) {
                if ([item isKindOfClass:[UITableViewCell class]]) {
                    commentCell = item;
                    break;
                }
            }
        }
        
        [commentCell setSelectionStyle:UITableViewCellEditingStyleNone];
        [commentCell setDataSource:comment];
        [commentCell setCommentDelegate:indexPath.row
                                 target:self
                                 action:@selector(commentCellButtonAction:)];
        
        return commentCell;
    }
    else
    {
        TextCommentCell *commentCell = [tableView dequeueReusableCellWithIdentifier:@"TextCommentCell"];
        
        if (commentCell == nil) {
            NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:@"TextCommentCell" owner:nil options:nil];
            
            for (id item in nibs) {
                if ([item isKindOfClass:[UITableViewCell class]]) {
                    commentCell = item;
                    break;
                }
            }
        }
        
        [commentCell setSelectionStyle:UITableViewCellEditingStyleNone];
        [commentCell setDataSource:comment];
        [commentCell setCommentDelegate:indexPath.row 
                                 target:self 
                                 action:@selector(commentCellButtonAction:)];
        
        return commentCell;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([self.conversation.statusList count] == 0) {
        return 0;
    }
    
    if (indexPath.row >= [self.conversation.statusList count])
        return 60;
    
    ZStatus *comment = [self.conversation.statusList objectAtIndex:indexPath.row];
    
    return [self isAudioComment:comment] ?
    [AudioCommentCell heightForCell:comment replyToStatus:nil] :
    [TextCommentCell heightForCell:comment];
}


- (CGFloat)tableHeightForObject:(ZConversation*)aConversation {
    
    CGFloat tableHeight = 0.0;
    
    for (ZStatus *status in aConversation.statusList)
    {
        if (status.statusID == aConversation.originalStatus.statusID)
            continue;
        
        tableHeight += ([self isAudioComment:status] ?
                        [AudioCommentCell heightForCell:status replyToStatus:nil] :
                        [TextCommentCell heightForCell:status]);
    }
    
    return tableHeight > 0.0 ? tableHeight + 60 : 0.0;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Deselect
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == [self.conversation.statusList count])
    {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if (cell) {
            
            [(UIActivityIndicatorView *)[cell viewWithTag:200] startAnimating];
            cell.textLabel.text = NSLocalizedString(@"加载中...", @"");
        }
        
        NSInteger page = [self.conversation.statusList count] / 20 + 1;
        
        [DreamingAPI getConversation:[NSString stringWithFormat:@"%d", self.article.conversationID]
                             page:page
                           length:20
                         delegate:self
                    useCacheFirst:NO];
        
        commentCountBeforeLoading = [self.conversation.statusList count];
        
        return;
    }
}

- (BOOL)isAudioComment:(ZStatus *)status {
    return [[ZStatus getAudioUrl:status] length] > 0;
}



#pragma mark RKObjectLoaderDelegate methods

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {

    NSString *string = [response.URL absoluteString];
    
    if ([string hasPrefix:[NSString stringWithFormat:@"%@%@", MAIN_PATH, STATUS_DELETE]]) {
        
        NSString* bodyString = [[[NSString alloc] initWithData:response.body encoding:NSUTF8StringEncoding] autorelease];
        
        NSString *resultString = NSLocalizedString(@"评论删除成功", @"");
        
        if ([bodyString rangeOfString:@"error"].length > 0) {
            
            resultString = NSLocalizedString(@"评论删除失败", @"");
        }
        else {
            [self scrollToComment];
        }
        
        [[ZAppDelegate sharedAppDelegate] showInformation:self.view info:resultString];
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(id)object {
    
    NSString *string = [objectLoader.URL absoluteString];
    
    if ([string hasPrefix:[NSString stringWithFormat:@"%@/statusnet/conversation", MAIN_PATH]])
    {
        ZConversation *lastConversation = (ZConversation *)object;
        
        if (self.commentListCached == nil) {
            self.commentListCached = [[[NSMutableArray alloc] init] autorelease];
        }
        
        for (ZStatus *status in lastConversation.statusList) {
            
            BOOL alreadyExist = NO;
            for (ZStatus *statusInCache in self.commentListCached)
            {
                if (statusInCache.statusID == status.statusID)
                    alreadyExist = YES;
            }
            
            if (status.statusID == self.article.statusID) {
                
                [lastConversation.statusList removeObject:status];
                
                continue;
            }
                    
            if (!alreadyExist)
                [self.commentListCached addObject:status];
        }
        
        if ([self.conversation.statusList count] == 0) {
            self.conversation = lastConversation;
            
            [self initCommentTableView:self.conversation];
        }
        else {

            self.conversation.statusList = [[self.commentListCached copy] autorelease];
            
            [self resizeCommentTableView:self.conversation];
            
            //如果评论列表没有增长，说明已经请求完所有服务器的文章
            if (commentCountBeforeLoading == [self.commentListCached count] 
                && commentCountBeforeLoading == [self.conversation.statusList count]) 
            {
                [[ZAppDelegate sharedAppDelegate] showInformation:self.view info:NSLocalizedString(@"沒有更多评论了", @"")];
            }
        }
    }
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    
}


#pragma mark -Action 
- (void)scrollToComment {
    
    [self resetCommentList];
    
    [DreamingAPI getConversation:[NSString stringWithFormat:@"%d", self.article.conversationID]
                             page:0
                           length:20
                         delegate:self
                    useCacheFirst:NO]; 
}

- (void)scrollToTop {
    
    [self.contentScrollView setContentOffset:CGPointZero animated:YES];
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

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    
    return YES;
}


@end
