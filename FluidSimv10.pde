
void setup(){
  windowTitle("SPH Simulation");
  
  // Cosmetic stuff
  //pixelShader = loadShader("pixelate.glsl");
  //pixelShader.set("resolution", float(width), float(height));
  //pixelShader.set("pixelSize", 0.5); // Change this for bigger/smaller pixels
  ///
  
  try {
    // Gets the IP address of the local host
    InetAddress inet = InetAddress.getLocalHost();
    myIP = inet.getHostAddress();
    
    println("Your IP Address: " + myIP);
    println("Port: 6666");
    println("Use this to connect and stream data to the simulation");
    println("using the app Serial Sensor from Amazon Appstore");
  } catch (UnknownHostException e) {
    println("Could not get IP address: " + e);
    myIP = "Unknown";
  }
  
  size(1060,720,P3D);
  //pg = createGraphics(width, height, P3D);
  frameRate(30);
  noStroke();
 
  
  ///
  
  // CHANGE IT SO IT AUTOMATICALLY GETS THE DEVICES IP, and then tells you the IP to join
  udp = new UDP(this, 6666, myIP);
  //udp.log(true);
  udp.listen(true);

  Phone = new MotionController();
  
  
  ////
  
  theCamera = new SimCamera();
  theCamera.setPositionAndLookat( vec(cameraPosition.x, cameraPosition.y, cameraPosition.z), vec(0, 0, 0) );
  theCamera.isMoving = false;
  
  // LiquidBoundary(float bWidth, float bHeight, float bDepth)
  liquidBoundary = new LiquidBoundary(bWidth,bHeight,bDepth);
  
  // LiquidBody(int particleNum, LiquidBoundary boundary)
  liquidBody = new LiquidBody(particleNum, liquidBoundary, smoothingLength);
  
  
  // UI STUFF NOW!
  
  myUI = new SimUI();
  myUI.setUIScale(1);
  myUI.addSlider("Viscosity", 15, 20).showValue(false);
  myUI.addSlider("Gravity", 15, 60).showValue(false);
  myUI.addSlider("Smoothing Length", 15, 100).showValue(false);
  myUI.addSlider("Wall friction", 15, 140).showValue(false);
  myUI.addSlider("Restitution", 15, 180).showValue(false);
  myUI.addSlider("PhoneStrength", 15, 220).showValue(false);
  myUI.addToggleButton("Flip Gravity", 15, 310);
  myUI.addToggleButton("PhoneInput", 15, 270);
  

  String[] particleMenuItems =  { "100", "300", "500","1000", "2000", "3500", "5000", "10000"};
  myUI.addMenu("Particle Count", 680, 20, particleMenuItems);
  
  String[] boundaryMenuItems =  { "Default", "Small", "Medium", "Large"};
  myUI.addMenu("Boundary Size", 790, 20, boundaryMenuItems);
  
  myUI.addSimpleButton("Reset", 900,20);
  
  myUI.setSliderValue("Wall friction", 0);
  myUI.setSliderValue("Restitution", 0.5);
  myUI.setSliderValue("Smoothing Length", 0.3);
  myUI.setSliderValue("Viscosity", 0.5);
  myUI.setSliderValue("PhoneStrength", 0.5);
  myUI.setSliderValue("Gravity", 0);

  
}



void draw() {
  background(51);
  lights();
  fill(250,255,100);
  
  update();
  theCamera.update();
  theCamera.updateCameraPosition();
  
    if (resetTime){
    reset();
    resetTime = false;
  }

}

void update(){
 
  
  float speed = 0.05;
  //liquidBoundary.angularVel.set(0,0,0);
  
  if (keyPressed && keyCode == LEFT)  { liquidBoundary.rot.y -= speed; liquidBoundary.angularVel.y = -speed; }
  if (keyPressed && keyCode == RIGHT) { liquidBoundary.rot.y += speed; liquidBoundary.angularVel.y =  speed; }
  if (keyPressed && keyCode == UP)    { liquidBoundary.rot.x -= speed; liquidBoundary.angularVel.x = -speed; }
  if (keyPressed && keyCode == DOWN)  { liquidBoundary.rot.x += speed; liquidBoundary.angularVel.x =  speed; }

  
 //float ellapsedTime = timer.getElapsedTime();
 // updateFluid(LiquidBody body, float smoothingLength, float deltaT) 
 for (int s = 0; s < steps; s++) {
 updateFluid(liquidBody, liquidBody.smoothingLength , subDt);
 }
 liquidBoundarySolver(liquidBody, liquidBoundary);
 

  liquidBody.drawParticles();
   
   // UI
  theCamera.startDraw2D();
  myUI.update();
  theCamera.endDraw2D();
  
  phoneStrength = myUI.getSliderValue("PhoneStrength") * 0.01;
  liquidBody.viscosityStrength = myUI.getSliderValue("Viscosity") * 30.0;
  gravity.y = myUI.getSliderValue("Gravity") * 20;
  liquidBody.smoothingLength = myUI.getSliderValue("Smoothing Length") * 2;
  liquidBoundary.wallFriction = 1- (myUI.getSliderValue("Wall friction") * 0.3);
  liquidBoundary.restitution = (myUI.getSliderValue("Restitution") * 1);
  
  if (myUI.getToggleButtonState("Flip Gravity")) gravity.y *= - 1;
  if (myUI.getToggleButtonState("PhoneInput")) UDPMovement = !UDPMovement;
 
}

