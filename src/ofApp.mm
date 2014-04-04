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
    bloomFilter = [CIFilter filterWithName:@"CIBloom"].autorelease;
    comicFilter = [CIFilter filterWithName:@"CIComicEffect"].autorelease;
    crystalFilter = [CIFilter filterWithName:@"CICrystallize"].autorelease;
    edgeFilter =[CIFilter filterWithName:@"CIEdgeWork"].autorelease;
    hueFilter =[CIFilter filterWithName:@"CIHueAdjust"].autorelease;
    lineFilter =[CIFilter filterWithName:@"CILineScreen"].autorelease;

    
    // Supporting stuff
    texSize = CGSizeMake(outWidth, outHeight);
    inRect = CGRectMake(0,0,outWidth,outHeight);
    outRect = CGRectMake(0,0,outWidth,outHeight);
    
    //Uncomment to list all possible CI filters on your system
    /*
    NSArray *properties = [CIFilter filterNamesInCategory:
                           nil];
    NSLog(@"%@", properties);
    for (NSString *filterName in properties) {
        CIFilter *fltr = [CIFilter filterWithName:filterName];
        NSLog(@"%@", [fltr attributes]);
    }*/
    
    filterNum = 0;
    
}



//--------------------------------------------------------------
void ofApp::update(){
    
    ofSetWindowTitle(ofToString(ofGetFrameRate()));
   

    

    
    //[glCIcontext drawImage:filterCIImage inRect:outRect fromRect:inRect];
    
    
}

//--------------------------------------------------------------
void ofApp::draw(){
    
    ofBackground(50);
    
    sourceFbo.begin();
    
    // For feedback fun, let's not clear the Fbo after the first frame
    //if(ofGetKeyPressed('c')) {
        ofClear(0,0,0,255);
    //}
    // Draw circle
    ofSetColor(20, 130, 250);
    ofNoFill();
    ofSetLineWidth(40);
    ofCircle(outWidth/2,outHeight/2,10+(ofGetFrameNum()%40)*6);
    
    ofFill();
    ofSetColor(255);
    for (int i=0; i<10; i++) {
        ofSetColor(20*i, 10*i, 250);

        ofRect(ofGetWidth()/2+200*sin(i*0.7+0.5*ofGetElapsedTimef()), ofGetHeight()/2+200*cos(i*0.7+0.5*ofGetElapsedTimef()), 100,100);
    }

    
    sourceFbo.end();
    
    tex = sourceFbo.getTextureReference().texData.textureID;
    
    inputCIImage = [CIImage imageWithTexture:tex
                                        size:texSize
                                     flipped:NO
                                  colorSpace:genericRGB];
    
    // Blur filter
    if(filterNum==0){
        [blurFilter setValue:inputCIImage forKey:@"inputImage"];
        [blurFilter setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 1,20)] forKey:@"inputRadius"];
        filterCIImage = [blurFilter valueForKey:@"outputImage"];
    }else if(filterNum==1){
        [bloomFilter setValue:inputCIImage forKey:@"inputImage"];
        [bloomFilter setValue:[NSNumber numberWithFloat: 1] forKey:@"inputIntensity"];
        [bloomFilter setValue:[NSNumber numberWithFloat: 5] forKey:@"inputRadius"];
        filterCIImage = [bloomFilter valueForKey:@"outputImage"];
    }else if(filterNum==2){
        [comicFilter setValue:inputCIImage forKey:@"inputImage"];
        //[comicFilter setValue:[NSNumber numberWithFloat: 0.5+0.5*sin(0.3*ofGetElapsedTimef())] forKey:@"Intensity"];
        filterCIImage = [comicFilter valueForKey:@"outputImage"];
    }
    else if(filterNum==3){
        [crystalFilter setValue:inputCIImage forKey:@"inputImage"];
        [crystalFilter setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 5,50)] forKey:@"inputRadius"];
        filterCIImage = [crystalFilter valueForKey:@"outputImage"];
    }else if(filterNum==4){
        [edgeFilter setValue:inputCIImage forKey:@"inputImage"];
        [edgeFilter setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 0,20)] forKey:@"inputRadius"];
        filterCIImage = [edgeFilter valueForKey:@"outputImage"];
    }
    else if(filterNum==5){
        [hueFilter setValue:inputCIImage forKey:@"inputImage"];
        [hueFilter setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 0,PI)] forKey:@"inputAngle"];
        filterCIImage = [hueFilter valueForKey:@"outputImage"];
    }else if(filterNum==6){
        [lineFilter setValue:inputCIImage forKey:@"inputImage"];
        [lineFilter setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 0,PI)] forKey:@"inputAngle"];
        [lineFilter setValue:[CIVector vectorWithX:ofGetWidth()/2 Y:ofGetHeight()/2] forKey:@"inputCenter"];
        filterCIImage = [lineFilter valueForKey:@"outputImage"];
    }
    // Draw it

    
    ofSetColor(255);
    [glCIcontext drawImage:filterCIImage
                    inRect:outRect
                  fromRect:inRect];
    
    
    //sourceFbo.draw(0,0);
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){
    if(key==' '){
        filterNum++;
        filterNum = filterNum%7;
    }
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
