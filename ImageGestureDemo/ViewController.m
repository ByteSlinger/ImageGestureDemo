//
//  ViewController.m
//  ImageGestureDemo
//
//  This is a DEMO. It shows how to pan, pinch, rotate and drag/resize a UIImageView.
//
//  There is a background image and a foreground image.  Both images can be
//  panned, pinched and rotated, but only the foreground image can be resized
//  by dragging one of it's corners or it's sides.
//
//  NOTE:  Sure, much of this code could have been put into a subclass of UIView
//         or UIImageView.  But for simplicity and reference sake, all code and
//         methods are in one place, this ViewController subclass.  There is no
//         error checking at all.  App tested on an iPhone 6+ and an iPad gen3.
//
//  Features:
//      - allows an image to be resized with pan gesture by dragging corners and sides
//      - background image can be modified (pan, pinch, rotate)
//      - foreground image can be modified (pan, pinch, rotate, drag/resize)
//      - all image manipulation done within gestures linked from storyboard
//      - all finger touches on screen show with yellow circles
//      - when dragging, the touch circles turn to red (so you know when gestures start)
//      - double tap on foreground image resets it to original size and rotation
//      - double tap on background resets it and also resets the foreground image
//      - screen and image touch and size info displayed on screen
//      - uses CGAffineTransform objects for image manipulation
//      - uses UIGestureRecognizerStateBegan in gestures to save transforms (the secret sauce...)
//
//  Known Issues:
//      - when the image is rotated, determining if a touch is on a corner or side
//        does not work for large rotations.  Need to check touch points against
//        non rotated view frame and adjust accordingly.
//      - after rotations, pinch and resize can shrink image to invisibility despite
//        code attempts to prevent it.
//
//  Created by ByteSlinger on 6/21/18.
//  Copyright © 2018 ByteSlinger. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (strong, nonatomic) IBOutlet UIImageView *foregroundImageView;
@property (strong, nonatomic) IBOutlet UILabel *screenInfoLabel;
@property (strong, nonatomic) IBOutlet UILabel *touchInfoLabel;
@property (strong, nonatomic) IBOutlet UILabel *imageInfoLabel;
@property (strong, nonatomic) IBOutlet UILabel *backgroundInfoLabel;
@property (strong, nonatomic) IBOutlet UILabel *changeInfoLabel;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *backgroundTapGesture;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *foregroundTapGesture;
@end

@implementation ViewController
CGRect originalImageFrame;
CGRect originalBackgroundFrame;
CGAffineTransform originalImageTransform;
CGAffineTransform originalBackgroundTransform;
NSMutableArray* touchCircles = nil;
DragType currentDragType = DRAG_OFF;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // set this to whatever your desired touch radius is
    touchRadius = 48;
    
    // In Storyboard this must have set to 1, then this seems to work ok
    // when setting the double tap here
    _foregroundTapGesture.numberOfTapsRequired = 2;
    _backgroundTapGesture.numberOfTapsRequired = 2;

    [self centerImageView:_foregroundImageView];
    
    originalImageFrame = _foregroundImageView.frame;
    originalBackgroundFrame = _backgroundImageView.frame;
    originalImageTransform = _foregroundImageView.transform;
    originalBackgroundTransform = _backgroundImageView.transform;

    _backgroundImageView.contentMode = UIViewContentModeCenter;
    _foregroundImageView.contentMode = UIViewContentModeScaleToFill;    // allow stretch
    [_backgroundImageView setUserInteractionEnabled:YES];
    [_backgroundImageView setMultipleTouchEnabled:YES];
    [_foregroundImageView setUserInteractionEnabled:YES];
    [_foregroundImageView setMultipleTouchEnabled:YES];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationChanged:)
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];
    
    [_touchInfoLabel setText:nil];
    [_changeInfoLabel setText:nil];
    [_imageInfoLabel setText:nil];
    [_backgroundInfoLabel setText:nil];
    
    touchCircles = [[NSMutableArray alloc] init];
}

