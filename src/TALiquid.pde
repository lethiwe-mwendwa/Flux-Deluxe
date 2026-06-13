

class LiquidBody {
  int particleNum = 0;
  SPHParticle[] particles;
  HashMap<Integer, IntList> grid = new HashMap<Integer, IntList>(); // Intlist instead of arraylist for performance
  
  
  float restDensity = 160;
  float stiffness = 500.0;
  
  float viscosityStrength = 5;
  float particleRadius = 0.4;
  
  LiquidBoundary boundary;
  float smoothingLength;
  
  LiquidBody(int particleNum, LiquidBoundary boundary, float smoothingLength){
    this.particleNum = particleNum;
    this.boundary = boundary;
    this.smoothingLength = smoothingLength;
    this.particles = new SPHParticle[this.particleNum];
    addParticlesOLD();
  }
  
  void addParticlesOLD(){
    float sum = 0;
    
    for( int i = 0; i < this.particleNum; i++){
      particles[i] = new SPHParticle(boundary.randomPointWithin(particleRadius), particleRadius);
      particles[i].radius = particleRadius;
      particles[i].vel = boundary.vel.copy();
      particles[i].pressure = stiffness * ((particles[i].density / restDensity)-1);
      
       
    }
    for (int i = 0; i < this.particleNum; i++){
      particles[i].density = 0;
      // Is particle j close enough to affect me?
      for (int j = 0; j < this.particleNum; j++){
      if (i == j) continue;
      
        float r = distance(particles[i], particles[j]); // distance between i and j
        float W = poly6Kernel(r, smoothingLength); // if far → ignore if close → contribute
      
        particles[i].density += particles[j].mass * W;
        sum += particles[i].density;
      } 
  
    }
    restDensity = sum / this.particleNum;
    
  }
  
  void drawParticles(){
    for( int i = 0; i < this.particleNum; i++){
      particles[i].drawParticle();
    }
  }
  
  
}

class LiquidBoundary{
 
  PVector pos = new PVector(0,0,0);
  PVector vel = new PVector(0,0,0);
  PVector acc = new PVector(0,0,0);
  PVector angularVel = new PVector(0,0,0);
  PVector rot = new PVector(0, 0, 0);
  float bWidth;
  float bHeight;
  float bDepth;
  
  float wallFriction = 0.85; // tangential damping
  float restitution = 0.5;   // bounce strength (normal)
  
  float hx;
  float hy;
  float hz;
  
  LiquidBoundary(float bWidth, float bHeight, float bDepth){
      this.bWidth = bWidth;
      this.bHeight = bHeight;
      this.bDepth = bDepth;
      
      this.hx = bWidth/2;
      this.hy = bHeight/2;
      this.hz = bDepth/2;
      
  }
 
  PVector randomPointWithin(float radius){

  float x = random(-hx + radius, hx - radius);
  float y = random(-hy + radius, hy - radius);
  float z = random(-hz + radius, hz - radius);

  PVector local = new PVector(x, y, z);

  // convert to world space
  PVector world = PVector.add(local, pos);

  return world;
  }
  
  
}

PVector rotateToLocal(PVector v, PVector rot) {
  PVector p = v.copy();

  // inverse (Y)
  float cy = cos(-rot.y);
  float sy = sin(-rot.y);
  float x1 = p.x * cy + p.z * sy;  // note: + not -
  float z1 = -p.x * sy + p.z * cy; // note: -p.x not p.x
  p.x = x1;
  p.z = z1;

  // inverse (X)
  float cx = cos(-rot.x);
  float sx = sin(-rot.x);

  float y1 = p.y * cx - p.z * sx;
  float z2 = p.y * sx + p.z * cx;
  p.y = y1;
  p.z = z2;

  // Z?
  
  return p;
}

PVector rotateToWorld(PVector v, PVector rot) {
  PVector p = v.copy();

  // Z??

  // (X)
  float cx = cos(rot.x);
  float sx = sin(rot.x);

  float y1 = p.y * cx - p.z * sx;
  float z1 = p.y * sx + p.z * cx;
  p.y = y1;
  p.z = z1;

  // (Y)
  float cy = cos(rot.y);
  float sy = sin(rot.y);

  float x2 = p.x * cy + p.z * sy;
  float z2 = -p.x * sy + p.z * cy;
  p.x = x2;
  p.z = z2;

  return p;
}
