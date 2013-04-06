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

#import "MainViewController_iPad.h"
#import "AllArticleViewController.h"
#import "EGOPhotoViewController.h"
#import "UserLoginViewController.h"
#import "UserLoginViewController_iPad.h"

#import "ZStatus.h"
#import "ZPhoto.h"
#import "ZPhotoSource.h"


@interface MainViewController_iPad () {
    
    BOOL _reloading;
    BOOL _lockPageChange;
    
    NSUInteger _pageIndex;
}

@property (nonatomic, retain) UIScrollView *scrollView;

@property (nonatomic, retain) UIImageView *topBar;
@property (nonatomic, retain) UIButton *topBarLeftButton;
@property (nonatomic, retain) UIButton *topBarRightButton;
@property (nonatomic, retain) UIButton *topBarCenterButton;

@property (nonatomic, retain) NSMutableArray *articleList;
@property (nonatomic, retain) NSMutableArray *articleControllerArray;
@property (nonatomic, retain) NSString *textCommentString;
@property (nonatomic, retain) ZTextField *commentView;

@property (nonatomic, assign) id<ArticleViewScrollToTopDelegate> delegate;

@property (nonatomic, assign) NSUInteger pageIndex;

+ (NSString *)stringWithUUID;
- (IBAction)showAllArticle:(id)sender;
- (IBAction)showFristPage:(id)sender;

- (void)refresh:(BOOL)useCacheFirst;
- (void)setTopBar;
- (void)setArticleView:(NSInteger)index;
- (void)resetScrollView;

- (NSString *)setTopBarButtonTitle;
- (void)commentPost;
- (void)resetCommentView;
- (void)articleViewScrollToTop;

- (void)reloadPages;
- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated;//TODO animations
- (void)setPageIndex:(NSUInteger)index animated:(BOOL)animated;

@end

@implementation MainViewController_iPad

@synthesize scrollView;
@synthesize topBar;
@synthesize topBarLeftButton;
@synthesize topBarRightButton;
@synthesize articleList;
@synthesize textCommentString;
@synthesize commentView;
@synthesize topBarCenterButton;
@synthesize delegate;
@synthesize articleControllerArray;

+ (NSString *) stringWithUUID
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
    self.topBar = nil;
    self.topBarLeftButton = nil;
    self.topBarRightButton = nil;
    self.topBarCenterButton = nil;

    self.commentView = nil;
    self.textCommentString = nil;
    self.articleControllerArray = nil;
    self.delegate = nil;
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    self.view.frame = [[UIScreen mainScreen] applicationFrame];
    
    self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    
    CGRect frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    self.scrollView = [[UIScrollView alloc] initWithFrame:frame];
    self.scrollView.delegate = self;
    self.scrollView.autoresizesSubviews = YES;
    self.scrollView.backgroundColor = [UIColor whiteColor];
    self.scrollView.canCancelContentTouches = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.clipsToBounds = YES;
    self.scrollView.scrollEnabled = YES;
    self.scrollView.pagingEnabled = YES;
    
    self.scrollView.showsHorizontalScrollIndicator = YES;
    self.scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    
    [self.view addSubview:scrollView];
    
    [self resetCommentView];
    
    [self setTopBar];
    
    self.articleList = [[[NSMutableArray alloc] init] autorelease];
    self.articleControllerArray = [[[NSMutableArray alloc] init]autorelease];
    
    _pageIndex = 0;
    
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


- (void)resetCommentView {
    
    if (self.commentView != nil) {
                
       [self.view bringSubviewToFront:self.commentView];
       
       return;
    }
    
    self.commentView = [[[ZTextField alloc] init] autorelease];
    self.commentView.delegate = self;
    [self.commentView setView:self.view];
    
    [self.view addSubview:self.commentView];
}


- (void)setArticleView:(NSInteger)index {
    
    ZStatus *aarticle = [self.articleList objectAtIndex:index];
    
    ArticleViewController_iPad *articleView = [[[ArticleViewController_iPad alloc] init] autorelease];
    articleView.delegate = self;
    [articleView setArticleDatasource:aarticle];
}