- (void)viewDidAppear:(BOOL)animated {
    [self alert:APP_TITLE :INTRO_ALERT];
}

- (void) orientationChanged:(NSNotification *)note
{
    UIDevice * device = note.object;
    switch(device.orientation)
    {
        case UIDeviceOrientationPortrait:
            /* start special animation */
            break;
            
        case UIDeviceOrientationPortraitUpsideDown:
            /* start special animation */
            break;
            
        default:
            break;
    };
    
    [_screenInfoLabel setText:[NSString stringWithFormat:@"Screen: %.0f/%.0f",
                              self.view.frame.size.width,self.view.frame.size.height]];
}

//
// Update the info labels from the passed objects
//
- (void) updateInfo:(UIView *)imageView touch:(CGPoint)touch change:(CGPoint)change {
    NSString *label;
    UILabel *infoLabel;
    
    if (imageView == _foregroundImageView) {
        label = @"Image: %0.f/%0.f, %0.f/%0.f";
        infoLabel = _imageInfoLabel;
    } else {
        label = @"Background: %0.f/%0.f, %0.f/%0.f";
        infoLabel = _backgroundInfoLabel;
    }
    
    [infoLabel setText:[NSString stringWithFormat:label,
                              imageView.layer.frame.origin.x,
                              imageView.layer.frame.origin.y,
                              imageView.layer.frame.size.width,
                              imageView.layer.frame.size.height]];
    
    [_touchInfoLabel setText:[NSString stringWithFormat:@"Touch: %0.f/%.0f",
                              touch.x,touch.y]];
    
    [_changeInfoLabel setText:[NSString stringWithFormat:@"Change: %0.f/%.0f",
                               change.x,change.y]];
}

//
// Center the passed image frame within it's bounds
//
- (void)centerImageView:(UIImageView *)imageView {
    CGSize boundsSize = self.view.bounds.size;
    CGRect frameToCenter = imageView.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    imageView.frame = frameToCenter;
}

//
// Remove all touch circles
//
- (void)removeTouchCircles {
    [touchCircles makeObjectsPerformSelector: @selector(removeFromSuperview)];
    [touchCircles removeAllObjects];
}

//
// Draw a circle around the passed point where the user has touched the screen
//
- (void)drawTouchCircle:(UIView *)view fromCenter:(CGPoint)point ofRadius:(float)radius {
    CGRect frame = CGRectMake(point.x - view.frame.origin.x - radius,
                              point.y - view.frame.origin.y - radius,
                              radius * 2, radius * 2);
    
    UIView *circle = [[UIView alloc] initWithFrame:frame];
    circle.alpha = 0.5;
    circle.layer.cornerRadius = radius;
    circle.backgroundColor = currentDragType == DRAG_OFF ? [UIColor yellowColor] : [UIColor redColor];
    [circle.layer setBorderWidth:1.0];
    [circle.layer setBorderColor:[[UIColor blackColor]CGColor]];
    
    [view addSubview:circle];
    
    [touchCircles addObject:circle];
}

