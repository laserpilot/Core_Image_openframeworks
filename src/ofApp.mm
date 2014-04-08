#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
   // ofSetFrameRate(30);
    outWidth  = ofGetWidth();
    outHeight = ofGetHeight();
    ofEnableSmoothing();
    ofBackground(0);

    
    // Setup a framebuffer for the drawing. Perhaps there is some way to do this
    // without a framebuffer, but this is the only way I could figure out how to
    // enable grabbing an OpenGL texture to pass to the CoreImage filter
    sourceFbo.allocate(outWidth, outHeight, GL_RGBA32F_ARB); //32-bit framebuffer for smoothness
    sourceFbo.begin();
    ofClear(0);
    sourceFbo.end();
    
    bgFbo.allocate(outWidth, outHeight, GL_RGBA32F_ARB); //32-bit framebuffer for smoothness
    bgFbo.begin();
    ofClear(0);
    bgFbo.end();
    
    
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
    colorControls =[CIFilter filterWithName:@"CIColorControls"].autorelease;
    torusFilter =[CIFilter filterWithName:@"CITorusLensDistortion"].autorelease;
    boxBlurFilter =[CIFilter filterWithName:@"CIBoxBlur"].autorelease;
    kaleidoFilter =[CIFilter filterWithName:@"CIKaleidoscope"].autorelease;
    glideFilter =[CIFilter filterWithName:@"CIGlideReflectedTile"].autorelease;
    pinchFilter =[CIFilter filterWithName:@"CIPinchDistortion"].autorelease;
    falseColorFilter = [CIFilter filterWithName:@"CIFalseColor"].autorelease;
    addFilter = [CIFilter filterWithName:@"CIAdditionCompositing"].autorelease;
    bumpFilter = [CIFilter filterWithName:@"CIBumpDistortion"].autorelease;
    twirlFilter = [CIFilter filterWithName:@"CITwirlDistortion"].autorelease;
    glassFilter = [CIFilter filterWithName:@"CIGlassDistortion"].autorelease;
    halftoneFilter = [CIFilter filterWithName:@"CICMYKHalftone"].autorelease;
    hexFilter =[CIFilter filterWithName:@"CIHexagonalPixellate"].autorelease;
    rippleFilter =[CIFilter filterWithName:@"CIRippleTransition"].autorelease;
    multiplyFilter =[CIFilter filterWithName:@"CIMultiplyBlendMode"].autorelease;
    

    
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
    
    cam.initGrabber(640, 480);
    camActivate = false;
    
}



//--------------------------------------------------------------
void ofApp::update(){
    
    ofSetWindowTitle(ofToString(ofGetFrameRate()));
   
    if(camActivate){
        cam.update();
    }
    

    
    //[glCIcontext drawImage:filterCIImage inRect:outRect fromRect:inRect];
    
    
}

