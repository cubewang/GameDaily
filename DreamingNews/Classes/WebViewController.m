//
//  WebViewController.m
//  Dreaming
//
//  Created by Cube on 11-5-1.
//  Copyright 2011 Dreaming Team. All rights reserved.
//

#import <MessageUI/MessageUI.h>

#import "WebViewController.h"
#import "UserLoginViewController.h"
#import "UserLoginViewController_iPad.h"
#import "EGOPhotoViewController.h"
#import "SearchWebViewController.h"
#import "MovieViewController.h"

#import "AudioCommentCell.h"
#import "TextCommentCell.h"
#import "GlobalDef.h"
#import "ZConversation.h"

#import "ZAppDelegate.h"
#import "UserAccount.h"
#import "StringUtils.h"

#import "ZPhoto.h"
#import "ZPhotoSource.h"
#import "ZStatus.h"



@interface NoAutoScrollUIScrollView : UIScrollView

@end

@implementation NoAutoScrollUIScrollView

- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated
{
	// Don'd do anything here to prevent autoscrolling. 
	// Unless you plan on using this method in another fashion.
}

@end


@interface NoMenuUITextView : UITextView

@end

@implementation NoMenuUITextView

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(cut:)){  
        return NO;  
    }
    else if(action == @selector(copy:)){  
        return YES;  
    }
    else if(action == @selector(paste:)){  
        return NO;  
    }
    else if(action == @selector(select:)){  
        return NO;  
    }
    else if(action == @selector(selectAll:)){  
        return NO;  
    }
    else   
    {  
        return [super canPerformAction:action withSender:sender];  
    }
}

@end

@interface WebViewController() {
    
    int commentCountBeforeLoading; //分段请求前的评论数，用于记录是否请求完所有评论
}

@property (nonatomic, retain) ZStatus *operatingComment;

@property (nonatomic, retain) ZStatus *replyToComment;
@property (nonatomic, retain) UITableViewCell *replyToCommentCell;

@property (nonatomic, retain) NSMutableArray *commentListCached;

@end


@implementation WebViewController


@synthesize shouldScrollToComment;

@synthesize article;
@synthesize conversation;
@synthesize shouldAutoPlayAudio;

@synthesize operatingComment;
@synthesize replyToComment;
@synthesize replyToCommentCell;
@synthesize commentListCached;

@synthesize selectedWord, word;
@synthesize wordPanelView, wordLabel, accetationLabel;

@synthesize contentScrollView;
@synthesize articleView;
@synthesize articleSignature;

@synthesize player;
@synthesize coverImageView;
@synthesize coverButton;

@synthesize commentTableView;
@synthesize textCommentString;
@synthesize commentView;


@synthesize swipeRightRecognizer;
@synthesize longPressGestureRecognizer;



+ (WebViewController*)createWebViewController:(ZStatus*)article 
              baseTableViewControllerDelegate:(id)delegate
{
    if (article == nil)
        return nil;
    
    WebViewController *webViewController = [[UIDevice currentDevice] userInterfaceIdiom ] == UIUserInterfaceIdiomPhone ?
        [[WebViewController alloc] init] :
        [[WebViewController alloc] initWithNibName:@"WebView_iPad" bundle:nil];
    
    webViewController.article = article;
    
    return webViewController;
}


- (void)dealloc {
    
    [[RKClient sharedClient].requestQueue cancelRequestsWithDelegate:self];
    
    self.article = nil;
    
    self.conversation = nil;
    self.commentListCached = nil;
    
    self.operatingComment = nil;
    self.replyToComment = nil;
    self.replyToCommentCell = nil;
    
    self.selectedWord = nil;
    self.word = nil;
    
    self.contentScrollView = nil;
    self.articleView = nil;
    self.articleSignature = nil;
    
    [self.player stopPlaying];
    self.player.stateChangedDelegate = nil;
    self.player = nil;
    self.coverImageView = nil;
    self.coverButton = nil;
    
    self.commentTableView = nil;
    self.commentView.delegate = nil;
    self.commentView = nil;
    self.textCommentString = nil;
    
    self.swipeRightRecognizer = nil;
    self.longPressGestureRecognizer = nil;

    [super dealloc];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.contentScrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    //[self setupLongPressGesture];

    [self initCommentView];
    [self loadArticle:self.article];
}

