/////////////////////////////////////////////////////////////////////////////////////////////////////////
// This tab contains the physics class used in the 2nd half of the module, and a useful Timer class
//
//
//


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Simple Newtonian motion and collision response
//
// This Physics class accelerates according to the force accumulated over TIME
// MASS is taken into consideration by using F=MA (or acceleation = force/mass)
// If using "display()" Mass is represented by the surface area of the ball
// 
// The system works thus:-
// within each FRAME update of the system the following happens...
// 1/ Calculate the cumulative acceleration (by acceleration += force/mass) by adding all the forces, including friction, and divide by mass
// 2/ Multiply the acceleration by the elapsed time since the last frame using the Timer's getElapsedTime() method
// 3/ Add this time-scaled-acceleration to the velocity. This is now the change in distance every second.
// 4/ Calculate the time-scaled-velocity, by multiplying velocity by the elapsed time.
// 5/ Add the time-scaled-velocity to the location
// 6/ Set the acceleration back to zero again, as it has been used up
// repeat
//
class SimPhysics {
  // in the second half of the module we will add a Sim3DObject into this physics object
  // instead of using a 2D circle
  Sim3DObject simObject = null;
  
  
  Timer timer = new Timer();
  
  PVector location = new PVector(width/2, height/2, 0);
  PVector velocity = new PVector(0, 0);
  PVector acceleration = new PVector(0,0);
  private float mass = 1;
  float radius = 1;
  float frictionAmount = 0.3;


  SimPhysics() {
    setMass(1);
  }

  SimPhysics(Sim3DObject so, float mass) {
    simObject = so;
    radius = simObject.getTransformedRadius(); // all simobject have a radius, the distance from the centre to the most extent point
    location = simObject.translate.copy();
    setMass(mass);
  }


  
  
  ////////////////////////////////////////////////////////////
  // movement code has not changed except we now set the mass
  // by a method, which calculates the radius of the ball
  // required for drawing and collision checking
  
  void setMass(float m){
    // converts mass into surface area
    mass=m;
    
    
  }
  
  void addForce(PVector f){
    // use F= MA or (A = F/M) to calculated acceleration caused by force
    PVector accelerationEffectOfForce = PVector.div(f, mass);
    acceleration.add(accelerationEffectOfForce);
  }

  
  
  void update() {
    float ellapsedTime = timer.getElapsedTime();
    
    applyFriction();
    
    // scale the acceleration by time elapsed
    PVector accelerationOverTime = PVector.mult(acceleration, ellapsedTime);
    velocity.add(accelerationOverTime);
    
    // scale the movement by time elapsed
    PVector distanceMoved = PVector.mult(velocity, ellapsedTime);
    location.add(distanceMoved);
    
    // now that you have "used" your accleration it needs to be re-zeroed
    acceleration = new PVector(0,0);
    
    
  }
  
  
  
  void drawMe() {
    
    if(simObject == null){
      // draw in 2D 
      pushStyle();
        stroke(0);
        strokeWeight(2);
        fill(127);
        radius = 60 * sqrt( mass/ PI );
        ellipse(location.x, location.y, radius*2, radius*2);
      popStyle();
    } else {
      // draw the 3D sim object
      simObject.setTranslation(location.x, location.y, location.z);
      simObject.drawMe();
    }
    
  }
  
  
  
  
  void applyFriction(){
    // modify the acceleration by applying
    // a force in the opposite direction to its velociity
    // to simulate friction
    PVector reverseForce = PVector.mult( velocity, -frictionAmount );
    addForce(reverseForce);
  }
  
  ////////////////////////////////////////////////////////////
  // very simple collision code based on simple radius
  // call collisionCheck just before or after update in the "main" tab
  
  boolean collisionCheck(SimPhysics otherMover){
    
    if(otherMover == this) return false; // can't collide with yourself!
    
    float distance = otherMover.location.dist(this.location);
    float minDist = otherMover.radius + this.radius;
    if (distance < minDist)  return true;
    return false;
  }
  
  
  void collisionResponse(SimPhysics otherMover) {
    // Simulated perfect elastic collision of two spherical/circular objects
    // based on formilar given at https://en.wikipedia.org/wiki/Elastic_collision
    //
    // It works by setting the new, post-collision,  velocity on THIS object, and the OTHER object
    // based on maintaining overall momentum, and calculating post-collision direction based on
    // the axis of collision between the two objects.
    //
    if(otherMover == this) return; // can't collide with yourself!
     
     
    PVector v1 = this.velocity;
    PVector v2 = otherMover.velocity;
    
    PVector cen1 = this.location;
    PVector cen2 = otherMover.location;
    
    // calculate v1New, the new velocity of this mover
    float massPart1 = 2*otherMover.mass / (this.mass + otherMover.mass);
    PVector v1subv2 = PVector.sub(v1,v2);
    PVector cen1subCen2 = PVector.sub(cen1,cen2);
    float topBit1 = v1subv2.dot(cen1subCen2);
    float bottomBit1 = cen1subCen2.mag()*cen1subCen2.mag();
    
    float multiplyer1 = massPart1 * (topBit1/bottomBit1);
    PVector changeV1 = PVector.mult(cen1subCen2, multiplyer1);
    
    PVector v1New = PVector.sub(v1,changeV1);
    
    // calculate v2New, the new velocity of other mover
    float massPart2 = 2*this.mass/(this.mass + otherMover.mass);
    PVector v2subv1 = PVector.sub(v2,v1);
    PVector cen2subCen1 = PVector.sub(cen2,cen1);
    float topBit2 = v2subv1.dot(cen2subCen1);
    float bottomBit2 = cen2subCen1.mag()*cen2subCen1.mag();
    
    float multiplyer2 = massPart2 * (topBit2/bottomBit2);
    PVector changeV2 = PVector.mult(cen2subCen1, multiplyer2);
    
    PVector v2New = PVector.sub(v2,changeV2);
    
    this.velocity = v1New;
    otherMover.velocity = v2New;
    ensureNoOverlap(otherMover);
  }
  
 
  void ensureNoOverlap(SimPhysics otherMover){
    // the purpose of this method is to avoid Movers sticking together:
    // if they are overlapping it moves this Mover directly away from the other Mover to ensure
    // they are not still overlapping come the next collision check 
    
    
    PVector cen1 = this.location;
    PVector cen2 = otherMover.location;
    
    float cumulativeRadii = (this.radius + otherMover.radius)+2; // extra fudge factor
    float distanceBetween = cen1.dist(cen2);
    
    float overlap = cumulativeRadii - distanceBetween;
    if(overlap > 0){
      // move this away from other
      PVector vectorAwayFromOtherNormalized = PVector.sub(cen1, cen2).normalize();
      PVector amountToMove = PVector.mult(vectorAwayFromOtherNormalized, overlap);
      this.location.add(amountToMove);
    }
  }

}




/////////////////////////////////////////////////////////////////
// Timer class. Returns time in 
// floating point seconds
//
//
//

class Timer{
  
  int startMillis = 0;
  float lastNow;
  public Timer(){
    start();
  }
  
  // call this to reset the timer
  void start(){
    startMillis = millis();
    
    lastNow = 0;
  }
  
  // returns the elapsed time since you last called this function
  // or since start() if it's the first time called
  float getElapsedTime(){
    float now =  getTimeSinceStart();
    float elapsedTime = now - lastNow;
    lastNow = now;
    return elapsedTime;
    
  }
  
  // call this to get the time since you called start() or 
  // instantiated the object
  float getTimeSinceStart(){
    return ((millis()-startMillis)/1000.0);
  }
  
  
}
