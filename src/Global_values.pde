float phoneStrength = 0.005;

// Purely cosmetic stuff
//PShader pixelShader;
//PGraphics pg;


float bWidth = 10;
float bHeight = 50;
float bDepth = 10;


// USE THIS TO GET IP OF LAPTOP AUTOMATICALLY!!!

import java.net.InetAddress;
import java.net.UnknownHostException;
String myIP = "";

PVector cameraPosition = new PVector(50, -20, 30);

int particleNum = 2000;

boolean resetTime = false;


// UDP STUFF

import hypermedia.net.*;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
//import java.net.InetAddress;  TRY OUT LATER! 
UDP udp;
MotionController Phone;

////
LiquidBoundary liquidBoundary;
LiquidBody liquidBody;
SimCamera theCamera;

PVector gravity = new PVector(0, 9.8, 0);
float spacing = 0.25;
float smoothingLength = 2.5 * spacing; // ~2.5 * spacing
int steps = 6;
float subDt = 0.0005 / steps;
Timer timer = new Timer();

// TO help with TA SPH performance
float poly6Coeff;
float spikyGradCoeff;
float viscosityCoeff;

SimUI myUI;

// VALUES THAT NEED TO BE ABLE TO BE TWEAKED! They are internal

// LiquidBody {
  //int particleNum = 0;
  //SPHParticle[] particles;
  
  //float restDensity = 0.5;
  //float stiffness = 500;
  
  //float viscosityStrength = 2;
  //float particleRadius = 0; (becomes 0.3)
  
  //float smoothingLength;
  
  
// liquidBoundarySolver
