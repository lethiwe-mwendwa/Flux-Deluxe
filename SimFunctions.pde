///////////////////////////////////////////////////////////////////////////////////////////
// This tab contains an assortment of useful methods and classes.
// - useful maths functions and shorthand functions 
// - drawPoint and drawMajorAxes methods
// - SimExtents class
// - SimRay class
// - SimTriangle class
// - SimFacet class

///////////////////////////////////////////////////////////////////////////////////////////
//  maths functions, and short-hands, generally used

// shorthand for a new PVector
PVector vec(float x, float y, float z) {
  return new PVector(x, y, z);
}

// shorthand for adding two PVectors
PVector addV(PVector a, PVector b) {
  return PVector.add(a, b);
}

// shorthand for subtracting two PVectors
PVector subV(PVector a, PVector b) {
  return PVector.sub(a, b);
}

// shorthand for getting the cross-product two PVectors
PVector crossV(PVector v1, PVector v2) {
  return v1.cross(v2);
}

// shorthand for multiplying two PVectors
PVector multV(PVector v, float f) {
  return PVector.mult(v, f);
}


// shorthand for getting the dot-product two PVectors
float dotV(PVector v1, PVector v2) {
  return v1.dot(v2);
}


// shorthand for square of two floats
static float sqr(float a) {
  return a*a;
}

// returns true if v is between lo and hi, inclusive
boolean isBetweenInc(float v, float lo, float hi) {

  float sortedLo = min(lo, hi);
  float sortedHi = max(lo, hi);

  if (v >= sortedLo && v <= sortedHi) return true;
  return false;
}

// returns true if v is near zero. Used to avoid divide by zero.
boolean nearZero(float v) {

  if ( abs(v) <= EPSILON ) return true;
  return false;
}

// returns the min of 3 numbers
float min3(float a, float b, float c) {
  return  min( min(a, b), c);
}

// returns the max of 3 numbers
float max3(float a, float b, float c) {
  return  max( max(a, b), c);
}



///////////////////////////////////////////////////////////////////////////////////////////
// useful drawing utilities
//

// draws a point in 3D space
void drawPoint(PVector p, color c, float size) {
  pushStyle();
  strokeWeight(size);
  stroke(c);
  point(p.x, p.y, p.z);
  popStyle();
}


// draws the major x,y,z axis in 3D space aound point p, with
// each axis line being of length len. The x axis is red, the y axis is blue, the z axis is green.
void drawMajorAxis(PVector p, float len) {

  PVector topOfLine = new PVector(p.x, p.y+len, p.z);
  PVector intoScene = new PVector(p.x, p.y, p.z+len);
  PVector sideways  = new PVector(p.x+len, p.y, p.z);

  hint(DISABLE_DEPTH_TEST);
  // line x (red)
  stroke(255, 0, 0);
  line(p.x, p.y, p.z, sideways.x, sideways.y, sideways.z);

  // line y (green)
  stroke(0, 255, 0);
  line(p.x, p.y, p.z, topOfLine.x, topOfLine.y, topOfLine.z);

  // line z (blue)
  stroke(0, 0, 255);
  line(p.x, p.y, p.z, intoScene.x, intoScene.y, intoScene.z);
  hint(ENABLE_DEPTH_TEST);
}




////////////////////////////////////////////////////////////////////////////////////////
// SimExtents class
// Returns the extents of an object. 
// This can be initialised by passing in an array of the object's vertices (PVector points).
// The getMin() and getMax() return the minimum x,y,z and maximum x,y,z value of a shape
// and as such describes a simple Axis Aligned Bounding Box. 
// The getCentrePoint() returns a point mid-way between the min and max Extents points.
// The getRadius() method can be used as a generalised radius for all shapes - i.e. the distance from the 
// centrePoint to the furthestPointFromCentre
//
//

class SimExtents {
  PVector minExtents;
  PVector maxExtents;
  PVector centrePoint;
  PVector furthestPointFromCentre;

  public SimExtents() {
    
  }

  public SimExtents(PVector[] points) {
    calculateExtents(points);
  }
  

