// SPH particle = state container, not behavior container

class SPHParticle {
  PVector pos = new PVector(0, 0, 0);  // Position
  PVector vel = new PVector(0, 0, 0);  // Velocity
  PVector force = new PVector(0,0,0); // Force Accumulator
  float density = 0;  
  float pressure = 0;
  float mass = 1;
  float radius = 0;
  float renderRadius = 0;
  
  SPHParticle(PVector position, float radius) {
    this.pos = position.copy();
    this.radius = radius;
    this.renderRadius = radius * 0.6;
  }
  
  void drawParticle(){
    float speed = this.vel.mag();
    float maxSpeed = 0.1;
    float t = constrain(speed / maxSpeed, 0, 1);

    color blue   = color(0, 0, 255);
    color green  = color(0, 200, 100); // 0 220 50
    color yellow = color(255, 255, 50); // 200 220 0
    color red    = color(255, 0, 50);

    color speedColor;

    if (t < 0.33) {
        float localT = t / 0.33;
        speedColor = lerpColor(blue, green, localT);

    } else if (t < 0.66) {
        float localT = (t - 0.33) / 0.33;
        speedColor = lerpColor(green, yellow, localT);

    } else {
        float localT = (t - 0.66) / 0.34;
        speedColor = lerpColor(yellow, red, localT);
    }
          
         
    fill(speedColor);
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    sphere(renderRadius); 
    popMatrix();
  }
}