- (void)setTopBar {
    
    if (self.topBar != nil) {
        [self.view bringSubviewToFront:self.topBar];
        [self.view bringSubviewToFront:self.topBarLeftButton];
        [self.view bringSubviewToFront:self.topBarRightButton];
        [self.view bringSubviewToFront:self.topBarCenterButton];
        
        return;
    }
    
    self.topBar = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 46)] autorelease];
    [topBar setImage:[UIImage imageNamed:@"topbar_background@2x"]];
    
    UIImageView *topBarTitleImageView = [[[UIImageView alloc] initWithFrame:CGRectMake((SCREEN_WIDTH-124)/2, 0, 124, 47)] autorelease];
    [topBarTitleImageView setImage:[UIImage imageNamed:@"topbar_title@2x"]];
    
    self.topBarLeftButton = [[[UIButton alloc] initWithFrame:CGRectMake(6, 3, 44, 44)] autorelease];
    [topBarLeftButton setBackgroundImage:[UIImage imageNamed:@"date@2x"] forState:UIControlStateNormal];
    [topBarLeftButton addTarget:self action:@selector(showFristPage:) forControlEvents:UIControlEventTouchUpInside];
    [topBarLeftButton setTitle:[self setTopBarButtonTitle] forState:UIControlStateNormal];
    topBarLeftButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [topBarLeftButton setTitleEdgeInsets:UIEdgeInsetsMake(5,0,0,0)];
    
    self.topBarRightButton = [[[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 50, 3, 44, 44)]autorelease];
    [topBarRightButton setBackgroundImage:[UIImage imageNamed:@"show_articlelist@2x"] forState:UIControlStateNormal];
    [topBarRightButton addTarget:self action:@selector(showAllArticle:) forControlEvents:UIControlEventTouchUpInside];
    
    [topBar addSubview:topBarTitleImageView];
    
    self.topBarCenterButton = [[[UIButton alloc] initWithFrame:CGRectMake(130, 0, SCREEN_WIDTH-200, 44)]autorelease];
    self.topBarCenterButton.backgroundColor = [UIColor clearColor];
    [self.topBarCenterButton addTarget:self action:@selector(articleViewScrollToTop) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:topBar];
    [self.view addSubview:topBarLeftButton];
    [self.view addSubview:topBarRightButton];
    [self.view addSubview:topBarCenterButton];
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
- (void)articleViewScrollToTop {
    
    if ([delegate respondsToSelector:@selector(scrollToTop)]) {
        
        [delegate scrollToTop];
    }
}

- (void)refresh:(BOOL)useCacheFirst {
    
    [DreamingAPI getUserTimeline:@"dota" maxId:-1 length:10 delegate:self useCacheFirst:useCacheFirst];
}

- (IBAction)showAllArticle:(id)sender {
    
    [self.commentView resignFirstResponder];
    
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
    
    [self.articleControllerArray removeAllObjects];

    CGPoint point = {self.scrollView.frame.size.width*index, 0};
    
    [self.scrollView setContentOffset:point];
    
    _pageIndex = index;
    
    for (int i = 0; i < [self.articleList count]; i++) {
        
        ArticleViewController_iPad *vc = [[[ArticleViewController_iPad alloc]init]autorelease];
        [vc setArticleDatasource:[self.articleList objectAtIndex:i]];
        vc.delegate = self;
        vc.view.backgroundColor = [UIColor whiteColor];
        
        [self.articleControllerArray addObject:vc];
    }
     
    [self setViewControllers:self.articleControllerArray animated:NO];
    
    [self setPageIndex:index animated:NO];
}

- (void)commentPost {
    
    [[ZAppDelegate sharedAppDelegate] showProgress:self.view info:NSLocalizedString(@"发送中", @"")];
    [[ZAppDelegate sharedAppDelegate] setProgress:self.view progress:0.2 info:NSLocalizedString(@"发送中", @"")];
    
    ZStatus *status = [self.articleList objectAtIndex:_pageIndex];
    
    NSString *statusId = [NSString stringWithFormat:@"%d",status.statusID];
    
    [DreamingAPI postStatus:self.textCommentString
                    filePath:nil
                  websiteUrl:nil 
           inReplyToStatusId:statusId 
                    latitude:nil
                   longitude:nil
                    delegate:self];
}
#pragma mark RKObjectLoaderDelegate methods 

