///////////////////////////////////////////////////////////////////////////////////////////////
// This tab contains all intersection (collision) code, and figues out intersections between 
// Sim3DObjects, SimRays, SemExtents and Points
//
// All intersection code is in this sperate tab because attaching collion code directly to the a 3D object creates a problem;
// for example, if you have a "triangle-sphere" intersection test, do you put it in the triangle class, or the sphere class?
// To avoid this problem, and to create a centralised useful code resource, all intersection
// code is here as "loose" methods (i.e. not attached to a specific class). 
//
// This tab also contains some methods and classes that relate to Seperated Axis Theorem (SAT) 
// Specifically, triangle/triangle intersection, and a OrientedBox/OrientedBox intersection.
//
// 
// Intersections included in the code below so far are indicated by an x. An ! indicates that this 
// particular combination is not geometrically valid (e.g. a point cannot intersect another point).

//
//                SimSphere  SimBox    SimMesh   SimRay  Point  SimTriangle  SimExtents
// SimSphere         x        x          x          x      x        x          ^
// SimBox            x        x          x          x      x        x          ^
// SimMesh           x        x          x          x      !        x          ^
// SimRay            x        x          x          !      !        x          ^
// Point (PVector)   x        x          !          !      !        !          x
// SimTriangle       x        x          x          x      !        x          ^
// SimExtents        ^        ^          ^          ^      x        ^          x
//
// The SimModel type does not appear in the grid above because it uses more simple collision volumes 
// SimBox and SimSphere to determine intersection. 
//
// SimExtents are not really a shape but do, in effect, define an axis-aligned box. All shapes can provide their extents
// and are generally useful for speeding up algorithms and approximate collision detection. SimExtents can be easliy 
// converted to a SimBox, thereby enabling a whole range of other intersection calculations agains a  SimExtents.
// The ^ sign means "convert the SimExtents to a SimBox to get intersections".
//

///////////////////////////////////////////////////////////////////////////////////////////////
// Genereric intersection methods 
//
// intersections_Sim3DObjectSim3DObject(..) determines which methods to call to work out the intersection between 
// two Sim3DObjects, it works by passing them as their shared base-class the SimTransform, then working out
// what speficic type of Sim3DObject they are, and passing them to the correct intersection test method.
//
//

//                                                                            TETI EDITION ADDITIONS vvv

boolean intersections_TrianglesSphere(SimTriangle[] tris, SimSphere sphere) {
    for(SimTriangle t : tris) {
        if(intersections_SphereTriangle(sphere, t)) return true;
    }
    return false;
}

boolean intersections_TrianglesBox(SimTriangle[] tris, SimBox box) {
    for(SimTriangle t : tris) {
        if(intersections_BoxTriangle(box, t)) return true;
    }
    return false;
}

boolean intersections_TrianglesMesh(SimTriangle[] tris, SimSurfaceMesh mesh) {
    for(SimTriangle t1 : tris) {
        for(SimTriangle t2 : mesh.getTransformedTriangles()) {
            if(intersections_TriangleTriangle(t1, t2)) return true;
        }
    }
    return false;
}

boolean intersections_TrianglesRay(SimTriangle[] tris, SimRay ray) {
    for(SimTriangle t : tris) {
        if(intersections_TriangleRay(t, ray)) return true;
    }
    return false;
}

boolean intersections_TrianglesTriangles(SimTriangle[] trisA, SimTriangle[] trisB) {
    for (SimTriangle t1 : trisA) {
        for (SimTriangle t2 : trisB) {
            if (intersections_TriangleTriangle(t1, t2)) return true;
        }
    }
    return false;
}

///////////////////////////////////////////////////////////////////////////////////////////////
// SimModel collision integration
///////////////////////////////////////////////////////////////////////////////////////////////

// Object vs Object intersections
boolean intersections_SimModelObject(SimModel thisObj, Sim3DObject otherObj) {
    String otherObjectType = otherObj.getClassName();
    SimTriangle[] tris = thisObj.getTransformedTrianglesForCollision();

    if (otherObjectType.equals("SimModel") && !intersections_Sim3DObjectSim3DObject(((SimModel)thisObj).getTransformedBoundingVolume(), otherObj)){return false;}

    if (otherObjectType.equals("SimSphere")) {
        return intersections_TrianglesSphere(tris, (SimSphere)otherObj);
    }

    if (otherObjectType.equals("SimBox")) {
        return intersections_TrianglesBox(tris, (SimBox)otherObj);
    }

    if (otherObjectType.equals("SimSurfaceMesh")) {
        return intersections_TrianglesMesh(tris, (SimSurfaceMesh)otherObj);
    }

    if (otherObjectType.equals("SimModel")) {
      if (!intersections_Sim3DObjectSim3DObject(((SimModel)thisObj).getTransformedBoundingVolume(), 
      ((SimModel)otherObj).getTransformedBoundingVolume())){return false;}

      SimTriangle[] otherTris = ((SimModel)otherObj).getTransformedTrianglesForCollision();
      return intersections_TrianglesTriangles(tris, otherTris);
    }

    // If other object type is not catered for
    return intersections_notCateredForYet(thisObj.getClassName(), otherObjectType);
}

