# ImageGestureDemo
Sample iOS Xcode App (Objective C) that demonstrates how to pan, pinch, rotate and drag/resize a UIView with transforms and gestures.

* CGAffineTransform objects to do the View moving, resizing and rotating
* Storyboard linked gestures provide the UI

## Overview
This is a DEMO. It shows how to pan, pinch, rotate and drag/resize a UIImageView.

There is a background image and a foreground image.  Both images can be
panned, pinched and rotated, but only the foreground image can be resized
by dragging one of it's corners or it's sides.

**NOTE:**  Sure, much of this code could have been put into a subclass of UIView
or UIImageView.  But for simplicity and reference sake, all code and
methods are in one place, this ViewController subclass.  There is no
error checking at all.  App tested on an iPhone 6+ and an iPad gen3.

## Screenshot
<img src="https://github.com/ByteSlinger/ImageGestureDemo/blob/master/ImageGestureDemo/screenshot.png?raw=true" />

## Features
* allows an image to be resized with pan gesture by dragging corners and sides
* background image can be modified (pan, pinch, rotate)
* foreground image can be modified (pan, pinch, rotate, drag/resize)
* all image manipulation done within gestures linked from storyboard
* all finger touches on screen show with yellow circles
* when dragging, the touch circles turn to red (so you know when gestures start)
* double tap on foreground image resets it to original size and rotation
* double tap on background resets it and also resets the foreground image
* screen and image touch and size info displayed on screen
* uses CGAffineTransform objects for image manipulation
* uses UIGestureRecognizerStateBegan in gestures to save transforms (the secret sauce...)

## Known Issues
* when the image is rotated, determining if a touch is on a corner or side
does not work for large rotations.  Need to check touch points against
non rotated view frame and adjust accordingly.
* after rotations, pinch and resize can shrink image to invisibility despite
code attempts to prevent it.

## Prerequisites

The following was used to build and run this app:

* Mac OS X 10.13.5
* Apple Xcode Version 9.4.1 
* Apple Developer account

## Build and Deployment

I built and tested this on an iPad 3rd generation and an iPhone 6+.  I did not try any simulators.

## Code Highlights (the Secret Sauce...)

* Use gesture state UIGestureRecognizerStateBegan to save the initial transform of the image and then apply all translations and rotations on that transform.
* Use UIPanGestureRecognizer to resize an image when corners or sides are "dragged"
* Use custom translation adjustments to implement the drag/resizing functionality

## Author

* [ByteSlinger](https://github.com/ByteSlinger)

## License

This project is licensed under the MIT License: https://opensource.org/licenses/MIT