  void calculateExtents(PVector[] points) {


    float minx = Float.MAX_VALUE;
    float miny = Float.MAX_VALUE;
    float minz = Float.MAX_VALUE;

    float maxx = -Float.MAX_VALUE;
    float maxy = -Float.MAX_VALUE;
    float maxz = -Float.MAX_VALUE;
    for (PVector p : points) {
      if (p.x < minx) minx = p.x;
      if (p.y < miny) miny = p.y;
      if (p.z < minz) minz = p.z;
      if (p.x > maxx) maxx = p.x;
      if (p.y > maxy) maxy = p.y;
      if (p.z > maxz) maxz = p.z;
    }
    minExtents = new PVector(minx, miny, minz);
    maxExtents = new PVector(maxx, maxy, maxz);

    centrePoint = minExtents.copy();
    centrePoint.lerp(maxExtents, 0.5);

    // need to work out point furthest from the centre point
    PVector furthest = centrePoint.copy();
    for (PVector p : points) {
      if (centrePoint.dist(p) > centrePoint.dist(furthest)) {
        furthestPointFromCentre = p.copy();
      }
    }
  }
  
  PVector getMin(){
    return minExtents;
  }
  
  PVector getMax(){
    return maxExtents;
  }
  
  PVector getCentre(){
    return centrePoint;
  }

  PVector getFurthestPoint() {
    return furthestPointFromCentre;
  }
  
  float getRadius() {
    return furthestPointFromCentre.dist(centrePoint);
  }

  void drawMe() {
    SimBox bb = new SimBox();
    bb.setWithExtents(minExtents, maxExtents);
    bb.drawMe();
  }
  
  SimBox getSimBox(){
    SimBox bb = new SimBox();
    bb.setWithExtents(minExtents, maxExtents);
    return bb;
  }

  
  
  // SimExtents intersection methods are in the Intersections tab
  
}




////////////////////////////////////////////////////////////////////////////////////////
// SimRay.
// Defines a ray, which in turn is defined by a point, regarded as the ray's origin, and a direction vector
// which is normalised. A ray's intersection with most shapes can be found (using the algorithms in the intersections tab).
// If an intersection is found, then further information is set within the ray: the intersectionPoint, and interectionNormal and
// (if appropriate) a list of intersected triangles. This can then be recovered from the ray.
//
// Intersections with spheres, boxes and meshes give rise to a precise intersection point.
// In some cases a ray will intersect with with multiple triangles, in which case the nearest triangle to the ray's origin is used to determine
// the intersection point, but the full list of intersecting triangles can be recoved from the ray if needs be.
//
//

class SimRay {

  // defined by
  PVector origin = vec(0, 0, 0);
  PVector direction = vec(0, 0, -1);


  // interection details. These are set once an
  // intersection has been found
  //
  boolean intersectionFound = false;

  // the sim object intersected. Set to null if not a SimObject (may be a SimTriangle)
  private Sim3DObject intersectionSim3DObject = null;

  // the exact point of intersection
  private PVector intersectionPoint;

  // this is the surface normal of the intersection surface point, in world units.
  private PVector intersectionNormal;

  // nearest triangle and a list of triangles intersected - 0nly used IF the intersected object is made of triangles
  SimTriangle nearestIntersectingTriangle = null;
  ArrayList<SimTriangle> intersectingTriangleList = new ArrayList<SimTriangle>();



  public SimRay() {
  }

  public SimRay(PVector pOrig, PVector v2) {
    origin = pOrig.copy();
    direction = v2.copy();
    direction.normalize();
  }

  void setWithOriginAndSecondPoint(PVector pOrig, PVector v2) {
    origin = pOrig.copy();
    direction = PVector.sub(v2, pOrig);
    direction.normalize();
  }

  PVector getDirection(){
    return direction.copy();
  }
  
  PVector getStartPoint(){
    return origin.copy();
  }

  //////////////////////////////////////////////////////////////////////////////
  // once an intersection calculation has been made, the intersection can be queried
  //

  boolean isIntersection() {
    return intersectionFound;
  }

  public PVector getIntersectionPoint() {
    // this returns the intersection point nearest to the Ray's origin
    return this.intersectionPoint;
  }

  public PVector getIntersectionNormal() {
    return this.intersectionNormal;
  }

  int getNumIntersections() {
    // this works only with triangulated shapes (so does not work with spheres)
    return intersectingTriangleList.size();
  }