// Object vs Ray intersections
boolean intersections_SimModelRay(SimModel thisObj, SimRay ray) {
  if (!intersections_Sim3DObjectRay(thisObj.getTransformedBoundingVolume(),ray)){return false;}
    SimTriangle[] tris = thisObj.getTransformedTrianglesForCollision();
    return intersections_TrianglesRay(tris, ray);
}

// Object vs Point intersection
boolean isPointInsideSimModel(SimModel thisObj, PVector point) {
    if (!intersections_Sim3DObjectPoint(thisObj.getTransformedBoundingVolume(),point)){return false;}

    SimRay ray = new SimRay(point, vec(1, 0, 0)); // any direction
    intersections_TrianglesRay(thisObj.getTransformedTrianglesForCollision(), ray);
    return (ray.getNumIntersections() % 2 == 1);
}


//                                                                            TETI EDITION ADDITIONS ^^^

boolean intersections_Sim3DObjectSim3DObject(Sim3DObject thisObj, Sim3DObject otherObj){
  // Check to see they are not the same objects.
  // An object can not collide with itself.
  if( thisObj == otherObj) return false;
  
  // get their types as strings
  String thisObjectType = thisObj.getClassName();
  String otherObjectType = otherObj.getClassName();
  
  // SimModels
  
  // ----- SimModel vs other -----

    // ------------------ SimModel as first object ------------------
    
    if (thisObjectType.equals("SimModel")) {
        return intersections_SimModelObject((SimModel)thisObj,otherObj);
    }

    // ------------------ SimModel as second object ------------------
    if (otherObjectType.equals("SimModel")) {
      
        return intersections_SimModelObject((SimModel)otherObj,thisObj);
    }



  //                                                                            TETI EDITION ADDITIONS ^^^
  
  // now check the correct pair of Sim3DObjects against each other...
  
  if( thisObjectType.equals("SimSphere") ){
    if( otherObjectType.equals("SimSphere")) return intersections_SphereSphere((SimSphere)thisObj, (SimSphere)otherObj);
    if( otherObjectType.equals("SimBox")) return intersections_SphereBox((SimSphere)thisObj, (SimBox)otherObj);
    if( otherObjectType.equals("SimSurfaceMesh")) return intersections_MeshSphere((SimSurfaceMesh)otherObj, (SimSphere)thisObj);
  }
  
  if( thisObjectType.equals("SimBox") ){
    if( otherObjectType.equals("SimSphere")) return intersections_SphereBox((SimSphere)otherObj, (SimBox)thisObj);
    if( otherObjectType.equals("SimBox")) return intersections_BoxBox((SimBox)thisObj, (SimBox)otherObj);
    if( otherObjectType.equals("SimSurfaceMesh")) return intersections_MeshBox((SimSurfaceMesh)otherObj, (SimBox)thisObj);
  }
  
  if( thisObjectType.equals("SimSurfaceMesh") ){ 
    if( otherObjectType.equals("SimSphere")) return intersections_MeshSphere((SimSurfaceMesh)thisObj, (SimSphere)otherObj);
    if( otherObjectType.equals("SimBox")) return intersections_MeshBox((SimSurfaceMesh)thisObj, (SimBox)otherObj);
    if( otherObjectType.equals("SimSurfaceMesh")) return intersections_MeshMesh((SimSurfaceMesh)thisObj, (SimSurfaceMesh)otherObj);
  }

  // if you get here, then the class has not been accounted for
  return false;
}


///////////////////////////////////////////////////////////////////////////////////////////////
// General intersection method  for Sim3DObject with Ray - see the table above showing what is currently working
//
// intersections_Sim3DObjectRay(..) determines which methods to call to work out the intersection between 
// a Sim3DObject and a Ray. It works by passing the simobjet as a  SimTransform, then working out
// what speficic type of Sim3DObject they are, and passing them to the correct ray-intersection test method.
//
boolean intersections_Sim3DObjectRay(Sim3DObject Sim3DObject, SimRay ray){
  String objectType = Sim3DObject.getClassName();
  
  // TETI EDITION ADDITION vvv

  if( objectType.equals("SimModel")) {
    return intersections_SimModelRay((SimModel)Sim3DObject, ray);
  }

  // TETI EDITION ADDITION ^^^
  
  
  if( objectType.equals("SimSphere") ){
    return intersections_SphereRay((SimSphere)Sim3DObject,  ray);
  }
  
  if( objectType.contains("SimBox") ){
    return intersections_BoxRay((SimBox)Sim3DObject, ray);
  }
  
  if( objectType.equals("SimSurfaceMesh") ){
    return intersections_MeshRay((SimSurfaceMesh)Sim3DObject, ray);
  }
  

  // if you get here, then the class has not been accounted for
  return intersections_notCateredForYet(objectType, "Ray");
}


