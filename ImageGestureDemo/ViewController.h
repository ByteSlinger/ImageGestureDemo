//
//  ViewController.h
//  ImageGestureDemo
//
//  Created by ByteSlinger on 6/21/18.
//  Copyright © 2018 ByteSlinger. All rights reserved.
//

#import <UIKit/UIKit.h>
NSString *APP_TITLE = @"Image Gesture Demo";
NSString *INTRO_ALERT = @"\nDrag, Pinch and Rotate the Image!"
                        "\n\nYou can also Drag, Pinch and Rotate the background image."
                        "\n\nDouble tap an image to reset it";

float touchRadius = 48;   // max distance from corners to touch point

typedef NS_ENUM(NSInteger, DragType) {
    DRAG_OFF,
    DRAG_ON,
    DRAG_CENTER,
    DRAG_TOP,
    DRAG_BOTTOM,
    DRAG_LEFT,
    DRAG_RIGHT,
    DRAG_TOPLEFT,
    DRAG_TOPRIGHT,
    DRAG_BOTTOMLEFT,
    DRAG_BOTTOMRIGHT
};

@interface ViewController : UIViewController <UIGestureRecognizerDelegate>

//callback to process gesture events
- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer;
- (IBAction)handlePinch:(UIPinchGestureRecognizer *)recognizer;
- (IBAction)handleRotate:(UIRotationGestureRecognizer *)recognizer;
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
@end