- (void)request:(RKRequest *)request didReceiveResponse:(RKResponse *)response {
    
    NSString *string = [response.URL absoluteString];
    
    if ([string hasPrefix:[NSString stringWithFormat:@"%@%@",MAIN_PATH,STATUS_UPDATE]]) {
        
        if (response.statusCode == 200) {
            
            [[ZAppDelegate sharedAppDelegate] setProgress:self.view progress:1.0 info:NSLocalizedString(@"评论发送成功", @"")];
            
            if ([delegate respondsToSelector:@selector(scrollToComment)]) {
                
                [delegate scrollToComment];
            }
        }
        else {
            [[ZAppDelegate sharedAppDelegate] setProgress:self.view progress:1.0 info:NSLocalizedString(@"评论发送失败",@"")];
        }
    }
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {

    NSString *string = [objectLoader.URL absoluteString];
    
    if ([string hasPrefix:[NSString stringWithFormat:@"%@/statuses/user_timeline", MAIN_PATH]])
    {
        [self.articleList removeAllObjects];
        [self.articleControllerArray removeAllObjects];
        
        for (ZStatus *aArticle in objects) {
            
            aArticle.text = [ZStatus formatStatusText:aArticle.text];
            [ZStatus separateTags:aArticle];
            
            [self.articleList addObject:aArticle];
        }
        

        if ([self.articleList count] > 0) {
            
            for (int i = 0; i < [self.articleList count]; i ++) {
                
                ArticleViewController_iPad *vc = [[[ArticleViewController_iPad alloc]init]autorelease];
                [vc setArticleDatasource:[self.articleList objectAtIndex:i]];
                vc.delegate = self;
                vc.view.backgroundColor = [UIColor whiteColor];
                
                [self.articleControllerArray addObject:vc];
            }
            
            [self setViewControllers:self.articleControllerArray animated:NO];
            
            self.delegate = [self.articleControllerArray objectAtIndex:0];
        }
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    
    [[ZAppDelegate sharedAppDelegate] showNetworkFailed:self.view];
    
    NSString *string = [objectLoader.response.URL absoluteString];
    
    if ([string hasPrefix:[NSString stringWithFormat:@"%@%@",MAIN_PATH,STATUS_UPDATE]]) {
    
        [[ZAppDelegate sharedAppDelegate] setProgress:self.view progress:1.0 info:NSLocalizedString(@"评论发送失败",@"")];
    }
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
    
    NSString *url = [request.URL absoluteString];
    
    if ([url hasPrefix:[NSString stringWithFormat:@"%@%@",MAIN_PATH,STATUS_UPDATE]]) {
        
        [[ZAppDelegate sharedAppDelegate] setProgress:self.view progress:1.0 info:NSLocalizedString(@"评论发送失败",@"")];
    }
}


#pragma mark - ArticleViewButtonClickedDelegate 

- (void)imageButtonClick {
    
    ZStatus *aarticle = [self.articleList objectAtIndex:_pageIndex];
    
    NSString* videoUrlString = [ZStatus getVideoUrl:aarticle];
    if ([videoUrlString length] > 0) {
        
        MovieViewController *videoPlayer = [[MovieViewController alloc] initWithContentURL:
                                            [NSURL URLWithString:videoUrlString]];
        
        [videoPlayer shouldAutorotateToInterfaceOrientation:YES];
        
        [self presentMoviePlayerViewControllerAnimated:videoPlayer];
        
        return;
    }
    
    NSString* coverUrlString = [ZStatus getCoverImageUrl:aarticle];
    
    if ([coverUrlString length] == 0) {
        return ;
    }
    
    ZPhoto *photo = [[ZPhoto alloc] initWithImageURL:[NSURL URLWithString:coverUrlString]];
    ZPhotoSource *source = [[ZPhotoSource alloc] initWithPhotos:[NSArray arrayWithObjects:photo, nil]];
    
    EGOPhotoViewController *photoController = [[EGOPhotoViewController alloc] initWithPhotoSource:source];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:photoController];
    navController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    navController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentModalViewController:navController animated:YES];
    
    [navController release];
    [photoController release];
    [photo release];
    [source release];
}