///////////////////////////////////////////////////////////////////////////////////////////////
// General intersection methods for Sim3DObject with Point - see the table above showing what is currently working
//
// intersections_Sim3DObjectPoint(..) determines which methods to call to work out the intersection between 
// a Sim3DObject and a Point. It works by passing the simobjet as a  SimTransform, then working out
// what speficic type of Sim3DObject they are, and passing them to the correct point-intersection test method.
//
boolean intersections_Sim3DObjectPoint(Sim3DObject Sim3DObject, PVector point){
  String objectType = Sim3DObject.getClassName();
  
  // TETI EDITION ADDITION vvv

  if( objectType.equals("SimModel")) {
    return isPointInsideSimModel((SimModel)Sim3DObject, point);
  }
  
  // TETI EDITION ADDITION ^^^
  
  if( objectType.equals("SimSphere") ){
    return intersections_SpherePoint((SimSphere)Sim3DObject, point);
  }
  
  if( objectType.equals("SimBox") ){
    return intersections_BoxPoint((SimBox) Sim3DObject, point);
  }
  
  if( objectType.equals("SimSurfaceMesh") ){
    // A mesh is not a volume
    // so cannot have a point "inside" it
    return false;
  }

  // if you get here, then the class has not been accounted for
  return false;
}

boolean intersections_notCateredForYet(String thisType, String otherType){
  println("Intersection between a ", thisType, " and ", otherType, " is not catered for yet ");
  return false;
}


///////////////////////////////////////////////////////////////////////////////////////////////
// All Sphere intersections
//

public boolean intersections_SpherePoint(SimSphere sphere, PVector p) {
    PVector transCen = sphere.getTransformedCentre();
    float transRad = sphere.getTransformedRadius();
    float distP_Cen = transCen.dist(p);
    if (distP_Cen < transRad) return true;
    return false;
  }

public  boolean intersections_SphereSphere(SimSphere sphereA, SimSphere sphereB) {
  // based on common maths knowledge
    PVector cenB = sphereB.getTransformedCentre();
    PVector cenA = sphereA.getTransformedCentre();
    float radiusB = sphereB.getTransformedRadius();
    float radiusA = sphereA.getTransformedRadius();
    if ( cenB.dist(cenA) < radiusA+radiusB ) return true;
    
    return false;
  }
  
public boolean intersections_SphereRay(SimSphere sphere, SimRay ray) {
    // an implemetation of Jeff Hultquist's method. Graphics Gems ed A.Glasner
    ray.intersectionFound = false;
    PVector sphereCen = sphere.getTransformedCentre();
    
    float sphereRad = sphere.getTransformedRadius();
    PVector sphereCenToRayOrigin = PVector.sub(ray.origin, sphereCen); //m
    float b = PVector.dot(sphereCenToRayOrigin, ray.direction);
    float c = PVector.dot(sphereCenToRayOrigin, sphereCenToRayOrigin) - (sphereRad*sphereRad);

    if (c > 0 && b > 0) return false;
    // goes on to calculate the actual interetxection now
    float discr = b*b - c;

    // a negative discriminant means sphere behind ray origin
    if (discr < 0) return false;

    // ray now found to interesect
    float t = -b - sqrt(discr);

    // if t is negative then ray origin inside sphere, clamp t to zero
    if (t < 0) { 
      t = 0;
      
    }
    

    PVector dirMult = PVector.mult(ray.direction, t);
    ray.intersectionPoint = PVector.add(ray.origin, dirMult );
    ray.setIntersectionNormal(  PVector.sub(ray.intersectionPoint, sphereCen) );
    ray.intersectionFound = true;
    ray.intersectionSim3DObject = sphere;
    return true;
  }
  
  
  boolean intersections_SphereBox(SimSphere sphere, SimBox box) {
    if ( box.isOriented() == true ) {
      return intersections_SphereOrientedBox( sphere,  box);
    }
    return intersections_SphereAABox( sphere,  box);
  }
  
  boolean intersections_SphereAABox(SimSphere sphere, SimBox box) {
    // Thanks to Jim Arvo in Graphics Gems 2   
    if ( box.isOriented() == true ) {
      // just in case you have called this directly, and on the wrong type of box, let them know
      println("isSphereAABoxIntersection:: this is not an AA Box! Please use isSphereBoxIntersection(...) ");
      return intersections_SphereOrientedBox( sphere,  box);
    }
    
    
      SimExtents exts = box.getTransformedExtents();
      PVector bmin = exts.minExtents;
      PVector bmax = exts.maxExtents;
      PVector c = sphere.getTransformedCentre();
      float r = sphere.getTransformedRadius();
      float r2 = r * r;
      float dmin = 0;

      if ( c.x < bmin.x ) {
        dmin += sqr( c.x - bmin.x );
      } else {
        if ( c.x > bmax.x ) {
          dmin += sqr( c.x - bmax.x );
        }
      }

      if ( c.y < bmin.y ) {
        dmin += sqr( c.y - bmin.y );
      } else {
        if ( c.y > bmax.y ) {
          dmin += sqr( c.y - bmax.y );
        }
      }

      if ( c.z < bmin.z ) {
        dmin += sqr( c.z - bmin.z );
      } else {
        if ( c.z > bmax.z ) {
          dmin += sqr( c.z - bmax.z );
        }
      }

      boolean intersects = dmin <= r2;
      return intersects;
  

    
  }
  
  
  boolean intersections_SphereOrientedBox(SimSphere sphere, SimBox box){
    // Devised by the author, seems to work
    // loops through the triangles of the box-facets, finds the closest point on each one to the sphere's 
    // centre. If the closest point of all these points is less than sphere's radius then is intersecting
    
    PVector sphereCentre =  sphere.getTransformedCentre();
    float sphereRadius = sphere.getTransformedRadius();
    
    // if the centre of the sphere is inside the box then they definiely intersect
    if( intersections_BoxPoint(box, sphereCentre) == true) return true;
    
    // next, check to see if any of the facets of the box intersect the sphere
    for (int i = 0; i < 6; i++) {

      SimFacet f = box.getTransformedFacet(i);
      SimTriangle t1 = f.tri1;
      SimTriangle t2 = f.tri2;
      
      PVector p1 = t1.closestPointOnTriangle(sphereCentre);
      if(p1.dist( sphereCentre ) < sphereRadius) return true;
      PVector p2 = t2.closestPointOnTriangle(sphereCentre);
      if(p2.dist( sphereCentre ) < sphereRadius) return true;
    }

    return false;
  } 
  
  
  boolean intersections_SphereTriangle(SimSphere sphere, SimTriangle tri){
    // Devised by the author, seems to work
    // Finds the nearest point on the triangle to the sphere's centre, and if that is inside
    // sphere, then they have to be intersecting.
    
    PVector sphereCentre =  sphere.getTransformedCentre();
    float sphereRadius = sphere.getTransformedRadius();
    
    PVector nearestPointOnTriangle = tri.closestPointOnTriangle(sphereCentre);
    float distanceSphereCenetreToClosestPointOnMesh  = sphereCentre.dist(nearestPointOnTriangle);
    if( distanceSphereCenetreToClosestPointOnMesh > sphereRadius) return false;
    return true;
  } 
  