//
// Draw a touch circle for the passed user touch
//
- (void)handleTouchEvent:(UIView *) view
                 atPoint:(CGPoint) point
                forState:(UIGestureRecognizerState) state
                   clear:(Boolean) clear {
    //NSLog(@"handleTouchEvent");
    if (clear) {
        [self removeTouchCircles];
    }

    if (state == UIGestureRecognizerStateEnded) {
        [self removeTouchCircles];
    } else {
        [self drawTouchCircle:self.view fromCenter:point ofRadius:touchRadius];
    }
    
    [_touchInfoLabel setText:[NSString stringWithFormat:@"Touch: %0.f/%.0f",
                              point.x,point.y]];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    //NSLog(@"touchesBegan");
    [self removeTouchCircles];
    
    NSSet *allTouches = [event allTouches];
    NSArray *allObjects = [allTouches allObjects];
    for (int i = 0;i < [allObjects count];i++)
    {
        UITouch *touch = [allObjects objectAtIndex:i];
        CGPoint location = [touch locationInView: self.view];
        [self handleTouchEvent:touch.view atPoint:location forState:UIGestureRecognizerStateBegan clear:NO];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    //NSLog(@"touchesMoved");
    [self removeTouchCircles];
    
    NSSet *allTouches = [event allTouches];
    NSArray *allObjects = [allTouches allObjects];
    for (int i = 0;i < [allObjects count];i++)
    {
        UITouch *touch = [allObjects objectAtIndex:i];
        CGPoint location = [touch locationInView: self.view];
        [self handleTouchEvent:touch.view atPoint:location forState:UIGestureRecognizerStateChanged clear:NO];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    //NSLog(@"touchesEnded");
    [self removeTouchCircles];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    //NSLog(@"touchesCancelled");
    [self removeTouchCircles];
}

//
// Double tap resets passed image.  If background image, also reset foreground image.
//
- (IBAction)handleDoubleTap:(UITapGestureRecognizer *)recognizer {
    CGPoint touch = [recognizer locationInView: self.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan ||
        recognizer.state == UIGestureRecognizerStateChanged) {
        [self handleTouchEvent:recognizer.view atPoint:touch forState:recognizer.state clear:NO];
    } else {
        [self removeTouchCircles];
    }
    [self alert:@"Reset" :@"The Image has been Reset!"];
    
    CGRect frame = originalImageFrame;
    CGAffineTransform transform = originalImageTransform;
    
    if (recognizer.view == _backgroundImageView) {
        _foregroundImageView.transform = transform;
        _foregroundImageView.frame = frame;
        [self updateInfo:_foregroundImageView touch:touch change:CGPointZero];
        
        frame = originalBackgroundFrame;
        transform = originalBackgroundTransform;
    }
    
    recognizer.view.transform = transform;
    recognizer.view.frame = frame;
    [self updateInfo:recognizer.view touch:touch change:CGPointZero];
}

- (void) setDragType:(CGRect)frame withTouch:(CGPoint)touch {
    // the corners and sides of the current view frame
    CGRect topLeft = CGRectMake(frame.origin.x,frame.origin.y,
                                touchRadius, touchRadius);
    CGRect bottomLeft = CGRectMake(frame.origin.x,
                                   frame.origin.y + frame.size.height - touchRadius,
                                   touchRadius, touchRadius);
    CGRect topRight = CGRectMake(frame.origin.x + frame.size.width - touchRadius,
                                 frame.origin.y,
                                 touchRadius, touchRadius);
    CGRect bottomRight = CGRectMake(frame.origin.x + frame.size.width - touchRadius,
                                    frame.origin.y + frame.size.height - touchRadius,
                                    touchRadius, touchRadius);
    CGRect leftSide = CGRectMake(frame.origin.x,frame.origin.y,
                                 touchRadius, frame.size.height);
    CGRect rightSide = CGRectMake(frame.origin.x + frame.size.width - touchRadius,
                                  frame.origin.y,
                                  touchRadius, frame.size.height);
    CGRect topSide = CGRectMake(frame.origin.x,frame.origin.y,
                                frame.size.width, touchRadius);
    CGRect bottomSide = CGRectMake(frame.origin.x,
                                   frame.origin.y + frame.size.height - touchRadius,
                                   frame.size.width, touchRadius);
    
    if (CGRectContainsPoint(topLeft, touch)) {
        currentDragType = DRAG_TOPLEFT;
    } else if (CGRectContainsPoint(topRight, touch)) {
        currentDragType = DRAG_TOPRIGHT;
    } else if (CGRectContainsPoint(bottomLeft, touch)) {
        currentDragType = DRAG_BOTTOMLEFT;
    } else if (CGRectContainsPoint(bottomRight, touch)) {
        currentDragType = DRAG_BOTTOMRIGHT;
    } else if (CGRectContainsPoint(topSide, touch)) {
        currentDragType = DRAG_TOP;
    } else if (CGRectContainsPoint(bottomSide, touch)) {
        currentDragType = DRAG_BOTTOM;
    } else if (CGRectContainsPoint(leftSide, touch)) {
        currentDragType = DRAG_LEFT;
    } else if (CGRectContainsPoint(rightSide, touch)) {
        currentDragType = DRAG_RIGHT;
    } else if (CGRectContainsPoint(frame, touch)) {
        currentDragType = DRAG_CENTER;
    } else {
        currentDragType = DRAG_OFF; // touch point is not in the view frame
    }
}

//
// Return the unrotated size of the view
//
- (CGSize) getActualSize:(UIView *)view {
    CGSize result;
    //CGSize originalSize = view.frame.size;
    CGAffineTransform originalTransform = view.transform;
    float rotation = atan2f(view.transform.b, view.transform.a);
    
    // reverse rotation of current transform
    CGAffineTransform unrotated = CGAffineTransformRotate(view.transform, -rotation);
    
    view.transform = unrotated;
    
    // get the size of the "unrotated" view
    result = view.frame.size;
    
    // reset back to what it was
    view.transform = originalTransform;
    
    //NSLog(@"Size current = %0.f/%0.f, rotation = %0.2f, unrotated = %0.f/%0.f",
    //      originalSize.width,originalSize.height,
    //      rotation,
    //      result.width,result.height);
    
    return result;
}

//
// Resize or Pan an image on the ViewController View
//
- (IBAction)handleResize:(UIPanGestureRecognizer *)recognizer {
    static CGRect initialFrame;
    static CGAffineTransform initialTransform;
    static Boolean scaleIt = YES;
    
    // where the user has touched down
    CGPoint touch = [recognizer locationInView: self.view];
    
    //get the translation amount in x,y
    CGPoint translation = [recognizer translationInView:recognizer.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        initialFrame = recognizer.view.frame;
        initialTransform = recognizer.view.transform;
        [self setDragType:recognizer.view.frame withTouch:touch];
        scaleIt = YES;
    }
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        currentDragType = DRAG_OFF;
        scaleIt = NO;
        
        [self getActualSize:recognizer.view];
    } else { 
        // our new view frame - start with the initial one
        CGRect newFrame = initialFrame;
        
        // adjust the translation point according to where the user touched the image
        float tx = translation.x;
        float ty = translation.y;
        
        // resize by dragging a corner or a side
        if (currentDragType == DRAG_TOPLEFT) {
            tx = -translation.x;
            ty = -translation.y;
            newFrame.origin.x += translation.x;
            newFrame.origin.y += translation.y;
            newFrame.size.width -= translation.x;
            newFrame.size.height -= translation.y;
        } else if (currentDragType == DRAG_TOPRIGHT) {
            ty = -translation.y;
            newFrame.origin.y += translation.y;
            newFrame.size.width += translation.x;
            newFrame.size.height -= translation.y;
        } else if (currentDragType == DRAG_BOTTOMLEFT) {
            tx = -translation.x;
            newFrame.origin.x += translation.x;
            newFrame.size.width -= translation.x;
            newFrame.size.height += translation.y;
        } else if (currentDragType == DRAG_BOTTOMRIGHT) {
            // origin does not change
            newFrame.size.width += translation.x;
            newFrame.size.height += translation.y;
        } else if (currentDragType == DRAG_TOP) {
            tx = 0;
            newFrame.origin.y += translation.y;
            newFrame.size.height -= translation.y;
        } else if (currentDragType == DRAG_BOTTOM) {
            tx = 0;
            newFrame.size.height += translation.y;
        } else if (currentDragType == DRAG_LEFT) {
            tx = -translation.x;
            ty = 0;
            newFrame.origin.x += translation.x;
            newFrame.size.width -= translation.x;
        } else if (currentDragType == DRAG_RIGHT) {
            ty = 0;
            newFrame.size.width += translation.x;
        } else { //if (currentDragType == DRAG_CENTER) {
            newFrame.origin.x += translation.x;
            newFrame.origin.y += translation.y;
            scaleIt = NO;   // normal pan
        }
        
        // get the unrotated size of the view
        CGSize actualSize = [self getActualSize:recognizer.view];
        
        // make sure we can still touch the image
        if (actualSize.width < touchRadius * 2) {
            newFrame.size.width += touchRadius * 2;
            tx = 0; // stop resizing
        }
        if (actualSize.height < touchRadius * 2) {
            newFrame.size.height += touchRadius * 2;
            ty = 0; // stop resizing
        }
        
        // pan the image
        recognizer.view.transform = CGAffineTransformTranslate(initialTransform, tx, ty);
        
        if (scaleIt) {
            // the origin or size changed
            recognizer.view.frame = newFrame;
        }
    }
    
    [self updateInfo:recognizer.view touch:touch change:translation];
}

//
// Pan an image on the ViewController View
//
- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer {
    static CGAffineTransform initialTransform;
    
    // where the user has touched down
    CGPoint touch = [recognizer locationInView: self.view];
    
    //get the translation amount in x,y
    CGPoint translation = [recognizer translationInView:recognizer.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        initialTransform = recognizer.view.transform;
        currentDragType = DRAG_ON;
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        currentDragType = DRAG_OFF;
        [self getActualSize:recognizer.view];
    }
    recognizer.view.transform = CGAffineTransformTranslate(initialTransform, translation.x, translation.y);
    
    [self updateInfo:recognizer.view touch:touch change:translation];
}

//
// Pinch (resize) an image on the ViewController View
//
- (IBAction)handlePinch:(UIPinchGestureRecognizer *)recognizer {
    static CGSize initialSize;
    static CGAffineTransform initialTransform;
    
    // where the user has touched down
    CGPoint touch = [recognizer locationInView: self.view];
    
    //get the translation amount in x,y
    CGPoint change = CGPointMake(recognizer.view.transform.tx, recognizer.view.transform.ty);
    
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        initialSize = recognizer.view.frame.size;
        initialTransform = recognizer.view.transform;
        currentDragType = DRAG_ON;
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        currentDragType = DRAG_OFF;
        [self getActualSize:recognizer.view];
    }

    // make sure it stays visible
    float scale = recognizer.scale;
    float newWidth = initialSize.width * scale;
    float newHeight = initialSize.height * scale;
    
    // make sure we can still touch it
    if (newWidth > touchRadius * 2 && newHeight > touchRadius * 2) {
        // scale the image
        recognizer.view.transform = CGAffineTransformScale(initialTransform, scale, scale);
    }
    
    [self updateInfo:recognizer.view touch:touch change:change];
}

