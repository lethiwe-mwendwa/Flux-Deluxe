///////////////////////////////////////////////////////////////////////////////////////
// This tab contains the SimCamera - a useful flying camera class.
// In fly-mode. WASD - W/S Forward backward, steer with the mouse.
// A/D Straif sideways, up-arrow, down-arrow, Straif up/down
// 
// Toggle flyMode moving (and thus key-hogging) by setting isMoving to false
// Change the speed of the flying using forwardSpeed variable (default is 3.0)
//
// Can produce "camera rays" under the mouse pos, i.e. MouseRays
//
// Also, can render of 2D interface elements correctly using startDraw2D/endDraw2D methods
//
// TBD: User-defined key bindings
//
//
class SimCamera{

  
  
  PVector initialCameraPosition;
  PVector restoreCameraPosition;
  PVector restoreCameraLookat;
  
  PVector cameraUpVector = new PVector(0,-1,0);
  PVector cameraPos;
  PVector cameraLookat;

  float forwardSpeed = 3.0;
  float rotationAmount = 1;
  char cameraMotionToggleKey = 'c';
  
  // needs to be a mode, still, flying, virtual sphere
  boolean isMoving = true;
  
  // defines the extents on the hudArea if used
  PVector hudAreaTL, hudAreaBR;
  
  public SimCamera() {

    setViewParameters(PI/3.0, 1,100000);
    cameraPos = discoverCameraPosition();
    initialCameraPosition = cameraPos.copy();
    //println("initial camera pos", initialCameraPosition);
    cameraLookat = PVector.add(cameraPos, vec(0, 0, -1));
  }
  
  void update() {
    
    if(key == cameraMotionToggleKey && keyPressed) { 
      toggleCameraMotion();
      delay(200);// to stop repeat key press
      }
      
    if( isMoving == false) return;
    
    update_FlyingCamera();
    updateCameraPosition();
  }
  
  
  
   void setPositionAndLookat(PVector pos, PVector lookat) {
    cameraPos = pos.copy();
    cameraLookat = lookat.copy();
    updateCameraPosition();
  }
  
  void setViewParameters(float fov, float nearClip, float farClip){
   // default FOV is PI/3;
    if(fov != 0){
      perspective(fov, float(width)/float(height), nearClip, farClip);
    } else {
      // this is experimental, and has very odd results in many cases
      ortho();
    }
  }
  
  
  
  
  

  PVector getPosition() { 
    return cameraPos;
  }
  PVector getLookat() { 
    return cameraLookat;
  }
  
  PVector getForwardVector() {
    return PVector.sub(cameraLookat, cameraPos).normalize();
  }
  
  void setMoving(boolean b){
    isMoving = b;
  }
  
  void setForwardSpeed(float moreOrLess){
    forwardSpeed = constrain(forwardSpeed + moreOrLess, 0.5,15);
  }
  
  
  
  void setRotationSpeed(float r){
    rotationAmount = r;
  }
  
  
  
 
  void startDraw2D() {
    restoreCameraPosition = getPosition();
    restoreCameraLookat = getLookat();

    setPositionAndLookat(initialCameraPosition, PVector.add(initialCameraPosition, vec(0,0,-1)));
    hint(DISABLE_DEPTH_TEST);
    
    if( hudAreaTL == null) return;
    fill(255,255,255,100);
    rect( hudAreaTL.x, hudAreaTL.y, hudAreaBR.x-hudAreaTL.x, hudAreaBR.y-hudAreaTL.y);
  }

  void endDraw2D() {
    setPositionAndLookat(restoreCameraPosition, restoreCameraLookat);
    hint(ENABLE_DEPTH_TEST);
  }
  
  void setHUDArea(int left, int top, int w, int h){
    hudAreaTL = new PVector(left,top);
    hudAreaBR = new PVector(left+w,top+h);
  }
  
  
  
  ///////////////////////////////////////////////////////////////
  // camera ray methods
  //
  SimRay getMouseRay(){
    return getWindowRay(getMousePos());
  }
  
