

// SPH summation operator applied to particles
void updateFluid(LiquidBody body, float smoothingLength, float deltaT){ 
  
  int pCount = body.particleNum;
  float h = smoothingLength;
  float r = 0;
  float W = 0;
  deltaT = min(deltaT, 0.0015); // CLAMPING! Just tweaking values till it works
  
  initSPHConstants(h);
  
  // CREATE HASHGRID BASED ON ALL PARTICLE LOCATIONS!
  body.grid.clear();

  for (int i = 0; i < pCount; i++) {
    SPHParticle p = body.particles[i];

    int cx = floor(p.pos.x / h);
    int cy = floor(p.pos.y / h);
    int cz = floor(p.pos.z / h);

    int hash = cx * 73856093 ^ cy * 19349663 ^ cz * 83492791;

    IntList cell = body.grid.get(hash);
    
    if (cell == null) {
      cell = new IntList(); 
      body.grid.put(hash, cell);
    }

    cell.append(i);
  }

  
  // STEP 1 Density computation!
  for (int i = 0; i < pCount; i++){
    body.particles[i].density = 0;
    
    int cx = floor(body.particles[i].pos.x / h);
    int cy = floor(body.particles[i].pos.y / h);
    int cz = floor(body.particles[i].pos.z / h);
    
    // Close cells in each direction
    for (int dx = -1; dx <= 1; dx++)
    for (int dy = -1; dy <= 1; dy++)
    for (int dz = -1; dz <= 1; dz++) {
      int nx = cx + dx;
      int ny = cy + dy;
      int nz = cz + dz;
      
      int hash = nx * 73856093 ^ ny * 19349663 ^ nz * 83492791;
      
      IntList cell = body.grid.get(hash);
      
      if (cell == null) continue;
      
      for (int k = 0; k < cell.size(); k++) {
        int j = cell.get(k);
        r = distance(body.particles[i], body.particles[j]);
        W = poly6Kernel(r, h);
        body.particles[i].density += body.particles[j].mass * W;
      }
    }
  }
  
  // STEP 2 Pressure computation! Suprisingly simple.
  for (int i = 0; i < pCount; i++){
     body.particles[i].pressure = body.stiffness * (body.particles[i].density - body.restDensity);
  }
  
  // STEP 3 Force accumulation!
  for (int i = 0; i < pCount; i++){
    body.particles[i].force.set(0,0,0);
    
    // External forces
    // DO THIS BEFORE ANYTHING ELSE
    body.particles[i].force.y += gravity.y * body.particles[i].mass;
    
    int cx = floor(body.particles[i].pos.x / h);
    int cy = floor(body.particles[i].pos.y / h);
    int cz = floor(body.particles[i].pos.z / h);
    
    for (int dx = -1; dx <= 1; dx++)
    for (int dy = -1; dy <= 1; dy++)
    for (int dz = -1; dz <= 1; dz++) {
      int nx = cx + dx;
      int ny = cy + dy;
      int nz = cz + dz;
      
      int hash = nx * 73856093 ^ ny * 19349663 ^ nz * 83492791;
      
      IntList cell = body.grid.get(hash);
      
      if (cell == null) continue;
      
      for (int k = 0; k < cell.size(); k++) {
        int j = cell.get(k);
        
        if (i == j) continue;
        float Fdx = body.particles[j].pos.x - body.particles[i].pos.x;
        float Fdy = body.particles[j].pos.y - body.particles[i].pos.y;
        float Fdz = body.particles[j].pos.z - body.particles[i].pos.z;
        float r2 = Fdx*Fdx + Fdy*Fdy + Fdz*Fdz;

        if (r2 > h*h) continue;
        r = sqrt(r2);
        if (r == 0) continue;
      
        float invR = 1.0 / (r + 1e-6);
        float dirX = Fdx * invR;
        float dirY = Fdy * invR;
        float dirZ = Fdz * invR;
      
        float gradMag = spikyKernel(r, h);
        float pi = body.particles[i].pressure;
        float pj = body.particles[j].pressure;
        float rhoi = body.particles[i].density;
        float rhoj = body.particles[j].density;

        float pressureTerm = (pi + pj) / (2.0 * rhoi * rhoj + 1e-6);
        float scalar = -body.particles[j].mass * pressureTerm * gradMag;
      
        // body.particles[i].force.add(forceContribution); redone for performance
        body.particles[i].force.x += dirX * scalar;
        body.particles[i].force.y += dirY * scalar;
        body.particles[i].force.z += dirZ * scalar;
      
        // Viscovity
        float dvx = body.particles[j].vel.x - body.particles[i].vel.x;
        float dvy = body.particles[j].vel.y - body.particles[i].vel.y;
        float dvz = body.particles[j].vel.z - body.particles[i].vel.z;

        float weightByDifference = viscosityKernel(r, h);
        scalar = (body.particles[j].mass * body.viscosityStrength * weightByDifference) / (2.0 * body.particles[j].density + 1e-6);

        // directly accumulate into force for performance. Avoid more PVectors
        body.particles[i].force.x += dvx * scalar;
        body.particles[i].force.y += dvy * scalar;
        body.particles[i].force.z += dvz * scalar;
        
      }
    }
  }
  
  
  // STAGE 4 Integration
  for (int i = 0; i < pCount; i++){
    
    float ax = body.particles[i].force.x / body.particles[i].mass;
    float ay = body.particles[i].force.y / body.particles[i].mass;
    float az = body.particles[i].force.z / body.particles[i].mass;

    body.particles[i].vel.x += ax * deltaT;
    body.particles[i].vel.y += ay * deltaT;
    body.particles[i].vel.z += az * deltaT;
    
    //vel.mult(deltaT);
    
    body.particles[i].pos.add(body.particles[i].vel); 
  }
}

float distance(SPHParticle i, SPHParticle j){
  
  float dx = j.pos.x - i.pos.x;
  float dy = j.pos.y - i.pos.y;
  float dz = j.pos.z - i.pos.z;

  float r2 = dx*dx + dy*dy + dz*dz;
  return sqrt(r2);
}


// Poly6 Kernel for density
float poly6Kernel(float r, float h){
  if (r > h) return 0;

  float x = h*h - r*r;
  return x*x*x * poly6Coeff;
}

// Spiky Kernel for pressure forces
float spikyKernel(float r, float h){
  if (r > h) return 0;

  float x = h - r;
  return x*x*x * spikyGradCoeff;
}

// Viscosity Kernel for velocity smoothing
float viscosityKernel(float r, float h){
  if (r > h) return 0;

  return (h - r) * viscosityCoeff;
}

// to avoid running expensive calculations multiple times
void initSPHConstants(float h) {
  poly6Coeff = 315.0 / (64.0 * PI * pow(h, 9));
  spikyGradCoeff = 45.0 / (PI * pow(h, 6));
  viscosityCoeff = 45.0 / (PI * pow(h, 6));
}
