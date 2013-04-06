//
//  AllArticleViewController.m
//  DreamingNews
//
//  Created by cg on 12-10-9.
//  Copyright (c) 2012年 Dreaming Team. All rights reserved.
//

#import "AllArticleViewController.h"
#import "MobClick.h"
#import "GlobalDef.h"
#import "StringUtils.h"
#import "ZStatus.h"
#import "DreamingAPI.h"
#import "ZAppDelegate.h"
#import "UIImageView+WebCache.h"
#import "MainViewController.h"
#import "SettingViewController.h"
#import "UserAccount.h"
#import "UserLoginViewController.h"
#import "UserLoginViewController_iPad.h"

@interface AllArticleViewController () {

    //广告条
    BOOL adPageControlIsChangingPage;
}

//广告条
@property (nonatomic, retain) UIScrollView *adScrollView;
@property (nonatomic, retain) UIPageControl* adPageControl;

@property (nonatomic, retain) NSMutableArray *appList;

@end



@implementation AllArticleViewController

@synthesize delegate;
@synthesize adScrollView, adPageControl;
@synthesize appList;


- (void)dealloc {
    
    [[RKClient sharedClient].requestQueue cancelRequestsWithDelegate:self];
    
    self.delegate = nil;
    
    self.adScrollView = nil;
    self.adPageControl = nil;
    
    self.appList = nil;
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    
    UIImageView *topBar = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 46)] autorelease];
    [topBar setImage:[UIImage imageNamed:@"topbar_background@2x"]];
    [self.view addSubview:topBar];
    
    UIButton *topBarLeftButton = [[[UIButton alloc] initWithFrame:CGRectMake(6, 10, 50, 30)] autorelease];
    [topBarLeftButton setBackgroundImage:[UIImage imageNamed:@"back@2x"] forState:UIControlStateNormal];
    [topBarLeftButton addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:topBarLeftButton];
    
    UIButton  *topBarRightButton = [[[UIButton alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 56, 10, 50, 30)]autorelease];
    [topBarRightButton setBackgroundImage:[UIImage imageNamed:@"setting@2x"] forState:UIControlStateNormal];
    [topBarRightButton addTarget:self action:@selector(showSettingView:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:topBarRightButton];
    
    UIImageView *backgroundImageView = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 46, SCREEN_WIDTH, 504)] autorelease];
    [backgroundImageView setImage:[UIImage imageNamed:@"register_page_bg@2x"]];
    [self.view addSubview:backgroundImageView];
    [self.view sendSubviewToBack:backgroundImageView];
    
    [self requestApps];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}  

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)getArticleList:(NSInteger)maxId length:(NSInteger)length useCacheFirst:(BOOL)useCacheFirst
{
    [DreamingAPI getUserTimeline:@"dota" maxId:maxId length:length delegate:self useCacheFirst:useCacheFirst];
    
    return YES;
}

- (void)requestApps
{
    NSDate *lastNewAppCheckDate = [[NSUserDefaults standardUserDefaults] objectForKey:kLastNewAppCheckDate];
    NSTimeInterval sec = [[NSDate date] timeIntervalSinceDate:lastNewAppCheckDate];
    
    //5天后向服务器请求最新App数据
    if (sec > 5*24*60*60)
    {
        [DreamingAPI getGoodApps:self useCacheFirst:NO];
    }
    else
    {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:kAdBarClosed])
            [DreamingAPI getGoodApps:self useCacheFirst:YES];
    }
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
    
    NSString *string = [objectLoader.URL absoluteString];
    
    if ([string hasPrefix:[NSString stringWithFormat:@"%@%@",MAIN_PATH,APPS_LIST]])
    {
        if ([objects count] == 0)
            return;
        
        self.appList = [[[NSMutableArray alloc] init] autorelease];
        
        for (ZStatus *app in objects)
        {
            if (![app.text isEqualToString:@"电竞视角"])
                [self.appList addObject:app];
        }
        
        if (!objectLoader.response.wasLoadedFromCache) {
            
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastNewAppCheckDate];
        }
        
        [self addAdScrollView];
        
        return;
    }
    
    [super objectLoader:objectLoader didLoadObjects:objects];
    
    if (!objectLoader.response.wasLoadedFromCache) {
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastUpdateDate];
    }
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    
    NSString *string = [objectLoader.URL absoluteString];
    
    if ([string hasPrefix:[NSString stringWithFormat:@"%@%@",MAIN_PATH,APPS_LIST]])
        return;
    
    [super objectLoader:objectLoader didFailWithError:error];
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
    
    NSString *string = [request.URL absoluteString];
    
    if ([string hasPrefix:[NSString stringWithFormat:@"%@%@",MAIN_PATH,APPS_LIST]])
        return;
    
    [super request:request didFailLoadWithError:error];
}

- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader *)objectLoader {
    
    NSString *string = [objectLoader.URL absoluteString];
    
    if ([string hasPrefix:[NSString stringWithFormat:@"%@%@",MAIN_PATH,APPS_LIST]])
        return;
    
    [super objectLoaderDidLoadUnexpectedResponse:objectLoader];
}

- (void)requestDidTimeout:(RKRequest *)request {
    
    NSString *string = [request.URL absoluteString];
    
    if ([string hasPrefix:[NSString stringWithFormat:@"%@%@",MAIN_PATH,APPS_LIST]])
        return;
    
    [super requestDidTimeout:request];
}

- (void)addAdScrollView {
    
    int posterCount = [self.appList count];
    
    if (posterCount == 0)
        return;
    
    CGRect posterRect = CGRectMake(0, 0, SCREEN_WIDTH, AD_BAR_HEIGHT * SCREEN_WIDTH / 320);
    CGRect pageControlRect = CGRectMake(SCREEN_WIDTH - 126, AD_BAR_HEIGHT * SCREEN_WIDTH / 320 - 24, 126, 26);
    
    UIView *adView = [[[UIView alloc] initWithFrame:posterRect] autorelease];
    self.adScrollView = [[[UIScrollView alloc] initWithFrame:posterRect] autorelease];
    self.adPageControl = [[[UIPageControl alloc] initWithFrame:pageControlRect] autorelease];
    
    self.adScrollView.delegate = self;
    self.adScrollView.backgroundColor = CELL_BACKGROUND;
    self.adScrollView.canCancelContentTouches = NO;
    self.adScrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    self.adScrollView.clipsToBounds = YES;
    self.adScrollView.scrollEnabled = YES;
    self.adScrollView.pagingEnabled = YES;
    
    self.adScrollView.scrollsToTop = NO;
    
    self.adPageControl.backgroundColor = [UIColor clearColor];
    
    if ([UIPageControl instancesRespondToSelector:@selector(setPageIndicatorTintColor:)])
    {
        self.adPageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
        self.adPageControl.currentPageIndicatorTintColor = [UIColor darkGrayColor];
    }
    
    [adView addSubview:self.adScrollView];
    [adView addSubview:self.adPageControl];
    
    CGFloat cx = 0;
    for (int i = 1; i <= posterCount; i++)
    {
        ZStatus *app = [self.appList objectAtIndex:i - 1];
        
        UIImageView *imageView = [[[UIImageView alloc] initWithFrame:
                                   CGRectMake(cx, 0, SCREEN_WIDTH, AD_BAR_HEIGHT * SCREEN_WIDTH / 320)] autorelease];
        
        NSString *imageUrl = [ZStatus getCoverImageUrl:app];
        
        [imageView setImageWithURL:[NSURL URLWithString:imageUrl] placeholderImage:nil];
        
        UIButton *imageButton = [[[UIButton alloc] initWithFrame:
                                  CGRectMake(cx, 0, SCREEN_WIDTH, AD_BAR_HEIGHT * SCREEN_WIDTH / 320)] autorelease];
        [imageButton addTarget:self action:@selector(imageButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
        [imageButton setTag:300 + i]; //Tag: 300+
        
        [self.adScrollView addSubview:imageView];
        [self.adScrollView addSubview:imageButton];
        
        cx += self.adScrollView.frame.size.width;
    }
    
    UIButton *closeButton = [[[UIButton alloc] initWithFrame:
                              CGRectMake(SCREEN_WIDTH - 28,
                                         (AD_BAR_HEIGHT * SCREEN_WIDTH / 320 - 20) / 2,
                                         20,
                                         20)] autorelease];
    [closeButton setBackgroundImage:[UIImage imageNamed:@"ad_close@2x"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(adCloseButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [adView addSubview:closeButton];
    
    self.baseTableView.tableHeaderView = adView;
    
    self.adPageControl.numberOfPages = posterCount;
    [self.adScrollView setContentSize:CGSizeMake(cx, self.adScrollView.bounds.size.height)];
}

#pragma mark -action

- (IBAction)back:(id)sender {
    
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)showSettingView:(id)sender {
    
    if ([UserAccount getUserId]) {
        
        SettingViewController *settingVC = [[[SettingViewController alloc] init] autorelease];
        [self presentModalViewController:settingVC animated:YES];
    }
    else {
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {

            UserLoginViewController *userLoginVC = [[[UserLoginViewController alloc] init]autorelease];
            [self presentModalViewController:userLoginVC animated:YES];
        } 
        else {
            UserLoginViewController_iPad *userLoginVC = [[[UserLoginViewController_iPad alloc] init]autorelease];
            [self presentModalViewController:userLoginVC animated:YES];
        }
    }
}

- (void)processStatusClickedAction:(NSInteger)row
{
    NSMutableArray *articleArray = [[[NSMutableArray alloc] init] autorelease];

    for (ZStatus* status in self.statusItems)
    {
        [articleArray addObject:status];
    }

    if ([self.delegate respondsToSelector:@selector(showArticles:articleIndex:)]) {
        
        [self.delegate showArticles:articleArray articleIndex:row];
    }

    [self back:nil];
}

- (void)imageButtonDidClick:(id)sender
{
    UIButton *clickedButton = sender;
    int tagNumber = [clickedButton tag];
    
    int index = tagNumber - 300;
    
    ZStatus *app = [self.appList objectAtIndex:index - 1];
    
    NSURL *url = [NSURL URLWithString:[ZStatus getAppStoreUrl:app]];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)adCloseButtonDidClick:(id)sender
{
    [self.baseTableView.tableHeaderView removeFromSuperview];
    self.baseTableView.tableHeaderView = nil;
    self.adScrollView = nil;
    self.adPageControl = nil;
    self.appList = nil;
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kAdBarClosed];
}


#pragma mark -
#pragma mark UIScrollViewDelegate stuff
- (void)scrollViewDidScroll:(UIScrollView *)_scrollView
{
    if (self.adScrollView == _scrollView)
    {
        if (adPageControlIsChangingPage) {
            return;
        }
        
        /*
         *    We switch page at 50% across
         */
        CGFloat pageWidth = _scrollView.frame.size.width;
        int page = floor((_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
        self.adPageControl.currentPage = page;
    }
    
    [super scrollViewDidScroll:_scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)_scrollView
{
    if (self.adScrollView == _scrollView)
    {
        adPageControlIsChangingPage = NO;
    }
}

#pragma mark -
#pragma mark PageControl stuff
- (IBAction)changePage:(id)sender
{
    /*
     *    Change the scroll view
     */
    CGRect frame = self.adScrollView.frame;
    frame.origin.x = frame.size.width * self.adPageControl.currentPage;
    frame.origin.y = 0;
    
    [self.adScrollView scrollRectToVisible:frame animated:YES];
    
    /*
     *    When the animated scrolling finishings, scrollViewDidEndDecelerating will turn this off
     */
    adPageControlIsChangingPage = YES;
}


@end
