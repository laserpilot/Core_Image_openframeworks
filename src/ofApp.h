#pragma once
//  *****************************************************************
//  Demonstration of using Max OSX Core Image filters in an
//  Open Frameworks 0.7.4 project
//
//  Bret Battey / BatHatMedia.com
//  August 4, 2013
//  *****************************************************************

#include "ofMain.h"
#import <QuartzCore/QuartzCore.h>  // One way to get the CI classes
#import <QuartzCore/CoreImage.h>

//#import <QuartzCore/QuartzCore.h>


class ofApp : public ofBaseApp{
    
public:
    void setup();
    void update();
    void draw();
    
    void keyPressed  (int key);
    void keyReleased(int key);
    void mouseMoved(int x, int y );
    void mouseDragged(int x, int y, int button);
    void mousePressed(int x, int y, int button);
    void mouseReleased(int x, int y, int button);
    void windowResized(int w, int h);
    void dragEvent(ofDragInfo dragInfo);
    void gotMessage(ofMessage msg);
    
    // Basics
    int     outWidth, outHeight;
    ofFbo   sourceFbo;
    
    
    // Core Image
    CGLContextObj   CGLContext;
    NSOpenGLPixelFormatAttribute*   attr;
    NSOpenGLPixelFormat*    pf;
    CGColorSpaceRef genericRGB;
    CIContext*  glCIcontext;
    CIImage*    inputCIImage;
    CIFilter*   blurFilter;
    CIFilter* bloomFilter;
    CIFilter* comicFilter;
    CIFilter* crystalFilter;
    CIFilter* edgeFilter;
    CIFilter* hueFilter;
    CIFilter* torusFilter;
    CIFilter* lineFilter;
    CIImage*    filterCIImage;
    CGSize      texSize;
    GLint       tex;
    CGRect      outRect;
    CGRect      inRect;
    
    int filterNum;
    
    
};