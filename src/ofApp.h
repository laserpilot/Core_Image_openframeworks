#pragma once
//  *****************************************************************
//  Demonstration of using Max OSX Core Image filters in an
//  Open Frameworks 0.7.4 project
//
//  Bret Battey / BatHatMedia.com
//  August 4, 2013
//  *****************************************************************
//
//  Expanded example by Blair Neal
//  www.blairneal.com
//  OF 0.8.0 - OSX 10.8.5
//  4/7/2014

#include "ofMain.h"
#import <QuartzCore/QuartzCore.h>  // One way to get the CI classes



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
    ofFbo   bgFbo;
    
    
    
    // Core Image
    CGLContextObj   CGLContext;
    NSOpenGLPixelFormatAttribute*   attr;
    NSOpenGLPixelFormat*    pf;
    CGColorSpaceRef genericRGB;
    CIContext*  glCIcontext;
    CIImage*    inputCIImage;
    CIImage*    inputBGCIImage;
    CIFilter*   blurFilter;
    CIFilter* bloomFilter;
    CIFilter* comicFilter;
    CIFilter* crystalFilter;
    CIFilter* edgeFilter;
    CIFilter* hueFilter;
    CIFilter* torusFilter;
    CIFilter* lineFilter;
    CIFilter* colorControls;
    CIFilter* boxBlurFilter;
    CIFilter* kaleidoFilter;
    CIFilter* glideFilter;
    CIFilter* pinchFilter;
    CIFilter* falseColorFilter;
    CIFilter* addFilter;
    CIFilter* bumpFilter;
    CIFilter* twirlFilter;
    CIFilter* glassFilter;
    CIFilter* halftoneFilter;
    CIFilter* hexFilter;
    CIFilter* rippleFilter;
    CIFilter* multiplyFilter;
    CIImage*    filterCIImage;
    CGSize      texSize;
    GLint       tex, tex2;
    CGRect      outRect;
    CGRect      inRect;
    
    int filterNum;
    string filterName;
    
    ofVideoGrabber cam;
    
    bool camActivate;
    
    
};