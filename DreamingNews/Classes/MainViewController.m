//
//  ViewController.m
//  DreamingNews
//
//  Created by cg on 12-9-28.
//  Copyright (c) 2012年 Dreaming Team. All rights reserved.
//

#import "DreamingAPI.h"
#import "UIImageView+WebCache.h"
#import "StringUtils.h"
#import "ZAppDelegate.h"
#import "MovieViewController.h"
#import "UserAccount.h"
#import "StreamingPlayer.h"

#import "MainViewController.h"
#import "AllArticleViewController.h"
#import "EGOPhotoViewController.h"
#import "UserLoginViewController.h"
#import "UserLoginViewController_iPad.h"
#import "WebViewController.h"

#import "ZStatus.h"
#import "ZPhoto.h"
#import "ZPhotoSource.h"


@interface MainViewController () {
    
}

@property (nonatomic, retain) UIScrollView *scrollView;

@property (nonatomic, retain) UIImageView *photoFrameUpside;
@property (nonatomic, retain) UIImageView *photoFrameDownside;
@property (nonatomic, retain) UIButton *topBarLeftButton;
@property (nonatomic, retain) UIButton *topBarRightButton;

@property (nonatomic, retain) NSMutableArray *articleList;
@property (nonatomic, assign) NSInteger currentPageIndex;


+ (NSString *)stringWithUUID;
- (IBAction)showAllArticle:(id)sender;
- (IBAction)showFristPage:(id)sender;

- (void)refresh:(BOOL)useCacheFirst;
- (void)setTopBar;
- (void)setArticleView:(NSInteger)index;
- (void)resetScrollView;

- (NSString *)setTopBarButtonTitle;

@end


@implementation MainViewController

@synthesize scrollView;
@synthesize photoFrameUpside;
@synthesize photoFrameDownside;
@synthesize topBarLeftButton;
@synthesize topBarRightButton;
@synthesize articleList;
@synthesize currentPageIndex;



+ (NSString *)stringWithUUID
{
    CFUUIDRef uuidObj = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef strRef = CFUUIDCreateString(kCFAllocatorDefault, uuidObj);
    NSString* uuidString = [NSString stringWithString:(NSString*)strRef];
    CFRelease(strRef);
    CFRelease(uuidObj);
    return uuidString;
}

- (void)dealloc {
    
    [[RKClient sharedClient].requestQueue cancelRequestsWithDelegate:self];
    
    self.scrollView = nil;
    self.articleList = nil;
    self.photoFrameUpside = nil;
    self.photoFrameDownside = nil;
    self.topBarLeftButton = nil;
    self.topBarRightButton = nil;
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    self.view.frame = [[UIScreen mainScreen] applicationFrame];
    
    UIImageView *background = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 568)] autorelease];
    [background setImage:[UIImage imageNamed:@"Default-568h@2x"]];
    [self.view addSubview:background];
    
    //横滑 scrollView设置
    [self resetScrollView];
      
    self.articleList = [[[NSMutableArray alloc] init] autorelease];
    
    currentPageIndex = 0;
    
    [self refresh:YES]; 
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIDeviceOrientationPortrait);
}


- (void)resetScrollView {
   
    CGRect frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    
    [self.scrollView removeFromSuperview];
    self.scrollView = [[[UIScrollView alloc] initWithFrame:frame] autorelease];
    self.scrollView.clipsToBounds = YES;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.alwaysBounceVertical = NO;
    self.scrollView.delegate = self;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.backgroundColor = [UIColor clearColor];
    
    [self.view addSubview:self.scrollView];
    
    [self setTopBar];
}

