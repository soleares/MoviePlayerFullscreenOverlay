//
//  VideoViewController.m
//  MoviePlayerFullscreenSubview
//
//  Created by Jesse Wolff on 1/8/14.
//  Copyright (c) 2014 Soleares. All rights reserved.
//

#import "VideoViewController.h"

@interface VideoViewController ()
@property (nonatomic, strong) NSURL *contentURL;
@property (nonatomic, strong) UIView *fullscreenOverlay;
@end

@implementation VideoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString *path = [[NSBundle mainBundle] pathForResource:@"big_buck_bunny" ofType:@"mp4"];
    self.contentURL = [NSURL fileURLWithPath:path];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [self removeMovieNotificationHandlers];
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // viewWillAppear/viewDidAppear is called when exiting fullscreen on iOS 6+.
    if (!self.moviePlayerController.fullscreen) {
        [self createAndConfigureMoviePlayer];
        
        MPMoviePlayerController *player = self.moviePlayerController;
        if (self.contentURL) {
            player.contentURL = self.contentURL;
            [player prepareToPlay];
            [self resizeMovieView];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // viewWillDisappear/viewDidDisappear is called when entering fullscreen on iOS 6+.
    if (!self.moviePlayerController.fullscreen) {
        [self removeMovieViewFromViewHierarchy];
        [self deleteMoviePlayerAndNotificationObservers];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
	
	[self resizeMovieView];
}

- (void)resizeMovieView
{
    // Size the non-fullscreen movie view to 80% of the parent view.
    // This is for example purposes only to show a distinction between embedded and fullscreen modes.
    CGRect bounds = self.view.bounds;
    CGRect movieRect = CGRectInset(bounds,
                                   CGRectGetWidth(bounds) * .1,
                                   CGRectGetHeight(bounds) * .1);
    
	self.moviePlayerController.view.frame = movieRect;
}

#pragma mark - Setters and Getters

- (UIWindow *)appWindow
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (!window) {
        window = ([UIApplication sharedApplication].windows)[0];
    }
    
    return window;
}

#pragma mark - Create and Configure Movie Player

- (void)createAndConfigureMoviePlayer
{
    MPMoviePlayerController *player = [[MPMoviePlayerController alloc] init];
    
    if (player) {
        self.moviePlayerController = player;
		
        [self installMovieNotificationObservers];
        
        player.movieSourceType = MPMovieSourceTypeFile;
        player.shouldAutoplay = NO;
        player.allowsAirPlay = YES;
        
        [self.view addSubview:player.view];
    }
}

- (void)installMovieNotificationObservers
{
    MPMoviePlayerController *player = self.moviePlayerController;
    
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterFullscreen:)
                                                 name:MPMoviePlayerDidEnterFullscreenNotification
                                               object:player];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willExitFullscreen:)
                                                 name:MPMoviePlayerWillExitFullscreenNotification
                                               object:player];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didExitFullscreen:)
                                                 name:MPMoviePlayerDidExitFullscreenNotification
                                               object:player];
}

#pragma mark - Movie Notification Handlers

