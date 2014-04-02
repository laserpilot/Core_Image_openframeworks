#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
   // ofSetFrameRate(30);
    outWidth  = ofGetViewportWidth();
    outHeight = ofGetViewportHeight();
    ofEnableSmoothing();
    ofBackground(0);
    ofNoFill();
    ofSetLineWidth(4);
    
    // Setup a framebuffer for the drawing. Perhaps there is some way to do this
    // without a framebuffer, but this is the only way I could figure out how to
    // enable grabbing an OpenGL texture to pass to the CoreImage filter
    sourceFbo.allocate(outWidth, outHeight, GL_RGBA32F_ARB); //32-bit framebuffer for smoothness
    
    // SETUP THE CORE IMAGE CONTEXT, FILTERS, ETC
    // The appended .autorelease methods should auto cleanup the memory at exit.
    // Use a generic RGB color space:
    genericRGB = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    // Create the pixel format attributes... The Core Image Guide for processing images says:
    // "It’s important that the pixel format for the context includes the NSOpenGLPFANoRecovery constant as an
    // attribute. Otherwise Core Image may not be able to create another context that shares textures with this one."
    NSOpenGLPixelFormatAttribute attr[] = {
        NSOpenGLPFAAccelerated,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAColorSize, 32,
        0
    };
    CGColorSpaceRelease(genericRGB);
    // Setup the pixel format object:
    pf=[[NSOpenGLPixelFormat alloc] initWithAttributes:attr].autorelease;
    // Setup the core image context, tied to the OF Open GL context:
    glCIcontext = [CIContext contextWithCGLContext: CGLGetCurrentContext()
                                       pixelFormat: CGLPixelFormatObj(pf)
                                        colorSpace: genericRGB
                                           options: nil].autorelease;
    // Setup a Gaussian Blur filter:
    blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"].autorelease;
    

    
    // Supporting stuff
    texSize = CGSizeMake(outWidth, outHeight);
    inRect = CGRectMake(0,0,outWidth,outHeight);
    outRect = CGRectMake(0,0,outWidth,outHeight);
    
    NSArray *properties = [CIFilter filterNamesInCategory:
                           kCICategoryBuiltIn];
    NSLog(@"%@", properties);
    for (NSString *filterName in properties) {
        CIFilter *fltr = [CIFilter filterWithName:filterName];
        NSLog(@"%@", [fltr attributes]);
    }
    
}



//--------------------------------------------------------------
void ofApp::update(){
    
    ofSetWindowTitle(ofToString(ofGetFrameRate()));
   
    sourceFbo.begin();
    
    // For feedback fun, let's not clear the Fbo after the first frame
    if(ofGetKeyPressed(' ')) {
        ofClear(0);
    }
    // Draw circle
    ofSetColor(20, 130, 250);
    ofCircle(outWidth/2,outHeight/2,10+(ofGetFrameNum()%40)*6);
    
    // Get the texture ID of the fbo:
    tex = sourceFbo.getTextureReference().texData.textureID;
    // set the CI Image to link with the Fbo texture
    inputCIImage = [CIImage imageWithTexture:tex
                                        size:texSize
                                     flipped:NO
                                  colorSpace:genericRGB];
    // Blur filter
    [blurFilter setValue:inputCIImage forKey:@"inputImage"];
    [blurFilter setValue:[NSNumber numberWithFloat: 4+4*sin(ofGetElapsedTimef())] forKey:@"inputRadius"];
    blurredCIImage = [blurFilter valueForKey:@"outputImage"];
    // Draw it
    ofSetColor(255);
    [glCIcontext drawImage:blurredCIImage
                    inRect:outRect
                  fromRect:inRect];
    
    sourceFbo.end();
}

//--------------------------------------------------------------
void ofApp::draw(){
    sourceFbo.draw(0,0);
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){

}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){

}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y ){

}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){

}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg){

}

//--------------------------------------------------------------
void ofApp::dragEvent(ofDragInfo dragInfo){ 

}