///////////////////////////////////////////////////////////////////////////////////////////////
// All Box intersections, both AA and oriented
//

boolean intersections_BoxBox(SimBox box1, SimBox box2){
  // assumes that if either one is oriented, then treat both as oriented
  if( box1.isOriented()==false && box2.isOriented()==false){
    return intersections_AABoxAABox( box1,  box2);
  }
  
  return intersections_OrientedBoxOrientedBox( box1,  box2);
}


boolean intersections_AABoxAABox(SimBox box1, SimBox box2){
   // assumes that if either one is oriented, then you need to treat both as oriented
  if( box1.isOriented() || box2.isOriented()){
    // just in case user calls this incorrectly, at least let them know
    println("isAABoxAABoxIntersection - boxes are oriented, please use isBoxBoxIntersection(SimBox box1, SimBox box2)");
    return intersections_OrientedBoxOrientedBox( box1,  box2);
  }
  
  // the AABB check using simple bounds
  SimExtents thisExts = box1.getTransformedExtents();
  SimExtents otherExts = box2.getTransformedExtents();
  

  return  intersections_ExtentsExtents(thisExts, otherExts);
}

boolean intersections_OrientedBoxOrientedBox(SimBox box1, SimBox box2){
  // uses the orentedn box class declared further down in this tab
  OrientedBox ob1 = new OrientedBox(box1);
  OrientedBox ob2 = new OrientedBox(box2);
  return  ob1.getOBOBCollision(ob2);
}