  PVector getPointAtDistance(float d) {
    // returns the point on the ray at distance d from the origin
    PVector p1 = PVector.mult(direction, d);
    return PVector.add(p1, origin);
  }

  // utility methods
  SimRay copy() {
    SimRay sr =  new SimRay();
    sr.origin = this.origin.copy();
    sr.direction = this.direction.copy();

    return sr;
  }
  
  void drawMe(float len) {
    pushStyle();
    PVector farPoint = getPointAtDistance(len);
    strokeWeight(g.strokeWeight);
    stroke(g.strokeColor);
    line(origin.x, origin.y, origin.z, farPoint.x, farPoint.y, farPoint.z);
    popStyle();
  }


  ///////////////////////////////////////////////////////////////////////////////////////////////////////
  // SimRay multiple triangle intersection calculations
  // would like these to be private, but have to be public
  //
  //
  // not to be used by end-user. Used internally
  void setIntersectionNormal(PVector n) {
    this.intersectionNormal = n.copy();
    this.intersectionNormal.normalize();
  }


  public boolean addIntersectingTriangle(SimTriangle t) {
    boolean intersects = intersections_TriangleRay(t, this);


    if ( intersects ) {
      intersectingTriangleList.add(t);
      return true;
    }
    return false;
  }

  public void clearIntersectingTriangles() {
    intersectingTriangleList.clear();
  }

  PVector getNearestTriangleIntersectionPoint() {
    PVector nearestIntersectionPoint = vec(0, 0, 0);
    float nearestIntersectionDistance = 10000000000.0;
    PVector nearestSurfaceNormal = vec(0, 0, 0);
    for (SimTriangle t : intersectingTriangleList) {

      if ( intersections_TriangleRay(t, this) ) {
        PVector rayIntersectionPoint = getIntersectionPoint();
        PVector rayOrigin = origin.copy();
        float thisPointDistToRayOrigin = PVector.dist(rayIntersectionPoint, rayOrigin);
        if (thisPointDistToRayOrigin < nearestIntersectionDistance) {
          nearestIntersectionDistance = thisPointDistToRayOrigin;
          nearestIntersectionPoint = rayIntersectionPoint;
          nearestSurfaceNormal = t.surfaceNormal();
          nearestIntersectingTriangle = t;
        }//end if
      }//end if
    }// end for
    this.intersectionPoint = nearestIntersectionPoint;
    this.setIntersectionNormal(nearestSurfaceNormal);
    return nearestIntersectionPoint;
  }// end method
}
// end SimRay class



////////////////////////////////////////////////////////////////////////////
// TETI EDITION ADDITION vvvv
// SimTriangle
// simple containter for a 3d triange
//
class SimTriangle {
  public PVector p1, p2, p3;
  public PVector normal;          // cached normal
  SimExtents cachedExtents;

  public SimTriangle(PVector p1, PVector p2, PVector p3) {
    this.p1 = p1;
    this.p2 = p2;
    this.p3 = p3;
    computeNormal();             // compute normal at creation
    cacheExtents();
  }

  public SimTriangle() {
    this.p1 = new PVector(0, 0, 0);
    this.p2 = new PVector(1, 0, 0);
    this.p3 = new PVector(0, 0, 1);
    computeNormal();
    cacheExtents();
  }

  public SimTriangle copy(){
    return new SimTriangle(p1.copy(), p2.copy(), p3.copy());
  }

  void flip() {
    PVector tmp = p2;
    p2 = p3;
    p3 = tmp;
    computeNormal();
    cacheExtents();
  }

  void drawMe() {
    beginShape(TRIANGLE);
    vertex(p1.x, p1.y, p1.z);
    vertex(p2.x, p2.y, p2.z);
    vertex(p3.x, p3.y, p3.z);
    endShape(CLOSE);
  }

  // ------------------------------------------------------------------
  // Compute and cache a normalized surface normal
  void computeNormal() {
    PVector edge1 = PVector.sub(p2, p1);
    PVector edge2 = PVector.sub(p3, p1);
    normal = edge1.cross(edge2);
    if (normal.mag() > 0) normal.normalize(); // avoid zero-length
  }

  PVector surfaceNormal() {
    // return cached normal for performance
    if (normal == null) computeNormal();
    return normal.copy();
  }