- (void)setArticleView:(NSInteger)index {
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * [self.articleList count], SCREEN_HEIGHT);
    
    ZStatus *aarticle = [self.articleList objectAtIndex:index];
    
    CGRect articleViewFrame = {self.scrollView.frame.size.width * index, 0, SCREEN_WIDTH, SCREEN_HEIGHT};
    
    ArticleView *articleView = [[[ArticleView alloc] initWithFrame:articleViewFrame] autorelease];
    articleView.delegate = self;
    [articleView setArticleDatasource:aarticle];

    [self.scrollView addSubview:articleView];
    
    self.scrollView.showsHorizontalScrollIndicator = YES;
    self.scrollView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
    self.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, SCREEN_HEIGHT-8, 0);
}

- (void)setTopBar {
    
    if (self.photoFrameUpside != nil) {
        [self.view bringSubviewToFront:self.photoFrameUpside];
        [self.view bringSubviewToFront:self.photoFrameDownside];
        [self.view bringSubviewToFront:self.topBarLeftButton];
        [self.view bringSubviewToFront:self.topBarRightButton];
        
        return;
    }
    
    self.photoFrameUpside = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 40)] autorelease];
    [self.photoFrameUpside setImage:[UIImage imageNamed:@"photo_frame_up@2x"]];
    
    self.photoFrameDownside = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 254, SCREEN_WIDTH, 36)] autorelease];
    [self.photoFrameDownside setImage:[UIImage imageNamed:@"photo_frame_down@2x"]];
    
    self.topBarLeftButton = [[[UIButton alloc] initWithFrame:CGRectMake(6, 3, 44, 44)] autorelease];
    [self.topBarLeftButton setBackgroundImage:[UIImage imageNamed:@"date@2x"] forState:UIControlStateNormal];
    [self.topBarLeftButton addTarget:self action:@selector(showFristPage:) forControlEvents:UIControlEventTouchUpInside];
    [self.topBarLeftButton setTitle:[self setTopBarButtonTitle] forState:UIControlStateNormal];
    self.topBarLeftButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.topBarLeftButton setTitleEdgeInsets:UIEdgeInsetsMake(5,0,0,0)];
    
    self.topBarRightButton = [[[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 50, 3, 44, 44)]autorelease];
    [self.topBarRightButton setBackgroundImage:[UIImage imageNamed:@"show_articlelist@2x"] forState:UIControlStateNormal];
    [self.topBarRightButton addTarget:self action:@selector(showAllArticle:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.photoFrameUpside];
    [self.view addSubview:self.photoFrameDownside];
    [self.view addSubview:topBarLeftButton];
    [self.view addSubview:topBarRightButton];
}

- (NSString *)setTopBarButtonTitle {
        
    NSDateFormatter *formatter =[[[NSDateFormatter alloc] init] autorelease];
    NSDate *date = [NSDate date];
    [formatter setTimeStyle:NSDateFormatterMediumStyle];
    NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
    NSDateComponents *comps = [[[NSDateComponents alloc] init] autorelease];
    NSInteger unitFlags = NSYearCalendarUnit | 
    NSMonthCalendarUnit |
    NSDayCalendarUnit | 
    NSWeekdayCalendarUnit | 
    NSHourCalendarUnit |
    NSMinuteCalendarUnit |
    NSSecondCalendarUnit;
    
    comps = [calendar components:unitFlags fromDate:date];
    
    int day = [comps day];
    
    NSString *today = [NSString stringWithFormat:@"%d",day];
    
    return today;
}

#pragma mark - Action 


- (void)refresh:(BOOL)useCacheFirst {
    
    [DreamingAPI getUserTimeline:@"dota" maxId:-1 length:10 delegate:self useCacheFirst:useCacheFirst];
}

- (IBAction)showAllArticle:(id)sender {
    
    AllArticleViewController *viewController = [[[AllArticleViewController alloc] init] autorelease];
    viewController.delegate = self;
    
    [self presentModalViewController:viewController animated:YES];
}

- (IBAction)showFristPage:(id)sender {
    
    [self.scrollView setContentOffset:CGPointZero animated:NO];
    
    [self refresh:NO];
}