boolean intersections_BoxPoint(SimBox box, PVector p){
  // Devised by the author, seems to work
  // does for both AA and OO boxes
  if( box.isOriented() ){
      // works on the assumption that if the point is inside, a ray cast from this point in 
      // any direction will only have 1 intersection with the  box
      SimRay sr = new SimRay(p, vec(1,1,1) );
      box.intersects(sr);
      if( sr.getNumIntersections() == 1) return true;
      return false;
    }
      
    // is AABB
    
    SimExtents extents = box.getTransformedExtents();
    
    return intersections_ExtentsPoint(extents,p);
}


  /////////////////////////////////////////////////////////////////////////////
  //
  // Ray/Box intersection.Works with both AA and Oriented BB's as it uses the box's triangles to
  // calculate the intersection.
  // As there may be 1 or 2 intersections, depending on where the ray starts, it returns the nearest point to the origin
  // of the ray
  // A faster ray/extents check is documented in https://github.com/erich666/GraphicsGems/blob/master/gems/RayBox.c
  // but not implemented here
  //
  public boolean intersections_BoxRay(SimBox box, SimRay sr) {
    // works with AA and OB as uses the box's triangles
    boolean intersectionFound = false;

    sr.clearIntersectingTriangles();
    for (int i = 0; i < 6; i++) {

      SimFacet f = box.getTransformedFacet(i);
      SimTriangle t1 = f.tri1;
      SimTriangle t2 = f.tri2;
      
      
      // sr.addIntersectingTriangle returns true if the ray intersects the triangle
      if ( sr.addIntersectingTriangle(t1) ) intersectionFound = true;
      if ( sr.addIntersectingTriangle(t2) ) intersectionFound = true;
    }

    if (intersectionFound) {
      sr.intersectionSim3DObject = box;
      sr.getNearestTriangleIntersectionPoint();
    }
    
    return intersectionFound;
  } 
  
  
  boolean intersections_BoxTriangle(SimBox box, SimTriangle tri){
    boolean intersectionFound = false;

    
    for (int i = 0; i < 6; i++) {

      SimFacet f = box.getTransformedFacet(i);
      intersectionFound = intersections_TriangleTriangle(f.tri1, tri);
      if(intersectionFound) break;
      intersectionFound = intersections_TriangleTriangle(f.tri2, tri);
      if(intersectionFound) break;
    }

    
    return intersectionFound;
  }
  



///////////////////////////////////////////////////////////////////////////////////////////////
// SimSurfaceMesh intersection tests
//
//

  
boolean intersections_MeshSphere(SimSurfaceMesh mesh, SimSphere sphere){
    // slightly tested, seems to work
    // loops through the triangles of the mesh, finds the closest point on each one to the sphere's 
    // centre. If the closest point of all thses points is < sphere radius then is intersecting
    
    PVector sphereCentre =  sphere.getTransformedCentre();
    float sphereRadius = sphere.getTransformedRadius();
    
    PVector nearestPointOnMesh = mesh.getClosestPointOnTransformedSurface(sphereCentre);
    float distanceSphereCenetreToClosestPointOnMesh  = sphereCentre.dist(nearestPointOnMesh);
    if( distanceSphereCenetreToClosestPointOnMesh > sphereRadius) return false;
    return true;
  } 
  
  boolean intersections_MeshBox(SimSurfaceMesh mesh, SimBox box){
    // 
    // loops through the triangles of the mesh, and checks each of these with
    // the box. First making trivial checks to see if triangles can intersct using their extents
    // then, if they can intersect, seeing if an 2 triangles intersect
    // Exceptions: if the mesh is so small it fits fully inside the box, the test will fail
    SimExtents boxExtents = box.getTransformedExtents();
   
    
    
    
    SimTriangle[] meshTriangles = mesh.getTransformedTriangles();
    boolean intersectionFound = false;
    
    for(int i = 0; i < meshTriangles.length; i++){
      
      SimTriangle thisMeshTriangle = meshTriangles[i];
      //println("Triangle extents ", thisMeshTriangle.getExtents());
      if( intersections_ExtentsExtents( boxExtents, thisMeshTriangle.getExtents() )) {
        intersectionFound = intersections_BoxTriangle( box, thisMeshTriangle);
      }
      
      if(intersectionFound) break;
      
    }
    
    return intersectionFound;
  } 
  
  

public boolean intersections_MeshRay(SimSurfaceMesh mesh, SimRay sr){
    boolean intersectionFound = false;
    
    int numFacets = mesh.getNumFacets();
    sr.clearIntersectingTriangles();
    for (int i = 0; i < numFacets; i++) {
          
          SimFacet f = mesh.getTransformedFacet(i);
          SimTriangle t1 = f.tri1;
          SimTriangle t2 = f.tri2;

          // here the ray does the intersection test with the individual triangles
          // see.. later on
          if( sr.addIntersectingTriangle(t1) ) intersectionFound = true;
          if( sr.addIntersectingTriangle(t2) ) intersectionFound = true; 
        }
       
    if(intersectionFound){
      sr.getNearestTriangleIntersectionPoint();
      sr.intersectionSim3DObject = mesh;
    }
    return intersectionFound;
  } 
  
  
  public boolean intersections_MeshMesh(SimSurfaceMesh thisMesh, SimSurfaceMesh otherMesh){
    
    SimExtents thisExtents = thisMesh.getTransformedExtents();
    SimExtents otherExtents = otherMesh.getTransformedExtents();
    
    // do a trivial extents check on the whole meshes
    if( intersections_ExtentsExtents(thisExtents, otherExtents) == false ) return false;
    SimTriangle[] thisTriangles = thisMesh.getTransformedTriangles();
    SimTriangle[] otherTriangles = otherMesh.getTransformedTriangles();
    
    // now do the hard work of checking each triangle against the other
    for(int thisTriangleIndex = 0; thisTriangleIndex < thisTriangles.length; thisTriangleIndex++){
      for(int otherTriangleIndex = 0; otherTriangleIndex < otherTriangles.length; otherTriangleIndex++){
       
       if( intersections_TriangleTriangle(thisTriangles[thisTriangleIndex], otherTriangles[otherTriangleIndex]) == true)
            return true;
        }
      
    }

    return false;
  }
  
  public boolean intersections_MeshTriangle(SimSurfaceMesh thisMesh, SimTriangle tri){
    
    SimExtents meshExtents = thisMesh.getTransformedExtents();
    SimExtents triExtents = tri.getExtents();
    
    // do a trivial extents check on the whole meshes
    if( intersections_ExtentsExtents(meshExtents, triExtents) == false ) return false;
    SimTriangle[] meshTriangles = thisMesh.getTransformedTriangles();
   
    
    // now do the hard work of checking each triangle against the other
    for(int meshTriangleIndex = 0; meshTriangleIndex < meshTriangles.length; meshTriangleIndex++){
       if( intersections_TriangleTriangle(meshTriangles[meshTriangleIndex], tri) == true)
            return true;
    }

    return false;
  }
