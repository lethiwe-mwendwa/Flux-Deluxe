void liquidBoundarySolver(LiquidBody body, LiquidBoundary boundary){ // float restitution, float wallFriction
  int pCount = body.particles.length;
  //PVector boundaryPos;
  PVector localPos;
  //PVector worldPos;
  PVector velLocal;
  float radius;
  
  // TEMPORARY!
  float restitution = boundary.restitution;   // bounce strength (normal)
  float wallFriction = boundary.wallFriction; // tangential damping
  
  PVector omega = new PVector(
  boundary.rot.x,
  boundary.rot.y,
  boundary.rot.z
);
 
  for (int i = 0; i < pCount; i++){
    radius = body.particles[i].radius;
    PVector world = body.particles[i].pos.copy();
    
    PVector r = PVector.sub(body.particles[i].pos, boundary.pos);
    
    // I don't think I'll use this
    PVector wallVel = new PVector(
      -omega.y * r.z + omega.z * r.y,
       omega.x * r.z - omega.z * r.x,
      -omega.x * r.y + omega.y * r.x
    );

    // WORLD TO LOCAL RELATIVE TO THE BOUNDARY
    localPos = PVector.sub(world, boundary.pos);
    localPos = rotateToLocal(localPos, boundary.rot);
    velLocal = rotateToLocal(body.particles[i].vel.copy(), boundary.rot);
    
    
    //body.particles[i].vel.sub(wallVel);
    // COLLISION CHECK
    if(localPos.x < -boundary.hx + radius){
      localPos.x = -boundary.hx + radius;
      
      velLocal.x = -velLocal.x * restitution;
      //body.particles[i].vel.x *= -restitution;  
      
      if(wallFriction != 0){
        velLocal.y *= wallFriction; 
        velLocal.z *= wallFriction;
      }
      
       
      //body.particles[i].vel.y *= wallFriction;   
      //body.particles[i].vel.z *= wallFriction;
    }
    
    if(localPos.x > boundary.hx - radius){
      localPos.x = boundary.hx - radius;
      
      velLocal.x = -velLocal.x * restitution;
      if(wallFriction != 0){
      velLocal.y *= wallFriction; 
      velLocal.z *= wallFriction; 
      }
      //body.particles[i].vel.x *= restitution;   
      //body.particles[i].vel.y *= wallFriction;   
      //body.particles[i].vel.z *= wallFriction;
      
    }
    
    if(localPos.y < -boundary.hy + radius){
      localPos.y  = -boundary.hy + radius;
      
      velLocal.y = -velLocal.y * restitution;
      if(wallFriction != 0){
      velLocal.x *= wallFriction; 
      velLocal.z *= wallFriction; 
      }
      //body.particles[i].vel.y *= -restitution;   
      //body.particles[i].vel.x *= wallFriction;   
      //body.particles[i].vel.z *= wallFriction;
      
    }
    
    if(localPos.y > boundary.hy - radius){
      localPos.y = boundary.hy - radius;
      
      velLocal.y = -velLocal.y * restitution;
      if(wallFriction != 0){
      velLocal.x *= wallFriction; 
      velLocal.z *= wallFriction; 
      }
      //body.particles[i].vel.y *= restitution;   
      //body.particles[i].vel.x *= wallFriction;   
      //body.particles[i].vel.z *= wallFriction;
       
    }
    
    if(localPos.z < -boundary.hz + radius){
      localPos.z = -boundary.hz + radius;
       
      velLocal.z = -velLocal.z * restitution;
      if(wallFriction != 0){
      velLocal.x *= wallFriction; 
      velLocal.y *= wallFriction; 
      }
      //body.particles[i].vel.z *= -restitution;   
      //body.particles[i].vel.x *= wallFriction;   
      //body.particles[i].vel.y *= wallFriction;
       
    }
    
    if(localPos.z > boundary.hz - radius){
      localPos.z = boundary.hz - radius;
      
      velLocal.z = -velLocal.z * restitution;
      if(wallFriction != 0){
      velLocal.x *= wallFriction; 
      velLocal.y *= wallFriction;
      }
      //body.particles[i].vel.z *= restitution;   
      //body.particles[i].vel.x *= wallFriction;   
      //body.particles[i].vel.y *= wallFriction;
    }
    // HOPEFULLY THIS WORKSSS
    
    // LOCAL BACK TO WORLD
    localPos = rotateToWorld(localPos, boundary.rot);
    localPos.add(boundary.pos);
    body.particles[i].vel = rotateToWorld(velLocal, boundary.rot);
    body.particles[i].pos = localPos;
  }
}