  SimRay getWindowRay(PVector winPos){
    // returns a ray into the view at position p
    PVector mp = projectWindowPosInto3D(winPos);
    PVector cameraPos = this.getPosition();
    SimRay mouseRay = new SimRay();
    mouseRay.setWithOriginAndSecondPoint(cameraPos,mp);
    return mouseRay;
  }

  ///////////////////////////////////////////////////////////////////////////////////////////
  // below here are all used for internal workings of the camera
  //
  //
  //
  void updateCameraPosition(){
    camera(cameraPos.x, cameraPos.y, cameraPos.z, cameraLookat.x, cameraLookat.y, cameraLookat.z, 0, 1, 0);
  }


  boolean mouseInHUDArea(){
    if(hudAreaTL == null) return false;
    float x = mouseX;
    float y = mouseY;
    return ( isBetweenInc(x, hudAreaTL.x, hudAreaBR.x) && isBetweenInc(y, hudAreaTL.y, hudAreaBR.y) );
  }

  PVector getMousePos() {
    return new PVector(mouseX, mouseY, 0);
  }

  
  PVector discoverCameraPosition() {
    PMatrix3D mat = (PMatrix3D)getMatrix(); //Get the model view matrix
    
    mat.invert();
    return new PVector( mat.m03, mat.m13, mat.m23 );
  }

  
  void update_FlyingCamera () {
    
    if( mouseInHUDArea() ) return;
    
    
 
    if(key == 'w' && keyPressed) moveCameraForward(forwardSpeed);
    if(key == 's' && keyPressed) moveCameraForward(-forwardSpeed);
    if(arrowKeyPressed(LEFT)) strafe( LEFT );
    if(arrowKeyPressed(RIGHT)) strafe( RIGHT );
    if(arrowKeyPressed(UP)) strafe( UP );
    if(arrowKeyPressed(DOWN)) strafe( DOWN );
    
    if (mousePressed && mouseButton == RIGHT) {
      PVector mqv = getMouseQuadrantVector();
      
      if(mqv.mag()>0){
        rotatecameraLeftRight(rotationAmount*mqv.x);
        rotatecameraUpDown(rotationAmount*-mqv.y);
      }
      
    }

  }
  
  void toggleCameraMotion(){
    isMoving = !isMoving;
  }
  
  void strafe(int dir){
    PVector cameraForwardVector = getForwardVector();
    PVector sideVector = cameraForwardVector.cross(cameraUpVector);
    sideVector.mult(forwardSpeed);
    if(dir == LEFT){
      cameraPos = PVector.add(cameraPos, sideVector);
      cameraLookat = PVector.add(cameraLookat, sideVector);
    }
    if(dir == RIGHT){
      cameraPos = PVector.sub(cameraPos, sideVector);
      cameraLookat = PVector.sub(cameraLookat, sideVector);
    }
    
    if(dir == UP){
      PVector cameraUpScaled = PVector.mult(cameraUpVector, forwardSpeed);
      cameraPos = PVector.add(cameraPos, cameraUpScaled);
      cameraLookat = PVector.add(cameraLookat, cameraUpScaled);
    }
    if(dir == DOWN){
      PVector cameraUpScaled = PVector.mult(cameraUpVector, forwardSpeed);
      cameraPos = PVector.sub(cameraPos, cameraUpScaled);
      cameraLookat = PVector.sub(cameraLookat, cameraUpScaled);
    }
    
  }
  
  boolean arrowKeyPressed(int dir){
    if(keyPressed && key == CODED){
      if(keyCode == dir){
        return true;
      }
    }
    return false;
  }
  
  PVector getMouseQuadrantVector(){
    
    
    PVector centre = getCentre3DWindow();
    PVector mousePos = getMousePos();
    
    float dx = (mousePos.x - centre.x)/centre.x;
    float dy = (mousePos.y - centre.y)/centre.y;
    if(abs(dx) < 0.1) dx = 0;
    if(abs(dy) < 0.1) dy = 0;
    
    //println("dx dy ", dx, dy);
    return new PVector(dx,dy);
  }
  
  