///////////////////////////////////////////////////////////////////////////////////////////////
// Triangle-ray intersection
// The MOLLER_TRUMBORE algorithm  https://en.wikipedia.org/wiki/M%C3%B6ller%E2%80%93Trumbore_intersection_algorithm
//
//
public boolean intersections_TriangleRay(SimTriangle triangle, SimRay ray) 
        {

        ray.intersectionPoint = null;
        
        // make local copies so we don't change anything ouside the function
        PVector dir = ray.direction.copy();
        PVector orig = ray.origin.copy();
        PVector v0 = triangle.p1.copy();
        PVector v1 = triangle.p2.copy();
        PVector v2 = triangle.p3.copy();
        
        
        PVector edge_v0v1 = v1.sub(v0);
        PVector edge_v0v2 = v2.sub(v0);
        PVector pvec = dir.cross(edge_v0v2);
        
        float det = edge_v0v1.dot(pvec);
        
        if( nearZero(det) ){
          // ray is parallel with triangle plane
          // this ignores the direction of triangle winding
          return false;
        }
        
        float invDet = 1.0/det;
        PVector tvec = PVector.sub(orig,v0);
        float u = tvec.dot(pvec) * invDet;
        if( u < 0 || u > 1) {
          return false;
        }
        
        PVector qvec = tvec.cross(edge_v0v1);
        float v = dir.dot(qvec) * invDet;
        if(v < 0 || u + v > 1){
          return false;
        }
        
        float t = edge_v0v2.dot(qvec) * invDet;
        if(t < EPSILON){
          // line intersection, not ray intersection... 
          // to avoid hitting a point behind the camera
          return false;
        }
        PVector addToOrigin = PVector.mult(dir,t);
        ray.intersectionPoint = PVector.add(orig,addToOrigin);
        ray.nearestIntersectingTriangle = triangle;
        return true;
        
    }

///////////////////////////////////////////////////////////////////////////////////////////////
// 3D Triangle-Triangle intersection test. A surprisingly complex problem. Uses a SAT approach.
// To speed up, do trival rejection using triangles' extents first.
//
// Adapated from section "4.1 Separation of Triangles" of:
//
//  - [Dynamic Collision Detection using Oriented Bounding Boxes](https://www.geometrictools.com/Documentation/DynamicCollisionDetection.pdf)
// translated into Javascript by https://stackoverflow.com/questions/7113344/find-whether-two-triangles-intersect-or-not.
// Into Java by Simon Schofield
//
 