- (void)addTitleView {
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)initControls:(ZStatus*)status
{
    CGFloat top = 0;
    
    if ([[ZStatus getCoverImageUrl:status] length] > 0) {
        
        CGFloat coverHeight = ([[UIDevice currentDevice] userInterfaceIdiom ] == UIUserInterfaceIdiomPhone ? 220 : COVER_IMAGE_HEIGHT * 4 / 3);
        
        self.coverImageView = [[[UIImageView alloc] init] autorelease];
        
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.coverImageView setClipsToBounds:YES];
        self.coverImageView.frame = CGRectMake(0,
                                               top,
                                               SCREEN_WIDTH,
                                               coverHeight);
        
        [self.contentScrollView addSubview:self.coverImageView];
        
        [self.coverImageView setImageWithURL:[NSURL URLWithString:[ZStatus getCoverImageUrl:status]] 
                               placeholderImage:[UIImage imageNamed:@"DefaultCover@2x"]];
        
        self.coverButton = [[[UIButton alloc] init] autorelease];
        [self.coverButton addTarget:self action:@selector(coverButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        
        if ([[ZStatus getVideoUrl:status] length] > 0) {
            
            if ([[UIDevice currentDevice] userInterfaceIdiom ] == UIUserInterfaceIdiomPhone) {
                [self.coverButton setImage:[UIImage imageNamed:@"video_button@2x.png"] forState:UIControlStateNormal];
            }
            else {
                [self.coverButton setImage:[UIImage imageNamed:@"video_button_iPad.png"] forState:UIControlStateNormal];
            }
        }
        
        self.coverButton.frame = CGRectMake(kTableCellMargin,
                                            top,
                                            COVER_IMAGE_WIDTH,
                                            200);
        
        [self.contentScrollView addSubview:self.coverButton];
        
        top += coverHeight + kTableCellMargin;
    }
    
    if ([[ZStatus getAudioUrl:status] length] > 0) {
        
        self.player = [[[StreamingPlayer alloc] initWithFrame:CGRectMake(0, 0, PLAYER_HEIGHT, PLAYER_WIDTH)] autorelease];
        self.player.stateChangedDelegate = self;
        
        [self.contentScrollView addSubview:self.player];
        
        self.player.frame = CGRectMake((SCREEN_WIDTH - PLAYER_WIDTH)/2,
                                       top,
                                       PLAYER_WIDTH,
                                       PLAYER_HEIGHT);
        
        top += PLAYER_HEIGHT + kTableCellMargin;
        
        [self.player setAudioUrl:[ZStatus getAudioUrl:status]];
        
        if (self.shouldAutoPlayAudio) {
            [self.player buttonPressed:nil];
        }
    }
    
    NSString *contentString = status.text;
    
    //计算articleView高度
    self.articleView.frame = CGRectMake(kTableCellSmallMargin,
                                        top,
                                        SCREEN_WIDTH - 2*kTableCellSmallMargin,
                                        SCREEN_HEIGHT);
    
    self.articleView.text = contentString;
    
    //设置高度
    self.articleView.frame = CGRectMake(kTableCellSmallMargin,
                                        top,
                                        SCREEN_WIDTH - 2*kTableCellSmallMargin,
                                        self.articleView.contentSize.height);
    
    self.contentScrollView.contentSize = CGSizeMake(SCREEN_WIDTH, top + self.articleView.frame.size.height + kTableCellSmallMargin);
    
    CGRect signatureRect = self.articleSignature.frame;
    signatureRect.origin.y = self.contentScrollView.contentSize.height;
    self.articleSignature.frame = signatureRect;
    
    self.contentScrollView.contentSize = 
    CGSizeMake(SCREEN_WIDTH, self.contentScrollView.contentSize.height + signatureRect.size.height);
    
    if (self.shouldScrollToComment) {
        CGPoint point = CGPointMake(0, self.articleView.contentSize.height);
        
        [self.contentScrollView setContentOffset:point animated:YES];
    }
}


- (void)initCommentTableView:(ZConversation*)theConversation
{
    if ([theConversation.statusList count] == 0)
        return;
    
    CGFloat tableHeight = [self tableHeightForObject:theConversation];
    
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
    self.commentTableView.separatorColor = [UIColor blackColor];
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

- (void)initCommentView {
    
    if (self.commentView == nil) {
        
        self.commentView = [[[ZTextField alloc] init] autorelease];
        self.commentView.delegate = self;
        [self.commentView setView:self.view];
        
        [self.view addSubview:self.commentView];
    }
    
    [self.view bringSubviewToFront:wordPanelView];
}

- (void)postCommentToServer {
    
    [[ZAppDelegate sharedAppDelegate] showProgress:self.view info:NSLocalizedString(@"发送中", @"")];
    [[ZAppDelegate sharedAppDelegate] setProgress:self.view progress:0.2 info:NSLocalizedString(@"发送中", @"")];
    
    NSInteger statusId = self.replyToComment == nil ? self.article.statusID : self.replyToComment.statusID;
    
    [DreamingAPI postStatus:self.textCommentString
                filePath:nil
              websiteUrl:nil 
       inReplyToStatusId:[NSString stringWithFormat:@"%d", statusId]
                latitude:nil
               longitude:nil 
                delegate:self];
}

- (void)postAudioComment:(BOOL)isAudioComment {
    
    if ([UserAccount getUserName] == nil) {
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            
            UserLoginViewController *userLoginVC = [[[UserLoginViewController alloc] init]autorelease];
            userLoginVC.delegate = self;
            [self presentModalViewController:userLoginVC animated:YES];
        } 
        else {
            UserLoginViewController_iPad *userLoginVC = [[[UserLoginViewController_iPad alloc] init]autorelease];
            userLoginVC.delegate = self;
            [self presentModalViewController:userLoginVC animated:YES];
        }

    } else {
        
        [self postCommentToServer];
    }
}


- (void)userLoginViewControllerReturnResult {
    
    [self postCommentToServer];
}


#pragma mark -
#pragma mark Gesture

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    return YES;
}