- (void)postAudioComment:(BOOL)isAudioComment {
    
    if ([UserAccount getUserName] == nil) {
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            
            UserLoginViewController *vc = [[UserLoginViewController alloc] init];
            vc.delegate = self;
            [self presentModalViewController:vc animated:YES];
            
            [vc release];
        }
        else {
            
            UserLoginViewController_iPad *vc = [[UserLoginViewController_iPad alloc] init];
            vc.delegate = self;
            [self presentModalViewController:vc animated:YES];
            
            [vc release];
        }
    } else {
        
        [self commentPost];
    }
}



- (void)userLoginViewControllerReturnResult {
    
    [self commentPost];
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
    
    if ([UserAccount getUserName] == nil) {
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            
            UserLoginViewController *vc = [[UserLoginViewController alloc] init];
            vc.delegate = self;
            [self presentModalViewController:vc animated:YES];
            
            [vc release];
        }
        else {
            
            UserLoginViewController_iPad *vc = [[UserLoginViewController_iPad alloc] init];
            vc.delegate = self;
            [self presentModalViewController:vc animated:YES];
            
            [vc release];
        }
    }
    else {
        
        [self commentPost];
    }
}


- (void)ZTextFieldKeyboardPopup:(ZTextField *)sender {
    
    self.scrollView.userInteractionEnabled = NO;
}

- (void)ZTextFieldKeyboardDrop:(ZTextField *)sender {
    
    self.scrollView.userInteractionEnabled = YES;
}

#pragma mark Properties
- (void)setPageIndex:(NSUInteger)pageIndex {
    [self setPageIndex:pageIndex animated:NO];
}

- (void)setPageIndex:(NSUInteger)index animated:(BOOL)animated; {
    _pageIndex = index;
    /*
	 *	Change the scroll view
	 */
    CGRect frame = scrollView.frame;
    frame.origin.x = frame.size.width * index;
    frame.origin.y = 0;
	
    if (frame.origin.x < scrollView.contentSize.width) {
        [scrollView scrollRectToVisible:frame animated:animated];
    }
}

- (NSUInteger)pageIndex {
    return _pageIndex;
}

#pragma mark -
#pragma mark UIScrollViewDelegate stuff
- (void)scrollViewDidScroll:(UIScrollView *)_scrollView
{
    //The scrollview tends to scroll to a different page when the screen rotates
    if (_lockPageChange)
        return;
    
	/*
	 *	We switch page at 50% across
	 */
    CGFloat pageWidth = _scrollView.frame.size.width;
    int page = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    _pageIndex = page;
    
    self.delegate = [self.articleControllerArray count] > _pageIndex ? [self.articleControllerArray objectAtIndex:_pageIndex] : nil;
}

- (void)reloadPages {

    for (UIView *view in scrollView.subviews) {
        [view removeFromSuperview];
    }
    
	CGFloat cx = 0;
    
    NSUInteger count = self.childViewControllers.count;
	for (NSUInteger i = 0; i < count; i++) {
        UIViewController *viewController = [self.childViewControllers objectAtIndex:i];

		CGRect rect = viewController.view.frame;
		rect.origin.x = cx;
		rect.origin.y = 0;
		viewController.view.frame = rect;
        
		[scrollView addSubview:viewController.view];
        
		cx += scrollView.frame.size.width;
	}
    
	[scrollView setContentSize:CGSizeMake(cx, scrollView.bounds.size.height)];
}

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {
    
    [self stopAudioPlaying];
    
    if (self.childViewControllers.count > 0) {
        self.pageIndex = 0;
        for (UIViewController *vC in self.childViewControllers) {
            [vC willMoveToParentViewController:nil];
            [vC removeFromParentViewController];
        }
    }
    
    for (UIViewController *vC in viewControllers) {
        [self addChildViewController:vC];
        [vC didMoveToParentViewController:self];
    }
    
    if (self.scrollView)
        [self reloadPages];
}

- (void)stopAudioPlaying
{
    MPMoviePlayerController *moviePlayer = [[MPMoviePlayerController alloc]
                                            initWithContentURL:[NSURL URLWithString:@"www.qq.com"]];
    [moviePlayer play];
}

@end
