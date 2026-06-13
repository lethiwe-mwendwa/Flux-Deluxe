boolean UDPMovement = false;
boolean connected = false;
boolean firstConnect = false;

// able to do multiplayer?
class MotionController {

  float gyroX = 0;
  float gyroY = 0;
  float gyroZ = 0;

  float gravityX = 0;
  float gravityY = 0;
  float gravityZ = 0;

  float accelX = 0;
  float accelY = 0;
  float accelZ = 0;

  float gyroXnew;
  float gyroYnew;
  float gyroZnew;

  float gravityXnew;
  float gravityYnew;
  float gravityZnew;

  float accelXnew;
  float accelYnew;
  float accelZnew;

  boolean gyroChanged = false;
  boolean accelChanged = false;
  boolean gravityChanged = false;

  MotionController() {
  };

  float low_pass_filter(float new_value, float previous_filtered_value){
    float alpha = 0.5;
    return alpha * new_value + (1 - alpha) * previous_filtered_value;
  }
  
  void gyroUpdate(float x, float y, float z) {
    //gyroXnew = x;
    //gyroYnew = y;
    //gyroZnew = z;
    
    gyroXnew = low_pass_filter(x,gyroX);
    gyroYnew = low_pass_filter(y,gyroY);
    gyroZnew = low_pass_filter(z,gyroZ);
  };
  void gravityUpdate(float x, float y, float z) {
    //gravityXnew = x;
    //gravityYnew = y;
    //gravityZnew = z;
    
    gravityXnew = low_pass_filter(x,gravityX);
    gravityYnew = low_pass_filter(y,gravityY);
    gravityZnew = low_pass_filter(z,gravityZ);
  };
  void accelUpdate(float x, float y, float z) {
    //accelXnew = x;
    //accelYnew = y;
    //accelZnew = z;
    
    accelXnew = low_pass_filter(x,accelX);
    accelYnew = low_pass_filter(y,accelY);
    accelZnew = low_pass_filter(z,accelZ);
  };

  void updateShape() {
    if (gyroChanged) {
      //terrain.setTransformRel(1, (gyroXnew)/250, (gyroYnew)/250, (gyroZnew)/250, null);
      
      
      // APPLY ROTATIONAL TO OBJECT HERE
      liquidBoundary.rot.x += gyroXnew * phoneStrength;
      liquidBoundary.rot.y += gyroYnew * phoneStrength;
      liquidBoundary.rot.z += gyroZnew * phoneStrength;
      
      // Probably really unstable.
      
      //PVector force = new PVector(x, y, z);
      //ball1.physics.addForce(force);
      
      gyroX = gyroXnew;
      gyroY = gyroYnew;
      gyroZ = gyroZnew;
      gyroChanged = false;
    }
    if (accelChanged && gravityChanged) {
      
      float x = (accelXnew)-(gravityXnew);
      float y = (accelYnew)-(gravityYnew);
      float z = (accelZnew)-(gravityZnew);
      
      // APPLY ACCELERATION TO OBJECT HERE
      PVector acceleration = new PVector(x, y, z);
      
      //ball1.physics.acceleration = acceleration.mult(50);
      //ball1.physics.velocity.add(PVector.mult(acceleration,0.6));
      
      // make ABS that does not include rotations? current
      //terrain.setTransformRel(1, 0, 0, 0, vec( x/20, y/20, z/20 ));
      
      //old
      //terrain.setTransformRel(1, 0, 0, 0, vec( x, y, z ));
      
      accelX = accelXnew;
      accelY = accelYnew;
      accelZ = accelZnew;
      gravityX = gravityXnew;
      gravityY = gravityYnew;
      gravityZ = gravityZnew;
      
      accelChanged = false;
      gravityChanged = false;
    }
  }
}

void receive(byte[] data) {
  
  firstConnect = true;
  
  if(firstConnect && !connected){
   print("\nYour phone is now sending data over!") ;
   connected = true;
  }
  
  //println("WE WORKING");
  if (data.length < 13) {
    //println("Received incomplete data: " + data.length + " bytes");
    return;
  }

  // Parse the binary data
  ByteBuffer buffer = ByteBuffer.wrap(data);
  buffer.order(ByteOrder.LITTLE_ENDIAN); // Matches Python's '<' format

  try {
    int SensorID = data[0];
    float deviceX = buffer.getFloat(1); // Bytes 1-4
    float deviceY = buffer.getFloat(5); // Bytes 5-8
    float deviceZ = buffer.getFloat(9); // Bytes 9-12
    
    // have presets depending on the orientation. eg, x, y and z will change based on the preset.
    
    float x = deviceX;
    float y = -deviceZ;
    float z = -deviceY;

    // its not transmitting speed, its transmitting acceleration
    // it's acceleration!!!!!!!!!!
    // sensors don't detect where it is!!!
    // you need something to pin your location down to or do really clever stuff to 
    // USE IT TO SET THE SPEEED!

    switch (SensorID) {
    case 1: // Accel Sensor ID
      //println("Accelerometer");
      if (vec(x, y, z) != vec(Phone.accelX, Phone.accelY, Phone.accelZ)) {
        Phone.accelChanged = true;
        Phone.accelUpdate(x, y, z);
      }
      break;
    case 4: // Gyro Sensor ID
      //println("Gyro");
      if (vec(x, y, z) != vec(Phone.gyroX, Phone.gyroY, Phone.gyroZ)) {
        Phone.gyroChanged = true;
        Phone.gyroUpdate(x, y, z);
        if (UDPMovement) {
          Phone.updateShape();
        }
      }
      break;
    case 9: // Gravity Sensor ID
      //println("Gravity");
      if (vec(x, y, z) != vec(Phone.gravityX, Phone.gravityY, Phone.gravityZ)) {
        Phone.gravityChanged = true;
        Phone.gravityUpdate(x, y, z);
        if(UDPMovement && Phone.accelChanged) {
          Phone.updateShape();
        }
      }
      break;
    }

    //println("Data:" + String.format("%1.6f, %1.6f, %1.6f", x, y, z));
  }
  catch (Exception e) {
    //println("Error parsing data: " + e.getMessage());
  }
}