- (void)showArticles:(NSMutableArray *)articleArray articleIndex:(NSInteger)index {
    
    if ([articleArray count] > 0) {
        self.articleList = articleArray;
    }
    
    [self resetScrollView];

    CGPoint point = {self.scrollView.frame.size.width*index,0};
    
    [self.scrollView setContentOffset:point];
    
    currentPageIndex = index;
    
    for (int i = 0; i < [self.articleList count]; i++) {
        
        [self setArticleView:i];
    }
}

- (void)scrollToComment
{
    ZStatus *article = [self.articleList objectAtIndex:currentPageIndex];
    
    [self showArticleDetails:article shouldScrollToComment:YES];
}

#pragma mark RKObjectLoaderDelegate methods 

- (void)request:(RKRequest *)request didReceiveResponse:(RKResponse *)response {
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {

    [self.articleList removeAllObjects];
    
    for (ZStatus *aArticle in objects) {
        
        aArticle.text = [ZStatus formatStatusText:aArticle.text];
        [ZStatus separateTags:aArticle];
        
        [self.articleList addObject:aArticle];
    }
    
    [self resetScrollView];

    if ([self.articleList count] > 1) {
        
        [self setArticleView:1];
    }
    if ([self.articleList count] > 0) {
        
        [self setArticleView:0];
    }
    
    if (!objectLoader.response.wasLoadedFromCache) {
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastUpdateDate];
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
}

- (void)request:(RKRequest *)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
}

#pragma mark -
#pragma mark UIScrollViewDelegate 

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    
    return YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)ascrollView {
    
    CGSize pageSize = CGSizeMake(self.scrollView.frame.size.width, self.scrollView.frame.size.height); 
    NSInteger pageIndex = floor((ascrollView.contentOffset.x - pageSize.width / 2) / pageSize.width)+1;
    
    if (currentPageIndex == pageIndex || pageIndex > [self.articleList count] - 1 || pageIndex < 0) {
        return;
    }
    
    if (currentPageIndex + 1 == pageIndex ) {
        
        if (pageIndex + 1 < [self.articleList count]) {
            [self setArticleView:pageIndex+1];
        }
    } else {
        
        if (pageIndex - 1 > 0) {
            [self setArticleView:pageIndex-1];
        }
    }
    
    [self setArticleView:pageIndex];
    
    currentPageIndex = pageIndex;
}


#pragma mark - ArticleViewButtonClickedDelegate 

- (void)imageButtonClick {
    
    ZStatus *aarticle = [self.articleList objectAtIndex:currentPageIndex];
    
    NSString* videoUrlString = [ZStatus getVideoUrl:aarticle];
    if ([videoUrlString length] > 0) {
        
        MovieViewController *videoPlayer = [[MovieViewController alloc] initWithContentURL:
                                            [NSURL URLWithString:videoUrlString]];
        
        [videoPlayer shouldAutorotateToInterfaceOrientation:YES];
        
        [self presentMoviePlayerViewControllerAnimated:videoPlayer];
        
        return;
    }
    
    [self showArticleDetails:aarticle shouldScrollToComment:NO];
}

- (void)articleDetailButtonClick {
    
    ZStatus *article = [self.articleList objectAtIndex:currentPageIndex];
    
    [self showArticleDetails:article shouldScrollToComment:NO];
}


- (void)showArticleDetails:(ZStatus*)status shouldScrollToComment:(BOOL)scrollToComment
{
    // Show detail
    WebViewController *webViewController = [WebViewController createWebViewController:status baseTableViewControllerDelegate:nil];
    webViewController.shouldScrollToComment = scrollToComment;
    [self presentModalViewController:webViewController animated:YES];
    [webViewController release];
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
            break;
            
        default:
            break;
    }
}

#pragma mark AutoRefreshingDelegate

- (void)loadArticlesNow:(BOOL)useCache
{
    [self refresh:NO];
}

@end