  void moveCameraForward(float amt) {
    PVector cameraForwardVector = getForwardVector();
    PVector movement = PVector.mult(cameraForwardVector, amt);
    //println("forward motion ", movement);
    cameraPos = PVector.add(cameraPos, movement);
    cameraLookat = PVector.add(cameraPos, cameraForwardVector);
    setPositionAndLookat(cameraPos, cameraLookat);
  }


  void rotatecameraLeftRight(float degs) {
    PVector cameraForwardVector = getForwardVector();
    cameraForwardVector =  rotateVectorRoundAxis(cameraForwardVector, cameraUpVector, degs);
    cameraLookat = PVector.add(cameraPos, cameraForwardVector);
    setPositionAndLookat(cameraPos, cameraLookat);
  }
  
  void rotatecameraUpDown(float degs) {
    PVector cameraForwardVector = getForwardVector();
    PVector sideVector = cameraForwardVector.cross(cameraUpVector);
    cameraForwardVector =  rotateVectorRoundAxis(cameraForwardVector, sideVector, degs);
    cameraLookat = PVector.add(cameraPos, cameraForwardVector);
    setPositionAndLookat(cameraPos, cameraLookat);
  }
  
  
  PVector getCentre3DWindow(){
    
    float xc = width*0.5;
    float yc = height*0.5;
    return new PVector(xc,yc);
  }
  
 
    
    
  //////////////////////////////////////////////////////////////////////////////////////////
  // Performs conversion to the local coordinate system
  //( reverse projection ) from the window coordinate system
  // i.e. EyeSpace -> WorldSpace
  
  PVector projectWindowPosInto3D(PVector winPos){
    PVector pos3d = this.unProject(winPos.x, winPos.y, 0);
    //println("mousPos2D", winPos.x, winPos.y, 0, " mouse pos 3D ", pos3d);
    return pos3d;
  }
  
  
  PVector unProject(float winX, float winY, float winZ) {
    PMatrix3D mat = getMatrixLocalToWindow();  
    mat.invert();
   
    float[] in = {winX, winY, winZ, 1.0f};
    float[] out = new float[4];
    mat.mult(in, out);  // Do not use PMatrix3D.mult(PVector, PVector)
   
    if (out[3] == 0 ) {
      return null;
    }
   
    PVector result = new PVector(out[0]/out[3], out[1]/out[3], out[2]/out[3]);  
    return result;
  }
  
  //////////////////////////////////////////////////////////////////////////////////////////
  // Function to compute the viewport transformation matrix to the window 
  // coordinate system from the local coordinate system
  PMatrix3D getMatrixLocalToWindow() {
    PMatrix3D projection = ((PGraphics3D)g).projection; 
    PMatrix3D modelview = ((PGraphics3D)g).modelview;   
   
    // viewport transf matrix
    PMatrix3D viewport = new PMatrix3D();
    viewport.m00 = viewport.m03 = width/2;
    viewport.m11 = -height/2;
    viewport.m13 =  height/2;
   
    // Calculate the transformation matrix to the window 
    // coordinate system from the local coordinate system
    viewport.apply(projection);
    viewport.apply(modelview);
    return viewport;
}
  
  PVector rotateVectorRoundAxis(PVector vec, PVector axis, float degs){
    // remember this is in radians
    float theta = radians(degs);
    float x, y, z;
    float u, v, w;
    x=vec.x;
    y=vec.y;
    z=vec.z;
    
    u=axis.x;
    v=axis.y;
    w=axis.z;
    
    float xrot = u*(u*x + v*y + w*z)*(1.0 - cos(theta)) + x* cos(theta) + (-w*y + v*z)* sin(theta);
    float yrot = v*(u*x + v*y + w*z)*(1.0 - cos(theta)) + y* cos(theta) + ( w*x - u*z)* sin(theta);
    float zrot = w*(u*x + v*y + w*z)*(1.0 - cos(theta)) + z* cos(theta) + (-v*x + u*y)* sin(theta);
    return new PVector(xrot, yrot, zrot);
  }
  

  
}
