interface physics {
  
  public void setMass(float m);
  
  public void setAcceleration(PVector acceleration);
  
  public void setAngularVelocity(PVector angularVelocity);

  public void addForce(PVector force);
  
  public void addTorque(PVector force, PVector contactPoint);
  
  public void applyFriction();

  public void applyAngularFriction();

  public void update();
  
}
