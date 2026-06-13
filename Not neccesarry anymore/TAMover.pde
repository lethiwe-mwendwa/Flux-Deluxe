// Teti addition version of Mover >:3
// Rewritten so I understand it better and add rotational features

class RigidBodyMover implements physics{
  Timer timer = new Timer();
  PVector pos = new PVector(0, 0, 0);            // Position (m)
  PVector acc = new PVector(0, 0, 0);            // Acceleration (m/sec^2)
  PVector linearVel = new PVector(0, 0, 0);      // Linear Velocity (m/sec)
  PVector angularAcc = new PVector(0, 0, 0);     // Angular Acceleration (radians/sec^2)      
  PVector angularVel = new PVector(0, 0, 0);     // Angular Velocity (radians/sec)
  PVector angle = new PVector(0, 0, 0);          // Rotation angle (radians)
  boolean isRolling = false;
  float mass;
  float radius;
  float I; // Moment of inertia
  
  float linearfrictionAmount = 0.9;
  float angularfrictionAmount = 0.05;
  
  float linearDamping = 0.3; // Linear Velocity preservation per frame
  float angularDamping = 0.3; // Angular Velocity preservation per frame
  

  RigidBodyMover() {
    setMass(10);
  }
  
  void setMass(float m) {
    mass = m;
    radius = 60 * sqrt(mass / PI);
    I = (2.0/5.0) * mass * radius * radius;
    // radius = 60 * sqrt(mass / PI); // Radius is proportional to the square root of mass (Why is this important???? TODO. Go over radius stuff)
  }
  void setAcceleration(PVector acceleration) {
    // Directly set acceleration (no mass scaling)
    acc = acceleration;
  }
  
  void setAngularVelocity(PVector angularVelocity){
    angularVel = angularVelocity;
  }

  void addForce(PVector force) {
    acc.add(PVector.div(force, mass));
  }
  
  void addTorque(PVector force, PVector contactPoint) {
    PVector r = PVector.sub(contactPoint, pos);
    PVector torque = r.cross(force);
    angularAcc.add(torque.div(I)); // I = moment of inertia
  }
  
  void applyFriction() {
    PVector reverseLinearForce = PVector.mult(linearVel, -linearfrictionAmount);
    addForce(reverseLinearForce);
  }

  void applyAngularFriction() {
    PVector reverseAngularTorque = PVector.mult(angularVel, -angularfrictionAmount);
    angularAcc.add(reverseAngularTorque);
  }
  
  // linear velocity = angular speed * radius ?

  void update() {
    float dt = timer.getElapsedTime();
    
    // Angular motion
    angularVel.add(PVector.mult(angularAcc, dt));
    angularVel.mult(1 - angularDamping);
    angle.add(PVector.mult(angularVel, dt));
    
    // Linear motion
    linearVel.add(PVector.mult(acc, dt));
    linearVel.mult(1- linearDamping);
    pos.add(PVector.mult(linearVel, dt));
    
    // Enforce rolling condition (v = ω × r)
    //if (isRolling) {
    //  linearVel = angularVel.cross( position vector of the contact point relevant to the );
    //}
    
    acc.mult(0); // Reset acceleration
    angularAcc.mult(0);
    
  }
}


// NOTHING BELOW IS IMPORTANT RN



// OLD CODE
//class Mover {
//  Timer timer = new Timer();
//  PVector pos = new PVector(0, 0);            // Position (m)
//  PVector acc = new PVector(0, 0);            // Acceleration (m/sec^2)
//  PVector linearVel = new PVector(0, 0);      // Linear Velocity (m/sec)
//  PVector angularAcc = new PVector(0, 0);     // Angular Acceleration (radians/sec^2)      
//  PVector angularVel = new PVector(0, 0);     // Angular Velocity (radians/sec)
//  PVector angle = new PVector(0, 0);          // Rotation angle (radians)
//  boolean isRolling = false;
//  float mass;
//  float radius;
//  float I; // Moment of inertia
  
//  float linearfrictionAmount = 0.9;
//  float angularfrictionAmount = 0.05;
  
//  float linearDamping = 0.3; // Linear Velocity preservation per frame
//  float angularDamping = 0.3; // Angular Velocity preservation per frame
  

//  Mover() {
//    setMass(10);
//  }
  
//  void setMass(float m) {
//    mass = m;
//    radius = 60 * sqrt(mass / PI);
//    I = (2.0/5.0) * mass * radius * radius;
//    // radius = 60 * sqrt(mass / PI); // Radius is proportional to the square root of mass (Why is this important???? TODO. Go over radius stuff)
//  }
//  void setAcceleration(PVector acceleration) {
//    // Directly set acceleration (no mass scaling)
//    acc = acceleration;
//  }
  
//  void setAngularVelocity(PVector angularVelocity){
//    angularVel = angularVelocity;
//  }

//  void addForce(PVector force) {
//    acc.add(PVector.div(force, mass));
//  }
  
//  void addTorque(PVector force, PVector contactPoint) {
//    PVector r = PVector.sub(contactPoint, pos);
//    PVector torque = r.cross(force);
//    angularAcc.add(torque.div(I)); // I = moment of inertia
//  }
  
//  void applyFriction() {
//    PVector reverseLinearForce = PVector.mult(linearVel, -linearfrictionAmount);
//    addForce(reverseLinearForce);
//  }

//  void applyAngularFriction() {
//    PVector reverseAngularTorque = PVector.mult(angularVel, -angularfrictionAmount);
//    angularAcc.add(reverseAngularTorque);
//  }
  
//  // linear velocity = angular speed * radius

//  void update() {
//    //println("Acceleration: " + acc);
//    //println("linearVelocity: " + linearVel);
//    //println("Angular Velocity: " + angularVel);
//    //println("Position: " + pos);
//    println("Angle: " + angle);
    
    
//    // Depending on the mode it'll switch up how the mover is affected?
    
//    float dt = timer.getElapsedTime();
    
    
//    // Angular motion
//    angularVel.add(PVector.mult(angularAcc, dt));
//    angularVel.mult(1 - angularDamping);
//    angle.add(PVector.mult(angularVel, dt));
    
    
//    // Linear motion
//    linearVel.add(PVector.mult(acc, dt));
//    linearVel.mult(1- linearDamping);
//    pos.add(PVector.mult(linearVel, dt));
    
    
//    // Enforce rolling condition (v = ω × r)
//    //if (isRolling) {
//    //  linearVel = angularVel.cross(new PVector(0, 0, radius));
//    //}
    
//    acc.mult(0); // Reset acceleration
//    angularAcc.mult(0);
    
    
    
//  }
//}