  SimExtents getExtents() {
    if (cachedExtents != null) return cachedExtents;
    PVector[] points = {p1, p2, p3};
    cachedExtents = new SimExtents(points);
    return cachedExtents;
  }

  void cacheExtents() {
    cachedExtents = null;
    getExtents();
    computeNormal(); // keep normal in sync
  }

  PVector closestPointOnTriangle(PVector p) {
    PVector a = p1.copy();
    PVector b = p2.copy();
    PVector c = p3.copy();
    PVector ab = subV(b, a);
    PVector ac = subV(c, a);
    PVector ap = subV(p, a);

    float d1 = dotV(ab, ap);
    float d2 = dotV(ac, ap);
    if (d1 <= 0 && d2 <= 0) return a;

    PVector bp = subV(p, b);
    float d3 = dotV(ab, bp);
    float d4 = dotV(ac, bp);
    if (d3 >= 0 && d4 <= d3) return b;

    PVector cp = subV(p, c);
    float d5 = dotV(ab, cp);
    float d6 = dotV(ac, cp);
    if (d6 >= 0 && d5 <= d6) return c;

    float vc = d1 * d4 - d3 * d2;
    if (vc <= 0 && d1 >= 0 && d3 <= 0) {
      float v = d1 / (d1 - d3);
      return addV(a, multV(ab, v));
    }

    float vb = d5 * d2 - d1 * d6;
    if (vb <= 0 && d2 >= 0 && d6 <= 0) {
      float v = d2 / (d2 - d6);
      return addV(a, multV(ac, v));
    }

    float va = d3 * d6 - d5 * d4;
    if (va <= 0 && (d4 - d3) >= 0 && (d5 - d6) >= 0) {
      float v = (d4 - d3) / ((d4 - d3) + (d5 - d6));
      PVector cb = subV(c, b);
      return addV(b, multV(cb, v));
    }

    float denom = 1.0f / (va + vb + vc);
    float v = vb * denom;
    float w = vc * denom;
    return addV(addV(a, multV(ab, v)), multV(ac, w));
  }

  void applyTransform(Sim3DObject simObj){
    PVector[] points = {p1, p2, p3};
    PVector[] transformedPoints = simObj.transformVertices(points);
    p1 = transformedPoints[0];
    p2 = transformedPoints[1];
    p3 = transformedPoints[2];
    cacheExtents();
  }
}
// TETI EDITION ADDITION ^^^





////////////////////////////////////////////////////////////////////////////
// SimFacet
// Two triangles make a facet
//
class SimFacet {
  // do not manipuate the triangles independently as they must share 2 vertices
  private SimTriangle tri1;
  private SimTriangle tri2;

  public SimFacet() {
    setVertices( vec(0,0,0), vec(1,0,0), vec(1,0,1), vec(0,1,0) );
  }

  
  public SimFacet(PVector p1, PVector p2, PVector p3, PVector p4) {
    setVertices(p1, p2, p3, p4);
  }

  void setVertices( PVector p1, PVector p2, PVector p3, PVector p4) {
    // give 4 vertices of a facet, in either winding, create a correct 2-triangle facet
    // currently cannot handle "butterfly" quads
    tri1 = new SimTriangle(p1, p2, p3);
    tri2 = new SimTriangle(p1, p3, p4);
  }

  PVector[] getVertices() {
    PVector[] verts = new PVector[4];
    verts[0] = tri1.p1.copy();//p1
    verts[1] = tri1.p2.copy();//p2
    verts[2] = tri1.p3.copy();//p3
    verts[3] = tri2.p3.copy();//p4
    return verts;
  }
  
  SimTriangle getTriangle1(){
    return tri1.copy(); 
  }
  
  SimTriangle getTriangle2(){
    return tri2.copy(); 
  }
  
  SimExtents getExtents() {
    return new SimExtents(getVertices());
  }
  
  void applyTransform(Sim3DObject simObj){
    // a Sim3DObject is used to set and apply transforms to the SimFacet.
    PVector[] transformedPoints = simObj.transformVertices(getVertices());
    setVertices(  transformedPoints[0],transformedPoints[1],transformedPoints[2],transformedPoints[3]);
  }
  
  void drawMe(){
    tri1.drawMe();
    tri2.drawMe();
  }
  
}