//
// Rotate an image on the ViewController View
//
- (IBAction)handleRotate:(UIRotationGestureRecognizer *)recognizer {
    static CGFloat initialRotation;
    static CGAffineTransform initialTransform;
    
    // where the user has touched down
    CGPoint touch = [recognizer locationInView: self.view];

    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        initialTransform = recognizer.view.transform;
        initialRotation = atan2f(recognizer.view.transform.b, recognizer.view.transform.a);
        currentDragType = DRAG_ON;
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        currentDragType = DRAG_OFF;
        [self getActualSize:recognizer.view];
    }
    
    recognizer.view.transform = CGAffineTransformRotate(initialTransform, recognizer.rotation);
    
    [self updateInfo:recognizer.view touch:touch change:CGPointMake(initialRotation, recognizer.rotation)];
}

//
// Prevent simultaneous gestures so my transforms don't get funky
// (may not be necessary ... )
//
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return NO;
}

//
// Spew a message to the user
//
- (void)alert:(NSString *) title :(NSString *)message {
    UIAlertController *alert = [UIAlertController
                                 alertControllerWithTitle: title
                                 message: message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okButton = [UIAlertAction
                                actionWithTitle:@"Ok"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                }];
    
    [alert addAction:okButton];
    
    [self presentViewController:alert animated:YES completion:nil];
}

@end