boolean intersections_TriangleTriangle(SimTriangle t1, SimTriangle t2) {

  
  // check to see if the bounding boxes intersect.. triangles have extents already calculated
  if(  intersections_ExtentsExtents(t1.getExtents() , t2.getExtents() ) == false ) return false;
  
  // check if they are co-planar. If so then assume inifinitely thin coplanar shapes cannot intersect.
  // check for same normal AND inverted normal (mult by -1)
  PVector t2SurfaceNormal = t2.surfaceNormal();
  if( t1.surfaceNormal().equals(  t2SurfaceNormal )) return false;
  if( t1.surfaceNormal().equals(  PVector.mult(t2SurfaceNormal, -1) )) return false;
  
  
  // Now the SAT stuff.
  // Triangle 1:
  // Get edges and normal

  PVector E0 = subV(t1.p2,t1.p1);
  PVector E1 = subV(t1.p3,t1.p1);
  PVector E2 = subV(E1,E0);
  PVector N = crossV(E0,E1);


  // Triangle 2:
  // Get edges and normal

  PVector F0 = subV(t2.p2,t2.p1);
  PVector F1 = subV(t2.p3,t2.p1);
  PVector F2 = subV(F1,F0);
  PVector M = crossV(F0,F1);


  PVector D = subV(t2.p1,t1.p1);

  // Only potential separating axes for non-parallel and non-coplanar triangles are tested.

  // Seperating axis: N
  {
    float p0 = 0;
    float p1 = 0;
    float p2 = 0;
    float q0 = N.dot(D);
    float q1 = q0 + N.dot(F0);
    float q2 = q0 + N.dot(F1);

    if (areProjectionsSeparated(p0, p1, p2, q0, q1, q2))  return false;
  }


  // Separating axis: M
  {
    float p0 = 0;
    float p1 = M.dot(E0);
    float p2 = M.dot(E1);
    float q0 = M.dot(D);
    float q1 = q0;
    float q2 = q0;

    if (areProjectionsSeparated(p0, p1, p2, q0, q1, q2)) return false;
  }


  // Seperating axis: E0 × F0
  {
    float p0 = 0;
    float p1 = 0;
    float p2 = -(N.dot(F0));
    float q0 = crossV(E0,F0).dot(D);
    float q1 = q0;
    float q2 = q0 + M.dot(E0);

    if (areProjectionsSeparated(p0, p1, p2, q0, q1, q2)) return false;
  }


  // Seperating axis: E0 × F1
  {
    float p0 = 0;
    float p1 = 0;
    float p2 = -(N.dot(F1));
    float q0 = crossV(E0,F1).dot(D);
    float q1 = q0 - M.dot(E0);
    float q2 = q0;

    if (areProjectionsSeparated(p0, p1, p2, q0, q1, q2)) return false;
  }


  // Seperating axis: E0 × F2
  {
    float p0 = 0;
    float p1 = 0;
    float p2 = -(N.dot(F2));
    float q0 = crossV(E0,F2).dot(D);
    float q1 = q0 - M.dot(E0);
    float q2 = q1;

    if (areProjectionsSeparated(p0, p1, p2, q0, q1, q2)) return false;
  }


  // Seperating axis: E1 × F0
  {
    float p0 = 0;
    float p1 = N.dot(F0);
    float p2 = 0;
    float q0 = crossV(E1,F0).dot(D);
    float q1 = q0;
    float q2 = q0 + M.dot(E1);

    if (areProjectionsSeparated(p0, p1, p2, q0, q1, q2)) return false;
  }


  // Seperating axis: E1 × F1
  {
    float p0 = 0;
    float p1 = N.dot(F1);
    float p2 = 0;
    float q0 = crossV(E1,F1).dot(D);
    float q1 = q0 - M.dot(E1);
    float q2 = q0;

    if (areProjectionsSeparated(p0, p1, p2, q0, q1, q2)) return false;
  }


  // Seperating axis: E1 × F2
  {
    float p0 = 0;
    float p1 = N.dot(F2);
    float p2 = 0;
    float q0 = crossV(E1,F2).dot(D);
    float q1 = q0 - M.dot(E1);
    float q2 = q1;

    if (areProjectionsSeparated(p0, p1, p2, q0, q1, q2)) return false;
  }


  // Seperating axis: E2 × F0

  {
    float p0 = 0;
    float p1 = N.dot(F0);
    float p2 = p1;
    float q0 = crossV(E2,F0).dot(D);
    float q1 = q0;
    float q2 = q0 + M.dot(E2);

    if (areProjectionsSeparated(p0, p1, p2, q0, q1, q2))  return false;
  }


  // Seperating axis: E2 × F1
  {
    float p0 = 0;
    float p1 = N.dot(F1);
    float p2 = p1;
    float q0 = crossV(E2,F1).dot(D);
    float q1 = q0 - M.dot(E2);
    float q2 = q0;

    if (areProjectionsSeparated(p0, p1, p2, q0, q1, q2)) return false;
  }


  // Seperating axis: E2 × F2
  {
    float p0 = 0;
    float p1 = N.dot(F2);
    float p2 = p1;
    float q0 = crossV(E2,F2).dot(D);
    float q1 = q0 - M.dot(E2);
    float q2 = q1;

    if (areProjectionsSeparated(p0, p1, p2, q0, q1, q2)) return false;
  }


  return true;
} // end of intersections_TriangleTriangle method


