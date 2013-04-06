//
//  RTTableViewCell.m
//  Dreaming
//
//  Created by Cube on 11-5-5.
//  Copyright 2011 Dreaming Team. All rights reserved.
//

#import "RTTableViewCell.h"
#import "UIImageView+WebCache.h"
#import <QuartzCore/QuartzCore.h>

#import "StringUtils.h"
#import "GlobalDef.h"

@implementation RTTableViewCell


static UIImage* defaultCoverImage;
static UIImage* defaultBackgroundImage;


@synthesize descriptionLabel = _descriptionLabel;

@synthesize coverImageView = _coverImageView;

@synthesize videoButton = _videoButton;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString*)identifier {
	if (self = [super initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:identifier]) {
	}
	
	return self;
}


- (void)setDataSource:(id)data
{
    if (data == nil) 
        return;
    
    ZStatus *status = data;
    [self setBackgroundImage:nil];
    [self setDescription:status.text];
}


+ (UIImage*)getDefaultCoverImage {
    
    if (defaultCoverImage == nil) {
        defaultCoverImage = [[UIImage imageNamed:@"DefaultCover.png"] retain];
    }
    
    return defaultCoverImage;
}


+ (UIImage*)getDefaultBackgroundImage {
    
    if (defaultBackgroundImage == nil) {
        NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"cell_background@2x" ofType:@"png"];
        
        if ([UIImage instancesRespondToSelector:@selector(resizableImageWithCapInsets:resizingMode:)]) {
            defaultBackgroundImage = [[UIImage imageWithContentsOfFile:imagePath] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 100, 100) resizingMode:UIImageResizingModeTile];
            
            [defaultBackgroundImage retain];
        }
        else {
            defaultBackgroundImage = [[UIImage imageWithContentsOfFile:imagePath]
                                      stretchableImageWithLeftCapWidth:0.0 topCapHeight:50.0];
            
            [defaultBackgroundImage retain];
        }
    }
    
    return defaultBackgroundImage;
}


- (void)setCoverImageUrl:(NSString *)url tagId:(NSInteger)tagId target:(id)target action:(SEL)selector
{
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] init];
        
        [self.contentView addSubview:_coverImageView];
        
        [_coverImageView release];
    }
    
    [_coverImageView setImageWithURL:[NSURL URLWithString:url] 
                    placeholderImage:[RTTableViewCell getDefaultCoverImage]];
}


- (void)setVideoUrl:(NSString *)url tagId:(NSInteger)tagId target:(id)target action:(SEL)selector
{
    if ([url length] == 0)
        return;
    
    if (!_videoButton) {
        _videoButton = [[UIButton alloc] init];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom ] == UIUserInterfaceIdiomPhone) {
            [self.videoButton setImage:[UIImage imageNamed:@"video_button_timeline@2x.png"] forState:UIControlStateNormal];
        }
        else
        {
            [self.videoButton setImage:[UIImage imageNamed:@"video_button_timeline@2x.png"] forState:UIControlStateNormal];
        }
        
        if (target != nil && selector != nil)
            [_videoButton addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
        
        [self.contentView addSubview:_videoButton];
    }
    
    _videoButton.tag = tagId;
}

- (void)setDescription:(NSString *)newDescription
{
    if (!_descriptionLabel) {
		_descriptionLabel = [[UILabel alloc] init];
        _descriptionLabel.font = English_font_des;
		_descriptionLabel.textColor = ZBSTYLE_tableSubTextColor;
		_descriptionLabel.highlightedTextColor = ZBSTYLE_tableSubTextColor;
		_descriptionLabel.textAlignment = UITextAlignmentLeft;
		_descriptionLabel.contentMode = UIViewContentModeTop;
		_descriptionLabel.lineBreakMode = UILineBreakModeTailTruncation;
		_descriptionLabel.numberOfLines = 0;
		
		[self.contentView addSubview:_descriptionLabel];
	}
    
    _descriptionLabel.text = newDescription ? newDescription : @"";
}


- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    
    _descriptionLabel.backgroundColor = [UIColor clearColor];
}


- (void)setBackgroundImage:(UIImage *)theImage
{
    UIImage *backgroundImage;
    
    if (theImage == nil) {

        backgroundImage = [RTTableViewCell getDefaultBackgroundImage];
    }
    else {
        backgroundImage = theImage;
    }
    
    if (self.backgroundView == nil) {
        self.backgroundView = [[[UIImageView alloc] initWithImage:backgroundImage] autorelease];
        self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundView.frame = self.bounds;
    }
}


+ (CGFloat)rowHeightForObject:(id)object {

    return 78;
}

#pragma mark -
#pragma mark UIView

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [_coverImageView cancelCurrentImageLoad];
    
    _coverImageView.image = nil;
    
    [_videoButton removeFromSuperview];
    
    RELEASE_SAFELY(_videoButton);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    [_coverImageView setClipsToBounds:YES];
    _coverImageView.frame = CGRectMake(kTableCellMargin,
                                       kTableCellMargin,
                                       COVER_IMAGE_WIDTH,
                                       COVER_IMAGE_HEIGHT);
    
    //设置_videoButton的坐标
    _videoButton.frame = CGRectMake(kTableCellMargin,
                                    kTableCellMargin,
                                    COVER_IMAGE_WIDTH,
                                    COVER_IMAGE_HEIGHT);
    
    //设置_descriptionLabe的坐标
    _descriptionLabel.frame = CGRectMake(COVER_IMAGE_WIDTH + 2*kTableCellMargin, kTableCellMargin,
                                         SCREEN_WIDTH - COVER_IMAGE_WIDTH - 3*kTableCellMargin,
                                         78 - 2*kTableCellMargin);
}


- (void)dealloc {
    
    RELEASE_SAFELY(_descriptionLabel);
    
    RELEASE_SAFELY(_coverImageView);
    
    RELEASE_SAFELY(_videoButton);
    
    [super dealloc];
}

@end