//--------------------------------------------------------------
void ofApp::draw(){
    
    ofBackground(50);
    
    
    //draw stuff into FBO so it can be filtered by core image
    sourceFbo.begin();
    ofClear(0,0,0,255); //can set this alpha to 0 to make the FBO transparent but your effects won't necessarily be seen
    
    if(camActivate){
        cam.draw(0,0,ofGetWidth(), ofGetHeight());
    }

    ofSetColor(20, 130, 250);
    ofNoFill();
    ofSetLineWidth(40);
    ofCircle(outWidth/2,outHeight/2,10+(ofGetFrameNum()%40)*6);
    
    ofFill();
    ofSetColor(255);
    for (int i=0; i<10; i++) {
        ofSetColor(20*i, 10*i, 250);
        ofSetRectMode(OF_RECTMODE_CENTER);
        ofRect(ofGetWidth()/2+200*sin(i*0.7+0.5*ofGetElapsedTimef()), ofGetHeight()/2+200*cos(i*0.7+0.5*ofGetElapsedTimef()), 100,100);
    }
    ofSetRectMode(OF_RECTMODE_CORNER);
    sourceFbo.end();
    
    //lets make a second fbo for doing blend effects with 2 sources
    bgFbo.begin();
    ofClear(0);
    for (int i=0; i<10; i++) {
        ofNoFill();
        ofSetColor(30*i, 30, 250);
        ofCircle(outWidth/2,outHeight/2,20+(ofGetFrameNum()%((i+1)*10))*6);
        ofSetColor(5*i, 20*i, 250);
        ofSetRectMode(OF_RECTMODE_CENTER);
        ofFill();
        ofRect(ofGetWidth()/2+100*sin(ofGetElapsedTimef())+200*sin(i*0.7+0.5*ofGetElapsedTimef()), ofGetHeight()/2+100*cos(ofGetElapsedTimef())+200*cos(i*0.7+0.5*ofGetElapsedTimef()), 100+50*sin(i+0.3*ofGetElapsedTimef()),100+50*cos(i+ofGetElapsedTimef()));
    }
    bgFbo.end();
    
    
    ofSetRectMode(OF_RECTMODE_CORNER);
    
    tex = sourceFbo.getTextureReference().texData.textureID;
    tex2 = bgFbo.getTextureReference().texData.textureID;
    
    inputCIImage = [CIImage imageWithTexture:tex
                                        size:texSize
                                     flipped:NO
                                  colorSpace:genericRGB];
    
    inputBGCIImage = [CIImage imageWithTexture:tex2
                                        size:texSize
                                     flipped:NO
                                  colorSpace:genericRGB];
    
    // Blur filter
    if(filterNum==0){
        filterName = "Gaussian Blur";
        [blurFilter setValue:inputCIImage forKey:@"inputImage"];
        [blurFilter setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 1,20)] forKey:@"inputRadius"];
        filterCIImage = [blurFilter valueForKey:@"outputImage"];
    }else if(filterNum==1){
        filterName = "Bloom";
        [bloomFilter setValue:inputCIImage forKey:@"inputImage"];
        [bloomFilter setValue:[NSNumber numberWithFloat: 1] forKey:@"inputIntensity"];
        [bloomFilter setValue:[NSNumber numberWithFloat: 5] forKey:@"inputRadius"];
        filterCIImage = [bloomFilter valueForKey:@"outputImage"];
    }else if(filterNum==2){
        filterName = "Comic Effect";
        [comicFilter setValue:inputCIImage forKey:@"inputImage"];
        //[comicFilter setValue:[NSNumber numberWithFloat: 0.5+0.5*sin(0.3*ofGetElapsedTimef())] forKey:@"Intensity"];
        filterCIImage = [comicFilter valueForKey:@"outputImage"];
    }
    else if(filterNum==3){
        filterName = " Crystallize";
        [crystalFilter setValue:inputCIImage forKey:@"inputImage"];
        [crystalFilter setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 5,50)] forKey:@"inputRadius"];
        filterCIImage = [crystalFilter valueForKey:@"outputImage"];
    }else if(filterNum==4){
        filterName = "Edge Filter";
        [edgeFilter setValue:inputCIImage forKey:@"inputImage"];
        [edgeFilter setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 0,20)] forKey:@"inputRadius"];
        filterCIImage = [edgeFilter valueForKey:@"outputImage"];
    }
    else if(filterNum==5){
        filterName = "Hue Adjust";
        [hueFilter setValue:inputCIImage forKey:@"inputImage"];
        [hueFilter setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 0,PI)] forKey:@"inputAngle"];
        filterCIImage = [hueFilter valueForKey:@"outputImage"];
    }else if(filterNum==6){
        filterName = "Line Effect";
        [lineFilter setValue:inputCIImage forKey:@"inputImage"];
        [lineFilter setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 0,PI)] forKey:@"inputAngle"];
        [lineFilter setValue:[NSNumber numberWithFloat: ofMap(mouseY,0,ofGetWidth(), 1, 0)] forKey:@"inputSharpness"];
        [lineFilter setValue:[NSNumber numberWithFloat: ofMap(mouseY,0,ofGetWidth(), 1, 30)] forKey:@"inputWidth"];
        [lineFilter setValue:[CIVector vectorWithX:512 Y: 378] forKey:@"inputCenter"];
        filterCIImage = [lineFilter valueForKey:@"outputImage"];
    } else if(filterNum==7){
        filterName = "Color Controls";
        [colorControls setValue:inputCIImage forKey:@"inputImage"];
        [colorControls setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), -1,1)] forKey:@"inputBrightness"];
        [colorControls setValue:[NSNumber numberWithFloat: ofMap(mouseY,0,ofGetWidth(), 0.25, 4)] forKey:@"inputContrast"];
        [colorControls setValue:[NSNumber numberWithFloat: ofMap(mouseY,0,ofGetWidth(), 0, 2)] forKey:@"inputSaturation"];
        filterCIImage = [colorControls valueForKey:@"outputImage"];
    }else if(filterNum==8){
        filterName = "Torus Distortion";
        [torusFilter setValue:inputCIImage forKey:@"inputImage"];
        [torusFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 20,200)] forKey:@"inputWidth"];
        [torusFilter  setValue:[NSNumber numberWithFloat: 1.7] forKey:@"inputRefraction"];
        [torusFilter  setValue:[NSNumber numberWithFloat: 200] forKey:@"inputRadius"];
        [torusFilter  setValue:[CIVector vectorWithX:mouseX Y: mouseY] forKey:@"inputCenter"];
       
        filterCIImage = [torusFilter valueForKey:@"outputImage"];
    }else if(filterNum==9){
        filterName = "Box Blur";
        [boxBlurFilter setValue:inputCIImage forKey:@"inputImage"];
        [boxBlurFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 1,100)] forKey:@"inputRadius"];
        filterCIImage = [boxBlurFilter valueForKey:@"outputImage"];
    }else if(filterNum==10){
        filterName = "Kaleidoscope";
        [kaleidoFilter setValue:inputCIImage forKey:@"inputImage"];
        [kaleidoFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), -PI,PI)] forKey:@"inputAngle"];
        [kaleidoFilter  setValue:[CIVector vectorWithX:mouseX Y: mouseY] forKey:@"inputCenter"];
        [kaleidoFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 0,30)] forKey:@"inputCount"];
        filterCIImage = [kaleidoFilter valueForKey:@"outputImage"];
    }else if(filterNum==11){
        filterName = "Glide Reflect";
        [glideFilter setValue:inputCIImage forKey:@"inputImage"];
        [glideFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), -PI,PI)] forKey:@"inputAngle"];
        [glideFilter  setValue:[CIVector vectorWithX:mouseX Y: mouseY] forKey:@"inputCenter"];
        [glideFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 80,200)] forKey:@"inputWidth"];
        filterCIImage = [glideFilter valueForKey:@"outputImage"];
    }else if(filterNum==12){
        filterName = "Pinch Distortion";
        [pinchFilter setValue:inputCIImage forKey:@"inputImage"];
        [pinchFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 0,1)] forKey:@"inputScale"];
        [pinchFilter  setValue:[CIVector vectorWithX:mouseX Y: mouseY] forKey:@"inputCenter"];
        [pinchFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 80,200)] forKey:@"inputRadius"];
        filterCIImage = [pinchFilter valueForKey:@"outputImage"];
    }else if(filterNum==13){
        filterName = "False Color";
        [falseColorFilter setValue:inputCIImage forKey:@"inputImage"];
        [falseColorFilter  setValue:[CIColor colorWithRed:1 green:0.8 blue:0.9 alpha:1] forKey:@"inputColor0"];
        [falseColorFilter  setValue:[CIColor colorWithRed:0.3 green: ofMap(mouseX,0,ofGetWidth(), 0,1) blue:0.02 alpha:1] forKey:@"inputColor1"];
        filterCIImage = [falseColorFilter valueForKey:@"outputImage"];
    }else if(filterNum==14){
        filterName = "Addition Composite";
        [addFilter setValue:inputCIImage forKey:@"inputImage"];
        [addFilter setValue:inputBGCIImage forKey:@"inputBackgroundImage"];

        filterCIImage = [addFilter valueForKey:@"outputImage"];
    }else if(filterNum==15){
        filterName = "Bump";
        [bumpFilter setValue:inputCIImage forKey:@"inputImage"];
        [bumpFilter  setValue:[CIVector vectorWithX:mouseX Y: mouseY] forKey:@"inputCenter"];
        [bumpFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 80,200)] forKey:@"inputRadius"];
        [bumpFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 0,1)] forKey:@"inputScale"];
        
        filterCIImage = [bumpFilter valueForKey:@"outputImage"];
    }else if(filterNum==16){
        filterName = "Twirl";
        [twirlFilter setValue:inputCIImage forKey:@"inputImage"];
        [twirlFilter  setValue:[CIVector vectorWithX:mouseX Y: mouseY] forKey:@"inputCenter"];
        [twirlFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 200,600)] forKey:@"inputRadius"];
        [twirlFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), -PI,PI)] forKey:@"inputAngle"];
        
        filterCIImage = [twirlFilter valueForKey:@"outputImage"];
    }else if(filterNum==17){
        filterName = "Glass Filter";
        [glassFilter setValue:inputCIImage forKey:@"inputImage"];
        [glassFilter setValue:inputBGCIImage forKey:@"inputTexture"];
        [glassFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 0,500)] forKey:@"inputScale"];
        
        filterCIImage = [glassFilter valueForKey:@"outputImage"];
    }else if(filterNum==18){
        filterName = "Hex Pixellate Filter";
        [hexFilter setValue:inputCIImage forKey:@"inputImage"];
        [hexFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 0,100)] forKey:@"inputScale"];
        [hexFilter  setValue:[CIVector vectorWithX:mouseX Y: mouseY] forKey:@"inputCenter"];
        
        filterCIImage = [hexFilter valueForKey:@"outputImage"];
    }else if(filterNum==19){
        filterName = "CMYK Halftone Filter";
        [halftoneFilter setValue:inputCIImage forKey:@"inputImage"];
        [halftoneFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 0,100)] forKey:@"inputWidth"];
        [halftoneFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseY,0,ofGetWidth(), -PI,PI)] forKey:@"inputAngle"];
        [halftoneFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseY,0,ofGetWidth(), 1,0)] forKey:@"inputSharpness"];
        [halftoneFilter  setValue:[NSNumber numberWithFloat: 0.5] forKey:@"inputUCR"];
        [halftoneFilter  setValue:[NSNumber numberWithFloat: 1] forKey:@"inputGCR"];
        [halftoneFilter  setValue:[CIVector vectorWithX:ofGetWidth()/2 Y: ofGetHeight()/2] forKey:@"inputCenter"];
        
        filterCIImage = [halftoneFilter valueForKey:@"outputImage"];
    }else if(filterNum==20){
        //not sure what is going on with this one - only works periodically, otherwise throws the ROI issue
        filterName = "Ripple Transition";
        [rippleFilter setValue:inputCIImage forKey:@"inputImage"];
        [rippleFilter setValue:inputBGCIImage forKey:@"inputTargetImage"];
        [rippleFilter setValue:inputBGCIImage forKey:@"inputShadingImage"];
        
        [rippleFilter  setValue:[CIVector vectorWithX:ofGetWidth()/2 Y:ofGetHeight()/2] forKey:@"inputCenter"];
        [rippleFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 0,1)] forKey:@"inputTime"];
        [rippleFilter  setValue:[NSNumber numberWithFloat: 100] forKey:@"inputWidth"];
        [rippleFilter  setValue:[NSNumber numberWithFloat: 50] forKey:@"inputScale"];
        [rippleFilter setValue:[CIVector vectorWithX:0 Y:0 Z:ofGetWidth() W:ofGetHeight()] forKey:@"inputExtent"];
        filterCIImage = [rippleFilter valueForKey:@"outputImage"];
    }else if (filterNum==21){
        filterName = "Chain of Crystallize and Pinch";

        [crystalFilter setValue:inputCIImage forKey:@"inputImage"];
        [crystalFilter setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 5,50)] forKey:@"inputRadius"];
        [pinchFilter setValue:[crystalFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
        [pinchFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 0,1)] forKey:@"inputScale"];
        [pinchFilter  setValue:[CIVector vectorWithX:mouseX Y: mouseY] forKey:@"inputCenter"];
        [pinchFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 80,200)] forKey:@"inputRadius"];
        
        filterCIImage = [pinchFilter valueForKey:@"outputImage"];
    }else if(filterNum==22){
        filterName = "Chain of Blur, Torus, Hex and Add";
        //take source 1 into blur
        [blurFilter setValue:inputCIImage forKey:@"inputImage"];
        [blurFilter setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 1,20)] forKey:@"inputRadius"];
        //source 2 into torus
        [torusFilter setValue:inputBGCIImage forKey:@"inputImage"];
        [torusFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 20,200)] forKey:@"inputWidth"];
        [torusFilter  setValue:[NSNumber numberWithFloat: 1.7] forKey:@"inputRefraction"];
        [torusFilter  setValue:[NSNumber numberWithFloat: 400] forKey:@"inputRadius"];
        [torusFilter  setValue:[CIVector vectorWithX:mouseX Y: mouseY] forKey:@"inputCenter"];
        
        //source 2 (torus filtered) into hex filter
        [hexFilter setValue:[torusFilter valueForKey:@"outputImage"]  forKey:@"inputImage"];
        [hexFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 0,50)] forKey:@"inputScale"];
        [hexFilter  setValue:[CIVector vectorWithX:mouseX Y: mouseY] forKey:@"inputCenter"];
        
        //add blend filtered source 1 and 2
        [addFilter setValue:[blurFilter valueForKey:@"outputImage"]  forKey:@"inputImage"];
        [addFilter setValue:[hexFilter valueForKey:@"outputImage"] forKey:@"inputBackgroundImage"];

        filterCIImage = [addFilter valueForKey:@"outputImage"];
    }else if(filterNum==23){
        filterName = "Chain of Blur, Torus, Crystal and Multiply";
        [blurFilter setValue:inputCIImage forKey:@"inputImage"];
        [blurFilter setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 1,20)] forKey:@"inputRadius"];
        
        [torusFilter setValue:[blurFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
        [torusFilter  setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 20,200)] forKey:@"inputWidth"];
        [torusFilter  setValue:[NSNumber numberWithFloat: 1.7] forKey:@"inputRefraction"];
        [torusFilter  setValue:[NSNumber numberWithFloat: 400] forKey:@"inputRadius"];
        [torusFilter  setValue:[CIVector vectorWithX:mouseX Y: mouseY] forKey:@"inputCenter"];
        
        [crystalFilter setValue:[torusFilter valueForKey:@"outputImage"] forKey:@"inputImage"];
        [crystalFilter setValue:[NSNumber numberWithFloat: ofMap(mouseX,0,ofGetWidth(), 5,50)] forKey:@"inputRadius"];
        
        [multiplyFilter setValue:[crystalFilter valueForKey:@"outputImage"]  forKey:@"inputImage"];
        [multiplyFilter setValue:inputCIImage forKey:@"inputBackgroundImage"];
        filterCIImage = [multiplyFilter valueForKey:@"outputImage"];
    }
    // Draw it

    //To do - figure out how to pass this back into an OF friendly GL format
    ofSetColor(255);
    [glCIcontext drawImage:filterCIImage
                    inRect:outRect
                  fromRect:inRect];
    

    
    ofDrawBitmapStringHighlight("Current Filter: " + ofToString(1+filterNum)+ " /24 " + filterName , 20,20 );
    ofDrawBitmapStringHighlight("Press ' ' to go to the next filter. \nMove the mouse to control parameters", 20,40 );
    ofDrawBitmapStringHighlight("Press 'c' to activate camera." , 20,80 );
    
    
    
    //sourceFbo.draw(0,0);
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){
    if(key==' '){
        filterNum++;
        filterNum = filterNum%24;
    }
    
    if(key=='c'){
        camActivate = !camActivate;
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