void reset(){
  
  myUI.setSliderValue("Smoothing Length", 0.7);
  myUI.setSliderValue("Viscosity", 0.9);
  myUI.setSliderValue("Restitution", 0.2);
  myUI.setSliderValue("Gravity", 0.5);
  
  
  
  for(int i = 0; i < liquidBody.particleNum; i++){
    liquidBody.particles[i] = null;
  }
  
  liquidBoundary = null;
  liquidBody = null;

    // LiquidBoundary(float bWidth, float bHeight, float bDepth)
  liquidBoundary = new LiquidBoundary(bWidth,bHeight,bDepth);

  // LiquidBody(int particleNum, LiquidBoundary boundary)
  liquidBody = new LiquidBody(particleNum, liquidBoundary, smoothingLength);
  
  liquidBody.viscosityStrength = myUI.getSliderValue("Viscosity") * 30.0;
  liquidBody.smoothingLength = myUI.getSliderValue("Smoothing Length") * 2;
  liquidBoundary.restitution = (myUI.getSliderValue("Restitution") * 1);
  gravity.y = myUI.getSliderValue("Gravity") * 20;
  
  theCamera.setMoving(false);
  theCamera.setPositionAndLookat(cameraPosition, new PVector(0,0,0));
  theCamera.updateCameraPosition();

  
  
}

void keyPressed() {
  
  //float force = 10f;

  //if (key == 'b') {
    // toggle the UDP movement which allows part of the phone input handling to run in the UDP "receive[]" function
    //UDPMovement = !UDPMovement;
  //}
  
}

void keyReleased() {
  //liquidBoundary.angularVel.set(0, 0, 0);
}


void handleSimUIEvent(SimUIEvent event) {
    if (event.eventIsFromWidget("Reset")) {
    resetTime = true;
  }
  
    if (event.eventIsFromWidget("100")) {
    particleNum = 100;
    println("Particle count updated. Press RESET to apply.");
  }
  
  if (event.eventIsFromWidget("300")) {
    particleNum = 300;
    println("Particle count updated. Press RESET to apply.");
}

  if (event.eventIsFromWidget("500")) {
    particleNum = 500;
    println("Particle count updated. Press RESET to apply.");
}

if (event.eventIsFromWidget("1000")) {
    particleNum = 1000;
    println("Particle count updated. Press RESET to apply.");
}

if (event.eventIsFromWidget("2000")) {
    particleNum = 2000;
    println("Particle count updated. Press RESET to apply.");
}

  if (event.eventIsFromWidget("3500")) {
    particleNum = 3500;
    println("Particle count updated. Press RESET to apply.");
}

if (event.eventIsFromWidget("5000")) {
    particleNum = 5000;
    println("Particle count updated. Press RESET to apply.");
}

if (event.eventIsFromWidget("10000")) {
    particleNum = 10000;
    println("Particle count updated. Press RESET to apply.");
}

if (event.eventIsFromWidget("Default")) {
    bWidth = 10;
    bHeight = 50;
    bDepth = 10;
    cameraPosition = new PVector(50, -20, 30);
    println("Boundary size updated. Press RESET to apply.");
}

if (event.eventIsFromWidget("Small")) {
    bWidth = 5;
    bHeight = 50;
    bDepth = 5;
    cameraPosition = new PVector(50, -20, 30);
    println("Boundary size updated. Press RESET to apply.");
}

if (event.eventIsFromWidget("Medium")) {
    bWidth = 30;
    bHeight = 50;
    bDepth = 30;
    cameraPosition = new PVector(50, -20, 30);
    println("Boundary size updated. Press RESET to apply.");
}

if (event.eventIsFromWidget("Large")) {
    bWidth = 100;
    bHeight = 50;
    bDepth = 100;
    cameraPosition = new PVector(150, -20, 30);
    println("Boundary size updated. Press RESET to apply.");
    
}
  
}