boolean areProjectionsSeparated(float p0, float p1, float p2, float q0, float q1, float q2) {
    // used exclusively by above method
    float min_p = min3(p0, p1, p2);
    float max_p = max3(p0, p1, p2);
    float min_q = min3(q0, q1, q2);
    float max_q = max3(q0, q1, q2);

    return ((min_p > max_q) || (max_p < min_q));
  }



  ///////////////////////////////////////////////////////////////////////////////////////////////
  // SimExtents intersection methods
  // Once you have the extents, you can do fast intersection checking with another extents or a point
  // This is used to optimise several other intersection tests, such as BoxMesh intersection
  // NB: SimTriangles have own optimised getExtents() method.
  //
  
  ///////////////////////////////////////////////////////////////////////
  // fast intersection test between two extents
  // This is the same as doing a AABB / AABB intersection test
  //
  boolean intersections_ExtentsExtents(SimExtents thisExts, SimExtents otherExts){
    
  
    return  (thisExts.minExtents.x < otherExts.maxExtents.x) && (thisExts.maxExtents.x > otherExts.minExtents.x) &&
            (thisExts.minExtents.y < otherExts.maxExtents.y) && (thisExts.maxExtents.y > otherExts.minExtents.y) &&
            (thisExts.minExtents.z < otherExts.maxExtents.z) && (thisExts.maxExtents.z > otherExts.minExtents.z);
  }
  
  ///////////////////////////////////////////////////////////////////////
  // fast point-inside test between point and extents
  //
  boolean intersections_ExtentsPoint(SimExtents thisExts, PVector p){
    
    if (  isBetweenInc(p.x, thisExts.minExtents.x , thisExts.maxExtents.x)   &&
          isBetweenInc(p.y, thisExts.minExtents.y , thisExts.maxExtents.y)   &&
          isBetweenInc(p.z, thisExts.minExtents.z , thisExts.maxExtents.z)  ) return true;
    return false;
  }
  
  
  

///////////////////////////////////////////////////////////////////////////////////////////
//  Oriented Box, to be used in conjunction with SimBox to give
//  oreint box collision using Seperated Axis Theorem
//  Probably best to put the class here, as it is cheifly about collision
//
class OrientedBox{
  
  PVector Pos;
  
  // these are the directions of the axis, I think they should be unit vectors
  PVector AxisX, AxisY, AxisZ; 
  
  PVector Half_size;
  
  OrientedBox(){
    
  }
  
  OrientedBox(float w, float h, float d){
    AxisX = vec( 1.f, 0.f, 0.f );
    AxisY = vec( 0.f, 1.f, 0.f );
    AxisZ = vec( 0.f, 0.f, 1.f );
    Pos = vec(0,0,0);
    Half_size = vec(w/2, h/2, d/2);
  }
  
  OrientedBox(SimBox simbox){
   
    Pos = simbox.getTransformedCentre();
    
    PVector[] axes = simbox.getTransformedAxes();
    float w = axes[0].mag();
    float h = axes[1].mag();
    float d = axes[2].mag();
    
    Half_size = new PVector(w/2,h/2,d/2);
    AxisX = axes[0].normalize();
    AxisY = axes[1].normalize();
    AxisZ = axes[2].normalize();
    
  }
  
  // check if there's a separating plane in between the selected axes
  boolean getSeparatingPlane(PVector RPos, PVector Plane, OrientedBox box1,  OrientedBox box2) {
  
      if(  abs(   dotV(RPos,Plane) ) > 
         ( abs(   dotV( multV(box1.AxisX,box1.Half_size.x) , Plane ) ) +
           abs(   dotV( multV(box1.AxisY,box1.Half_size.y) , Plane ) ) +
           abs(   dotV( multV(box1.AxisZ,box1.Half_size.z) , Plane ) ) +
           abs(   dotV( multV(box2.AxisX,box2.Half_size.x) , Plane ) ) + 
           abs(   dotV( multV(box2.AxisY,box2.Half_size.y) , Plane ) ) +
           abs(   dotV( multV(box2.AxisZ,box2.Half_size.z) , Plane ) ) )      
           ) return true;
      return false;
  }

  boolean getOBOBCollision(OrientedBox otherBox) 
  {
      PVector RPos = subV(otherBox.Pos, this.Pos);
  
      return !( getSeparatingPlane(RPos, this.AxisX, this, otherBox) ||
                getSeparatingPlane(RPos, this.AxisY, this, otherBox) ||
                getSeparatingPlane(RPos, this.AxisZ, this, otherBox) ||
                getSeparatingPlane(RPos, otherBox.AxisX, this, otherBox) ||
                getSeparatingPlane(RPos, otherBox.AxisY, this, otherBox) ||
                getSeparatingPlane(RPos, otherBox.AxisZ, this, otherBox) ||
                getSeparatingPlane(RPos, crossV(this.AxisX,otherBox.AxisX), this, otherBox) ||
                getSeparatingPlane(RPos, crossV(this.AxisX,otherBox.AxisY), this, otherBox) ||
                getSeparatingPlane(RPos, crossV(this.AxisX,otherBox.AxisZ), this, otherBox) ||
                getSeparatingPlane(RPos, crossV(this.AxisY,otherBox.AxisX), this, otherBox) ||
                getSeparatingPlane(RPos, crossV(this.AxisY,otherBox.AxisY), this, otherBox) ||
                getSeparatingPlane(RPos, crossV(this.AxisY,otherBox.AxisZ), this, otherBox) ||
                getSeparatingPlane(RPos, crossV(this.AxisZ,otherBox.AxisX), this, otherBox) ||
                getSeparatingPlane(RPos, crossV(this.AxisZ,otherBox.AxisY), this, otherBox) ||
                getSeparatingPlane(RPos, crossV(this.AxisZ,otherBox.AxisZ), this, otherBox));
  }

}// end of OrientedBox Class