- (void)moviePlayBackDidFinish:(NSNotification *)notification
{
    NSNumber *reason = [notification userInfo][MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
	switch ([reason integerValue]) {
		case MPMovieFinishReasonPlaybackEnded:
			break;
		case MPMovieFinishReasonPlaybackError:
			break;
		case MPMovieFinishReasonUserExited:
            [self removeMovieViewFromViewHierarchy];
			break;
		default:
			break;
	}
}

- (void)didEnterFullscreen:(NSNotification *)notification
{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(layoutFullscreenOverlayForOrientation:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
	
    // This needs to be called in the next run loop for it to work properly in iOS 6+
    [self performSelector:@selector(addFullscreenOverlayForCurrentInterfaceOrientation) withObject:nil afterDelay:0];
}

- (void)willExitFullscreen:(NSNotification*)notification
{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    
	// Remove the fullscreen overlay view
	if (self.fullscreenOverlay) {
		[self.fullscreenOverlay removeFromSuperview];
		self.fullscreenOverlay = nil;
	}
}

- (void)didExitFullscreen:(NSNotification*)notification
{
	// Remove the fullscreen overlay view
    // This was called already in willExitFullscreen: but we'll call it again to ensure that it's removed.
	if (self.fullscreenOverlay) {
		[self.fullscreenOverlay removeFromSuperview];
		self.fullscreenOverlay = nil;
	}
}

#pragma mark - Fullscreen Overlay

- (void)addFullscreenOverlayForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Get the screen dimensions based on the orientation
    CGRect screenRect = [UIScreen mainScreen].bounds;
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        CGRect temp = CGRectZero;
        temp.size.width = screenRect.size.height;
        temp.size.height = screenRect.size.width;
        screenRect = temp;
    }
    
    CGFloat screenWidth = CGRectGetWidth(screenRect);
    CGFloat screenHeight = CGRectGetHeight(screenRect);
    
	// Create a sample overlay view centered the fullscreen view
    CGFloat overlayHeight = 100;
    CGFloat overlayWidth = 200;
	CGRect overlayRect = CGRectMake(screenWidth/2.0 - overlayWidth/2.0,
                                    screenHeight/2.0 - overlayHeight/2.0,
                                    overlayWidth, overlayHeight);

	UIView *fullscreenOverlay = [[UIView alloc] initWithFrame:overlayRect];
    fullscreenOverlay.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.5];
	
	// Rotation and position the view based on the orientation
    // If your overlay isn't centered you'll need to adjust the CGAffineTransformTranslate
    // transform for PortraitUpsideDown, LandscapeLeft and LandscapeRight orientations.
	CGAffineTransform transform = CGAffineTransformIdentity;
    
	switch (interfaceOrientation) {
		case UIInterfaceOrientationPortrait:
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			transform = CGAffineTransformRotate(transform, M_PI);
			break;
		case UIInterfaceOrientationLandscapeLeft:
			transform = CGAffineTransformRotate(transform, -M_PI_2);
			transform = CGAffineTransformTranslate(transform,
                                                   -(screenWidth/2.0 - screenHeight/2.0),
                                                   -(screenWidth/2.0 - screenHeight/2.0));
			break;
		case UIInterfaceOrientationLandscapeRight:
			transform = CGAffineTransformRotate(transform, M_PI_2);
			transform = CGAffineTransformTranslate(transform,
												   screenWidth/2.0 - screenHeight/2.0,
                                                   screenWidth/2.0 - screenHeight/2.0);
			break;
		default:
			break;
	}
	
	[fullscreenOverlay setTransform:transform];
    
	[self.appWindow addSubview:fullscreenOverlay];
	self.fullscreenOverlay = fullscreenOverlay;
}

- (void)addFullscreenOverlayForCurrentInterfaceOrientation
{
    [self addFullscreenOverlayForInterfaceOrientation:self.interfaceOrientation];
}

- (void)layoutFullscreenOverlay
{
    UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    // If there's an overlay view, so remove it and add it in the new orientation
	if (self.fullscreenOverlay) {
		[self.fullscreenOverlay removeFromSuperview];
		self.fullscreenOverlay = nil;
		
        [self addFullscreenOverlayForInterfaceOrientation:statusBarOrientation];
    }
}

#pragma mark - UIDeviceOrientationDidChangeNotification Handler

- (void)layoutFullscreenOverlayForOrientation:(UIDeviceOrientation)orientation
{
    // This needs to be called in the next run loop for it to work properly in iOS 6+
    [self performSelector:@selector(layoutFullscreenOverlay) withObject:nil afterDelay:0];
}

#pragma mark - Remove Movie Player

- (void)removeMovieNotificationHandlers
{
    MPMoviePlayerController *player = self.moviePlayerController;
    
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:player];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerDidEnterFullscreenNotification object:player];
	[[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerWillExitFullscreenNotification object:player];
	[[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerDidExitFullscreenNotification object:player];
}

- (void)deleteMoviePlayerAndNotificationObservers
{
    [self removeMovieNotificationHandlers];
    
    // Need to nil the contentURL in iOS 5 otherwise the AVPlayerItem, AVURLAsset,
    // and other related objects don't get released.
    self.moviePlayerController.contentURL = nil;
    self.moviePlayerController = nil;
}

- (void)removeMovieViewFromViewHierarchy
{
    MPMoviePlayerController *player = self.moviePlayerController;
	[player.view removeFromSuperview];
}

@end