- (IBAction)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
    
    [self back:nil];
}

- (void)setupLongPressGesture
{
    //取词长按手势
    self.longPressGestureRecognizer = 
    [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    
    [self.articleView addGestureRecognizer:self.longPressGestureRecognizer];
    [self.longPressGestureRecognizer setDelegate:self];
    [self.longPressGestureRecognizer release];
}

- (void)delayDidWordPanelShow:(id) sender
{
    //隐藏取词Bar
    self.wordPanelView.alpha = 1.0;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDuration:0.3];
    
    self.wordPanelView.alpha = 0.0;
    
    [UIView commitAnimations];
}

- (IBAction) worldPanelViewDidClicked:(id)sender
{
    [self showDictPage];
}

- (void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer {
    
    if (self.articleView.selectedRange.location == NSNotFound || self.articleView.selectedRange.length == 0) {
        
        return;
    }
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    UIMenuItem *resetMenuItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"翻译verb", @"") action:@selector(showDictPage)];
    [menuController setMenuItems:[NSArray arrayWithObjects:resetMenuItem, nil]];
    [menuController setMenuVisible:YES animated:YES];
    [resetMenuItem release];
    
    NSString* selection = [self.articleView.text substringWithRange:self.articleView.selectedRange];
    
    //去掉左右空格
    selection = [selection stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSArray *wordArray = [selection componentsSeparatedByString:@" "];
    if ([wordArray count] > 1) {
        
        //翻译句子
        return;
    }
    
    //选择的内容为空
    if (selection.length == 0)
    {
        return;
    }
    
    //显示取词Bar
    if (self.wordPanelView.hidden || self.wordPanelView.alpha < 0.1)
    {
        self.wordPanelView.hidden = NO;
        self.wordPanelView.alpha = 0.0;
        
        [UIView beginAnimations:nil 
                        context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        [UIView setAnimationDuration:.3];
        
        self.wordPanelView.alpha = 1.0;
        
        [UIView commitAnimations];
    }
    
    //防止重发查询
    if (self.word != nil && [selection isEqualToString:self.word.Key])
    {
        if ([self.word.AcceptationList count] > 0)
        {
            self.accetationLabel.text = [self.word.AcceptationList objectAtIndex:0];
        }
        else {
            self.accetationLabel.text = NSLocalizedString(@"点击查看释义", @"");
        }
        
        [self performSelector:@selector(delayDidWordPanelShow:) 
                   withObject:nil 
                   afterDelay:3];
        
        return;
    }
    
    if ([DreamingAPI getWord:selection delegate:self]) {

        self.selectedWord = selection;
        self.wordLabel.text = self.selectedWord;
        self.accetationLabel.text = NSLocalizedString(@"查找中...", @"");
    }
}

- (void)showDictPage
{
    if ([self.selectedWord length] > 0)
    {
        NSString *dictUrl = [NSString stringWithFormat:@"%@%@", DICTIONARY_PAGE, self.selectedWord];
        SearchWebViewController *searchViewController = [[SearchWebViewController alloc] init];
        searchViewController.contentUrl = dictUrl;
        [self presentModalViewController:searchViewController animated:YES];
        
        [searchViewController release];
    }
}


#pragma mark -
#pragma mark Comment Cell Action

- (IBAction)commentCellButtonAction:(UIButton *)sender {
    
    if ([self needUserLogin:nil])
        return;
    
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
#pragma mark StreamingPlayerStateChangedDelegate

- (void)streamingPlayerStateDidChange:(BOOL)isPlaying
{
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
        cell.textLabel.textColor = CELLTEXT_COLOR;
        
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
    
    return [self isAudioComment:comment] ? [AudioCommentCell heightForCell:comment replyToStatus:nil] : [TextCommentCell heightForCell:comment];
}


- (CGFloat)tableHeightForObject:(ZConversation*)theConversation {
    
    CGFloat tableHeight = 0.0;
    
    for (ZStatus *status in theConversation.statusList)
    {
        if (status.statusID == theConversation.originalStatus.statusID)
            continue;
        
        tableHeight += ([self isAudioComment:status] ? [AudioCommentCell heightForCell:status replyToStatus:nil] : [TextCommentCell heightForCell:status]);
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



- (void)loadArticle:(ZStatus *)status
{
    if (status == nil || status.text == nil)
        return;
    
    [self initControls:status];
    
    [self addTitleView];
    
    [DreamingAPI getConversation:[NSString stringWithFormat:@"%d", status.conversationID]
                         page:0
                       length:20
                     delegate:self
                useCacheFirst:NO];
}


- (void)showWordOnLabel {

    if (self.word == nil)
    {
        self.accetationLabel.text = NSLocalizedString(@"点击查看释义", @"");
        
        [self performSelector:@selector(delayDidWordPanelShow:) 
                   withObject:nil 
                   afterDelay:3];
        return;
    }

    self.wordLabel.text = self.word.Key;

    if ([self.word.AcceptationList count] > 0)
    {
        self.accetationLabel.text = [self.word.AcceptationList objectAtIndex:0];
    }
    else {
        self.accetationLabel.text = NSLocalizedString(@"点击查看释义", @"");
    }

    [self performSelector:@selector(delayDidWordPanelShow:) 
               withObject:nil 
               afterDelay:3];
}

- (void)scrollToComment {
    
    [self resetCommentList];
    
    [DreamingAPI getConversation:[NSString stringWithFormat:@"%d", self.article.conversationID]
                         page:0
                       length:20
                     delegate:self
                useCacheFirst:NO];
    
    CGPoint point = CGPointMake(0, self.articleView.contentSize.height);
    
    [self.contentScrollView setContentOffset:point animated:YES];
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
    else if ([string hasPrefix:[NSString stringWithFormat:@"%@%@", MAIN_PATH, STATUS_UPDATE]]) {
        
        if (response.statusCode == 200) {
            
            [[ZAppDelegate sharedAppDelegate] setProgress:self.view progress:1.0 info:NSLocalizedString(@"评论发送成功", @"")];
            
            [self scrollToComment];
        }
        else {
            [[ZAppDelegate sharedAppDelegate] setProgress:self.view progress:1.0 info:NSLocalizedString(@"评论发送失败",@"")];
        }
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
    
    else if ([string hasPrefix:[NSString stringWithFormat:@"%@%@",DICT_PATH,DICTIONARY]])
    {
        self.word = (ZWord *)object;
        
        if (self.word.Key == nil)
            self.word.Key = (self.selectedWord ? self.selectedWord : @"");
        
        [self showWordOnLabel];
    }
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    
    NSString *string = [objectLoader.URL absoluteString];
    
    if ([string hasPrefix:[NSString stringWithFormat:@"%@%@",DICT_PATH,DICTIONARY]])
    {
        if ([self.selectedWord length]) {
            wordLabel.text = self.selectedWord;
            accetationLabel.text = NSLocalizedString(@"单词查找失败",@"");
            self.word = nil;
        }
        
        [self delayDidWordPanelShow:nil];
    }
    else if ([string hasPrefix:[NSString stringWithFormat:@"%@%@",MAIN_PATH,STATUS_UPDATE]]) {
        
        [[ZAppDelegate sharedAppDelegate] setProgress:self.view progress:1.0 info:NSLocalizedString(@"评论发送失败",@"")];
    }
    else if ([string hasPrefix:[NSString stringWithFormat:@"%@/statusnet/conversation", MAIN_PATH]])
    {
        [[ZAppDelegate sharedAppDelegate] showNetworkFailed:self.view];
        [self.commentTableView reloadData];
    }
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [[ZAppDelegate sharedAppDelegate] showNetworkFailed:self.view];
}


#pragma mark * UI Actions

- (IBAction)back:(id)sender {
    
    [AudioCommentCell stopAudioPlaying];
    
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)shareByActivity:(id)sender {
    
    NSString *text = [ZStatus revertStatusText:self.article.text];
    
    if ([text length] == 0)
        return;
    
    [self shareToSNS:text];
}

- (void)shareToSNS:(NSString *)text
{
    if ([text length] == 0)
        return;
    
    NSArray *activityItems;
    NSURL *url = [NSURL URLWithString:NSLocalizedString(@"rate url", @"")];
    
    if (self.coverImageView.image != nil) {
        activityItems = @[text, self.coverImageView.image, url];
    } else {
        activityItems = @[text, url];
    }
    
    UIActivityViewController *activityController =
    [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                      applicationActivities:nil];
    
    [self presentViewController:activityController
                       animated:YES completion:nil];
}

- (BOOL)needUserLogin:(id)callbackDelegate
{
    if ([UserAccount getUserName] == nil) {
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            
            UserLoginViewController *userLoginVC = [[[UserLoginViewController alloc] init]autorelease];
            userLoginVC.delegate = callbackDelegate;
            [self presentModalViewController:userLoginVC animated:YES];
        }
        else {
            UserLoginViewController_iPad *userLoginVC = [[[UserLoginViewController_iPad alloc] init]autorelease];
            userLoginVC.delegate = callbackDelegate;
            [self presentModalViewController:userLoginVC animated:YES];
        }
        
        return YES;
    }
    
    return NO;
}


- (IBAction)coverButtonClicked:(id)sender {

    NSString* videoUrlString = [ZStatus getVideoUrl:self.article];
    if ([videoUrlString length] > 0) {
        
        [self playVideoNow];
        
        return ;
    }
    
    NSString* coverUrlString = [ZStatus getCoverImageUrl:self.article];
    if ([coverUrlString length] == 0) {
        return ;
    }
    
    ZPhoto *photo = [[ZPhoto alloc] initWithImageURL:[NSURL URLWithString:coverUrlString]];
    ZPhotoSource *source = [[ZPhotoSource alloc] initWithPhotos:[NSArray arrayWithObjects:photo, nil]];
    
    EGOPhotoViewController *photoController = [[EGOPhotoViewController alloc] initWithPhotoSource:source];
    [self.navigationController pushViewController:photoController animated:YES];
    
    [photoController release];
    [photo release];
    [source release];
}

- (void)playVideoNow
{
    NSString* videoUrlString = [ZStatus getVideoUrl:self.article];
    if ([videoUrlString length] == 0) {
        return ;
    }
    
    MovieViewController *videoPlayer = [[MovieViewController alloc] initWithContentURL:
                                        [NSURL URLWithString:videoUrlString]];
    
    [videoPlayer shouldAutorotateToInterfaceOrientation:YES];
    
    [self presentMoviePlayerViewControllerAnimated:videoPlayer];
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer 
        shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer 
{
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    //[super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}


- (void)setRefreshComment
{
    [DreamingAPI getConversation:[NSString stringWithFormat:@"%d", self.article.conversationID]
                         page:0
                       length:20
                     delegate:self
                useCacheFirst:NO];
}

#pragma mark touch

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [self.commentView resignFirstResponder];
}

#pragma mark ZTextFieldDelegate

- (void)ZTextFieldButtonDidClicked:(ZTextField *)sender {
    
    ZTextField *text= sender;
    
    if ([text.textView.text length] == 0) {
        
        [[ZAppDelegate sharedAppDelegate] showInformation:self.view info:NSLocalizedString(@"评论不能为空",@"" ) ];
        
        return;
    }
    
    self.textCommentString = text.textView.text;
    
    [self.commentView resignFirstResponder];
    
    if (![self needUserLogin:self]) {
        
        [self postCommentToServer];
    }
}

- (void)ZTextFieldKeyboardPopup:(ZTextField *)sender {
    
    self.contentScrollView.userInteractionEnabled = NO;
}

- (void)ZTextFieldKeyboardDrop:(ZTextField *)sender {
    
    self.contentScrollView.userInteractionEnabled = YES;
}


#pragma mark audio player

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    if (event.type != UIEventTypeRemoteControl) {
        return;
    }
    
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlPause:
            break;
        case UIEventSubtypeRemoteControlPlay:    
            break;
        case UIEventSubtypeRemoteControlStop:
            break;
        case UIEventSubtypeRemoteControlTogglePlayPause:
        {
	    [self.player startOrPauseAudioPlaying];
            
            break;
        }
            
        default:
            break;
    }
}


@end
