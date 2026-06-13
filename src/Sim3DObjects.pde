///////////////////////////////////////////////////////////////////////////////////////
// This tab contains the code for creating and drawing the main 4 different types of Sim3DObjects:-
// SimSphere, SimBox, SimModel, SimSurfaceMesh. They are all derived from the Sim3DObject base class.
//
// These are the main 3D shapes you can make, transform and draw around 3D space, 
// You can get their location, and check if anything is intersecting and so are the main resource for making
// your 3D simulations.

///////////////////////////////////////////////////////////////////////////////////////
//
// SimObject base class - contains code shared by all SimObjects SimSphere, SimBox, SimModel and SimSurfaceMesh
// It includes...
// Transformation code - for setting the scale, rotation and tranlsation of the object
// Access to intersections code - handy access to the correct intersection code in the intersections tab
//
//

abstract class Sim3DObject{

  ///////////////////////////////////////////////
  // all Sim3DObjects have to write their own getTransformedExtents() and drawMe() methods
  // so it is declared as abstract here, forcing the declation in the sub-classes
  //
  abstract void drawMe();
  
  abstract SimExtents getTransformedExtents();
  
  ///////////////////////////////////////////////
  // This can be used to give a "friendly" name to an object
  String myTag = "unnamed";

  
   
  ////////////////////////////////////////////////////////////////////
  // Intersection methods giving you simple access to the correct intersection code
  // (in the Intersections tab)
  //
  public boolean intersects(Sim3DObject other){
    return intersections_Sim3DObjectSim3DObject(this, other);
    
  }
  
  public boolean intersects(SimRay ray){
    return intersections_Sim3DObjectRay( this,  ray);
  }
  
  public boolean intersects(PVector point){
    return intersections_Sim3DObjectPoint(this,  point);
  }
  
  
  
  ///////////////////////////////////////////////////////////////////////
  // This part is the main point (or vertex) transformation code 
  // It transforms the model-space geometry of the shape into the world-space, transformed state
  // Each different type of shape will submit it's own gemtry to this code
  // in oder to draw it and create a transformed shape for location and collision purposes
  //
  // Curently the implementation breaks the transformation down into its three stages; scale, rotation and translation
  // The rotation stage uses pre-cached sin and cos values (all vertces use the same sin and cos values, 
  // in a particular 3D rotaton, so it makes sense to pre-calulate them at the start)
  // This could be sped-up by using a matrices instead, but would not be so instructive!
  //
  // The tranformation settings
  float scale = 1;
  float rotateX, rotateY, rotateZ = 0.0;
  PVector translate = new PVector(0, 0, 0);
  
  
  private float sinRotateX, sinRotateY, sinRotateZ = 0;
  private float cosRotateX=1, cosRotateY=1, cosRotateZ=1;
  
  void preCalculateSinCosRotations(){
    sinRotateX = sin(rotateX); 
    sinRotateY = sin(rotateY);
    sinRotateZ = sin(rotateZ);
    cosRotateX = cos(rotateX);
    cosRotateY = cos(rotateY);
    cosRotateZ = cos(rotateZ);
    
  }
  
  void setIdentityTransform() {
    // sets the tranform to the same as the model-space
    setTransform( 1, 0, 0, 0, vec(0, 0, 0));
  }
  
  //////////////////////////////////////////////////////////////////////////
  // A one-stop-shop for setting the transform
  //
  //
  void setTransform(float scale, float rotateX, float rotateY, float rotateZ, PVector translate) {
    setScale(scale);
    setTranslation(translate);
    setRotation( rotateX,  rotateY,  rotateZ);
  }
  
  //////////////////////////////////////////////////////////////////////////
  // setting individual parts of the tranform
  //
  //
  void setScale(float s){
    if( nearZero(s) ) {
      println("You are scaling to near zero - not allowed");
      return;
    }
    this.scale = s;
    
  }
  
  
  void setRotation(float rotateX, float rotateY, float rotateZ){
    this.rotateX = rotateX;
    this.rotateY = rotateY;
    this.rotateZ = rotateZ;
    preCalculateSinCosRotations();
  }
  
  void setTranslation(PVector t){
    this.translate = t.copy();
  }
  
  void setTranslation(float tX, float tY, float tZ){
    setTranslation( new PVector(tX,tY,tZ) );
  }
  
  
  //////////////////////////////////////////////////////////////////////////
  // Tweaking the current transform by an amount. 
  // It is unlikely that the scale will be tweaked, so it is not facilitated
  //
  void tweakRotation(float rotateX, float rotateY, float rotateZ){
    this.rotateX += rotateX;
    this.rotateY += rotateY;
    this.rotateZ += rotateZ;
    preCalculateSinCosRotations();
  }
  
  void tweakTranslation(PVector t){
    this.translate.add(t);
  }
  
  void tweakTranslation(float tX, float tY, float tZ){
    tweakTranslation( new PVector(tX,tY,tZ) );
  }

  
  ////////////////////////////////////////////////////////////////////
  // Transformation of vertex code
  // given a model-space shape vertex p, transform the point in the order
  // scale, rotate x,y,z, translate
  // This uses sin/cosine triganometry, the sin/cos values are pre-calculated
  // when setting the rotation, but could be sped up more using matrices
  //
  //
  public PVector transform(PVector pIn) {
    // because we definately don't want to affect the vector coming in!
    PVector p = pIn.copy();
    
    // first scale the point
    PVector scaled = p.mult(this.scale);

    float x = scaled.x;
    float y = scaled.y;
    float z = scaled.z;

    // do the rotation around the 3 axis
    // rotate round X axis
    float y1 = y*cosRotateX  - z*sinRotateX;
    float z1 = y*sinRotateX  + z*cosRotateX ;
    float x1 = x;
    // rotate round Y axis
    float z2 = z1*cosRotateY  - x1*sinRotateY;
    float x2 = z1*sinRotateY +  x1*cosRotateY;
    float y2 = y1;
    // rotate round Z axis
    float x3 = x2*cosRotateZ  - y2*sinRotateZ ;
    float y3 = x2*sinRotateZ  + y2*cosRotateZ ;
    float z3 = z2;

    PVector rotated = new PVector(x3, y3, z3);

    
    // finally add-in the translation
    PVector translated = rotated.add(translate);
    return translated;
  }
  
  ////////////////////////////////////////////////////////////////////
  // Transformation of vertex code
  // given an array of model-space vertices 
  // return an array of transformed points
  PVector[] transformVertices(PVector[] vertices) {
    int numVerts = vertices.length;
    PVector[] transformedVerts = new PVector[numVerts];
    for (int n = 0; n < numVerts; n++) {
      transformedVerts[n] = transform(vertices[n]);
    }
    return transformedVerts;
  }


  SimExtents getTransformedExtents(PVector[] vertices) {
    PVector[] trasformedvertices = transformVertices(vertices);
    // the getExtents() method is in intersections tab
    return new SimExtents(trasformedvertices);
  }
  
  float getTransformedRadius(){
    SimExtents extents = getTransformedExtents();
    return extents.getRadius();
  }
  
  PVector getTransformedCentre(){
    SimExtents extents = getTransformedExtents();
    return extents.centrePoint;
  }
  
  /////////////////////////////////////////////////////////
  // For internal use only below here
  
  /////////////////////////////////////////////////////////
  // Useful shorthand function that draws a transformed vertices
  // used by many draw methods currently used bu SimBox and SimSurfacemesh to draw their transformed versions
  public void  drawTransformedVertex(PVector v) {
    PVector transformedVector = transform(v);
    vertex(transformedVector.x, transformedVector.y, transformedVector.z);
  }
  
  //////////////////////////////////////////////
  // useful for interrogating a SimObject to see what specific type it is
  // especially used in the intersections code. Returns the string of the class name, e.g. "SimSphere" etc..
  String getClassName(){
    return this.getClass().getSimpleName();
  }

  
}




//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// SimSphere
//

class SimSphere extends Sim3DObject {
  // Model-space description, the origin is at (0,0,0)
  // and the sphere has a set radius
  private float radius = 1;
  
  
  public SimSphere() {
    radius = 1;
  }

  public SimSphere(float rad) {
    radius = rad;
  }

  public PVector getTransformedCentre() {
    return transform( vec(0,0,0) );
  }

  public void setRadius(float r) {
    this.radius = r;
  }

  float getTransformedRadius() {
    float tradius = this.radius;
    tradius *= this.scale;
    return tradius;
  }
  
  SimExtents getTransformedExtents(){
    // returns an extents array of PVectors
    // used for trivial collision detection, this is quicker than doing a sphere/sphere 
    // intersection test (no sqrt) but not accurate.
    float r = getTransformedRadius();
    PVector radiusVector = new PVector(r,r,r);
    
    SimExtents extents = new SimExtents();
    
    PVector centre = getTransformedCentre();
    extents.minExtents = PVector.sub( centre, radiusVector);
    extents.maxExtents = PVector.add( centre, radiusVector);
    extents.centrePoint = centre.copy();
    extents.furthestPointFromCentre = new PVector(0,r,0);
    return extents;
  }


  void drawMe() {
    
    float r = getTransformedRadius();
    PVector transCen = getTransformedCentre();
  
    pushMatrix();
    translate(transCen.x, transCen.y, transCen.z);
    sphere(r); 
    popMatrix();
  }
  
  
} // end of SimSphere class

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// SimBox, for Axis Aligned Boxes (AABB) and Oriented  Boxes (Oriented Box or OB)
//
//


class SimBox extends Sim3DObject{
  // It is defined in model-space as an Axis-Aligned box
  // of user-defined width, height and depth. Its origin is in the centre 
  // of this box.
  PVector minCorner;
  PVector maxCorner;

  // index of top, and bottom vertices
  int
    T1 = 0, 
    T2 = 1, 
    T3 = 2, 
    T4 = 3, 
    B1 = 4, 
    B2 = 5, 
    B3 = 6, 
    B4 = 7;


  PVector[] vertices;


  public SimBox() {
    setDimensions(1,1,1);
  }


  SimBox(float w, float h, float d){
    setDimensions(w,h,d);
  }
  
  // necessary for determining if the box is AA or Oriented
  boolean isOriented() {
     if ( this.rotateX == 0 &&  this.rotateY == 0 && this.rotateZ == 0) return false;
    return true;
  }
  
  // see the OrientedBox class at the bottom of the Intersections tab
  OrientedBox getOrientedBox(){
    return new OrientedBox(this);
  }
  

  void setDimensions(float w, float h, float d) {
    float halfW = w/2;
    float halfH = h/2;
    float halfD = d/2;
    
    PVector c1 = new PVector(-halfW, -halfH, -halfD );
    PVector c2 = new PVector(halfW, halfH, halfD );
    setWithExtents(c1,c2);
  }
  
  void setWithExtents(PVector c1, PVector c2) {
    // not really one for the user to use. Resets the tarnsforms to the identity
    // then creates a AABox with these extents.
    vertices = new PVector[8];
    // sorts the data into min x,y,z, and max x,y,z
    // does not yet catch "illegal" boxes (zero width etc)
    setIdentityTransform();
    float minx = min(c1.x, c2.x);
    float miny = min(c1.y, c2.y);
    float minz = min(c1.z, c2.z);

    float maxx = max(c1.x, c2.x);
    float maxy = max(c1.y, c2.y);
    float maxz = max(c1.z, c2.z);

    minCorner = new PVector(minx, miny, minz);
    maxCorner = new PVector(maxx, maxy, maxz);
    createVertices();
  }

  int getNumFacets() { 
    return 6;
  }

  SimExtents getTransformedExtents() {
      return getTransformedExtents(vertices);
  }
  
  float getTransformedRadius(){
    return getTransformedExtents().getRadius();
    
  }

  private void createVertices() {
    //top corner
    float tx = minCorner.x;
    float ty = minCorner.y;
    float tz = minCorner.z;

    float bx = maxCorner.x;
    float by = maxCorner.y;
    float bz = maxCorner.z;
    // top face corners
    vertices[T1] = new PVector(tx, ty, tz);
    vertices[T2] = new PVector(tx, ty, bz);
    vertices[T3] = new PVector(bx, ty, bz);
    vertices[T4] = new PVector(bx, ty, tz);
    // bottom face corners
    vertices[B1] = new PVector(tx, by, tz);
    vertices[B2] = new PVector(tx, by, bz);
    vertices[B3] = new PVector(bx, by, bz);
    vertices[B4] = new PVector(bx, by, tz);
  }

  //////////////////////////////////////////////////////////////////////
  // returns the transformed values depending on boolean
  //
  //
  public PVector getTransformedCentre() {
    // sould work for both AABB and OBB's
    PVector minCornerTrans = transform(minCorner);
    PVector maxCornerTrans = transform(maxCorner);

    return minCornerTrans.lerp(maxCornerTrans, 0.5);
  }



  SimFacet getTransformedFacet(int num) {
    // returns the transformed facet
    // 0 = top, 1 = front, 2 = left, 3 = right, 4 = back, 5 = bottom 
    int v1, v2, v3, v4;

    //forward face
    // initialise them to this as default
    v1 = T1;
    v2 = T4;
    v3 = B4;
    v4 = B1;

    // top
    if (num == 0) {
      v1 = T1;
      v2 = T2;
      v3 = T3;
      v4 = T4;
    }

    //lhs face 
    if (num == 2) {
      v1 = T1;
      v2 = B1;
      v3 = B2;
      v4 = T2;
    }

    //rhs face 
    if (num == 3) {
      v1 = T4;
      v2 = T3;
      v3 = B3;
      v4 = B4;
    }

    //back face 
    if (num == 4) {
      v1 = T2;
      v2 = B2;
      v3 = B3;
      v4 = T3;
    }

    //bottom face 
    if (num == 5) {
      v1 = B1;
      v2 = B4;
      v3 = B3;
      v4 = B2;
    }

    PVector p1 = transform(vertices[v1]);
    PVector p2 = transform(vertices[v2]);
    PVector p3 = transform(vertices[v3]);
    PVector p4 = transform(vertices[v4]);

    return new SimFacet(p1, p2, p3, p4);
  }
  
  
  PVector[] getTransformedAxes(){
    // used by the OrientedBox class when needed to get the SimBox's axes
    // returns the full length axes in an array W,H,D as vectors
    PVector t1 = transform(vertices[T1]);
    PVector t2 = transform(vertices[T2]);
    PVector t4 = transform(vertices[T4]);
    PVector b1 = transform(vertices[B1]);
    
    PVector[] axes = new PVector[3];
    
    axes[0] = subV(t4,t1);
    axes[1] = subV(b1,t1);
    axes[2] = subV(t2,t1);
    
    
    return axes;
  }


  // draws the transformed shape
  public void drawMe() {
    //topface
    beginShape();
    drawTransformedVertex(vertices[T1]);
    drawTransformedVertex(vertices[T2]);
    drawTransformedVertex(vertices[T3]);
    drawTransformedVertex(vertices[T4]);
    endShape(CLOSE);


    //forward face
    beginShape();
    drawTransformedVertex(vertices[T1]);
    drawTransformedVertex(vertices[T4]);
    drawTransformedVertex(vertices[B4]);
    drawTransformedVertex(vertices[B1]);
    endShape(CLOSE);


    //lhs face 
    beginShape();
    drawTransformedVertex(vertices[T1]);
    drawTransformedVertex(vertices[B1]);
    drawTransformedVertex(vertices[B2]);
    drawTransformedVertex(vertices[T2]);
    endShape(CLOSE);


    //rhs face 
    beginShape();
    drawTransformedVertex(vertices[T4]);
    drawTransformedVertex(vertices[T3]);
    drawTransformedVertex(vertices[B3]);
    drawTransformedVertex(vertices[B4]);
    endShape(CLOSE);


    //back face 
    beginShape();
    drawTransformedVertex(vertices[T2]);
    drawTransformedVertex(vertices[B2]);
    drawTransformedVertex(vertices[B3]);
    drawTransformedVertex(vertices[T3]);
    endShape(CLOSE);

    //bottom face 
    beginShape();
    drawTransformedVertex(vertices[B1]);
    drawTransformedVertex(vertices[B4]);
    drawTransformedVertex(vertices[B3]);
    drawTransformedVertex(vertices[B2]);
    endShape(CLOSE);
  }
} // end of SimBox class



//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// SimModel
// This is a shape initialsed with a PShape, or by loading an OBJ file.
// The geometry of the shape is not used per-se for any collision detection, instead we use a bounding volume.
// This is either a SimBox or a SimSphere.
// 
// 

class SimModel extends Sim3DObject{
  // The model-space represention is the model, as loaded from file,
  // and the Bounding Box and Bounding Sphere, which are initialised to accurately 
  // contain the model. 
  // 
  
  //                                                                           TETI EDITION ADDITIONS vvv
  
  // model-space triangles (constructed once when model is loaded)
  private SimTriangle[] modelTriangles;           
  
  // world-space (transformed) triangle cache
  private SimTriangle[] transformedTriangles;           
  
  // true when transformedTriangles must be rebuilt
  private boolean trianglesDirty = true;
  
  //                                                                           TETI EDITION ADDITIONS ^^^
  
  // stores the untransformed (model-space) model
  private PShape originalModel;
  private PVector[] rawvertices;
  
  // bounding volumes
  private SimSphere boundingSphere = new SimSphere();
  private SimBox boundingBox = new SimBox();

  private String preferredBoundingVolume;
  public int boundingVolumeTransparency = 50;
  public boolean showBoundingVolume = false; // TETI EDIT

  public SimModel() {
  }
  
  public SimModel(String filename){
    PShape mod = loadShape(filename);
    if(mod == null){
      println("SimModel: cannot load file name ", filename);
      return;
    }
    setWithPShape(mod);
    
  }
  
  public SimModel(PShape shapeIn){
    setWithPShape(shapeIn);
  }

  //                                                                           TETI EDITION ADDITIONS vvv
    
  private void buildModelSpaceTriangles() {

    if (originalModel == null) return;

    // get tessellated PShape with triangles only
    PShape flat = originalModel.getTessellation();
    int vcount = flat.getVertexCount();
    if (vcount <= 0) {
      modelTriangles = new SimTriangle[0];
      trianglesDirty = true;
      return;
    }

    // guard: vertex count should be multiple of 3 for triangles
    int triCount = vcount / 3;
    modelTriangles = new SimTriangle[triCount];

    for (int i = 0; i < triCount; i++) {
      // each triangle uses vertices 3*i, 3*i+1, 3*i+2
      PVector a = flat.getVertex(i * 3);
      PVector b = flat.getVertex(i * 3 + 1);
      PVector c = flat.getVertex(i * 3 + 2);

      // create a SimTriangle and copy points (SimTriangle uses p1,p2,p3 in your code)
      SimTriangle t = new SimTriangle();
      t.p1 = a.copy();
      t.p2 = b.copy();
      t.p3 = c.copy();

      // optionally cache triangle extents / normal if the SimTriangle provides methods
      // e.g. t.cacheExtents(); // if implemented

      modelTriangles[i] = t;
    }

    // mark transformed cache dirty since model-space triangles created/changed
    trianglesDirty = true;
  }


public SimTriangle[] getTransformedTriangles() {
    if (modelTriangles == null) return new SimTriangle[0];

    int n = modelTriangles.length;
    transformedTriangles = new SimTriangle[n];

    for (int i = 0; i < n; i++) {
        SimTriangle mt = modelTriangles[i];
        PVector v1 = transform(mt.p1.copy());
        PVector v2 = transform(mt.p2.copy());
        PVector v3 = transform(mt.p3.copy());

        SimTriangle t = new SimTriangle();
        t.p1 = v1;
        t.p2 = v2;
        t.p3 = v3;
        t.surfaceNormal();   // essential for SAT
        t.cacheExtents();    // essential for early-out checks

        transformedTriangles[i] = t;

        //println("Triangle " + i + ": " + t.p1 + " " + t.p2 + " " + t.p3);
    }

    return transformedTriangles;
}


  public SimTriangle[] getTransformedTrianglesForCollision() {
    return getTransformedTriangles();
  }

  void setTransform(float scale, float rotateX, float rotateY, float rotateZ, PVector translate) {
    super.setTransform(scale, rotateX, rotateY, rotateZ, translate);
    trianglesDirty = true;
  }

  void setScale(float s) {
    super.setScale(s);
    trianglesDirty = true;
  }

  void setRotation(float rotateX, float rotateY, float rotateZ) {
    super.setRotation(rotateX, rotateY, rotateZ);
    trianglesDirty = true;
  }

  void setTranslation(PVector t) {
    super.setTranslation(t);
    trianglesDirty = true;
  }

  void tweakRotation(float rotateX, float rotateY, float rotateZ) {
    super.tweakRotation(rotateX, rotateY, rotateZ);
    trianglesDirty = true;
  }

  void tweakTranslation(PVector t) {
    super.tweakTranslation(t);
    trianglesDirty = true;
  }

  //                                                                           TETI EDITION ADDITIONS ^^^

  void setWithPShape(PShape shapeIn) {
    originalModel = shapeIn;
    calculateBoundingGeometry();
    buildModelSpaceTriangles(); //  <<< TETI EDITION ADDITION
    setIdentityTransform();
  }

  void calculateBoundingGeometry() {
    // called at the start to create a box and sphere that fit onto
    // the (as yet) un-transformed model
    // Uses the model-space geometry
    rawvertices = getRawVertices();
    SimExtents extents = new SimExtents(rawvertices);
    
    boundingBox = new SimBox();
    boundingBox.setWithExtents(extents.minExtents, extents.maxExtents);
    
    
    boundingSphere = new SimSphere(extents.getRadius());
   
    preferredBoundingVolume = "box";
  }
  
  SimExtents getTransformedExtents(){
    return getTransformedExtents(rawvertices);
  }

  void setPreferredBoundingVolume(String BOXorSPHERE){
    String s = BOXorSPHERE.toLowerCase();
    if(s.equals("box")) preferredBoundingVolume = "box";
    if(s.equals("sphere")) preferredBoundingVolume = "sphere";
  }
  
  Sim3DObject getTransformedBoundingVolume(){
    
    if(preferredBoundingVolume.equals("box")) {
      return getTransformedBoundingBox();
    } else {  
      return getTransformedBoundingSphere(); 
    }
  }
  
  void showBoundingVolume(boolean show){
    showBoundingVolume = show;
  }


  PVector[] getRawVertices() {
    PShape flatmodel = originalModel.getTessellation(); 

    int total = flatmodel.getVertexCount();
    
    //println("orig model vertext = ", flatmodel.getVertexCount(), " tessellation vertext count ", flatmodel.getVertexCount());
    
    PVector[] vertices = new PVector[total];
    for (int j = 0; j < total; j++) {
      vertices[j] = flatmodel.getVertex(j);
    }
    return vertices;
  }
  

  SimSphere getTransformedBoundingSphere() {
    boundingSphere.setTransform( this.scale, this.rotateX, this.rotateY, this.rotateZ, this.translate);
    return boundingSphere;
  }

  SimBox getTransformedBoundingBox() {
    boundingBox.setTransform( this.scale, this.rotateX, this.rotateY, this.rotateZ, this.translate);
    return boundingBox;
  }


  void drawMe() {
    // this method temporarily hijacks the original model
    // and temporarily tranforms it using Java's own 3D transformation code, then draws it 
    // , then resets the original model
    originalModel.resetMatrix();
    originalModel.scale(this.scale);
    originalModel.rotateX(this.rotateX);
    originalModel.rotateY(this.rotateY);
    originalModel.rotateZ(this.rotateZ); 
    originalModel.translate(this.translate.x, this.translate.y, this.translate.z);
    shape(originalModel);
    originalModel.resetMatrix();
    
    if(showBoundingVolume) drawBoundingVolume();
  }
  
  void drawBoundingVolume(){
    if(preferredBoundingVolume.equals("sphere")) drawBoundingSphere();
    if(preferredBoundingVolume.equals("box")) drawBoundingBox();
  }

  void drawBoundingSphere() {
    color cc = g.fillColor;
    
    //cc = color(255,0,0);
    pushStyle();
    fill( red(cc),green(cc), blue(cc),boundingVolumeTransparency);
    SimSphere bs = getTransformedBoundingSphere();
    //println("drawing sphere radius ", bs.radius, " at " , bs.translate);
    bs.drawMe();
    popStyle();
  }

  void drawBoundingBox() {
    SimBox bb = getTransformedBoundingBox();
    color cc = g.fillColor;
    
    //cc = color(255,0,0);
    pushStyle();
    fill( red(cc),green(cc), blue(cc),boundingVolumeTransparency);
    bb.drawMe();
    popStyle();
  }
  
  
} // end of SimModel class


////////////////////////////////////////////////////////////////////////////
// SimSurfaceMesh - a grid-like mesh for creating surfaces and landscapes
//
//
// The surface is instantiated in the y==0 plane, and extends in the x and z axes with centre of the mesh at (0,0,0).
// The size of the mesh in 3D units is determined
// by the sizeOfFacet parameter multiplied by the number of facets in x and z. A facet is a single rectangular grid cell of 
// the full mesh. Each facet is composed of two triangles.
// 
//
// Each vertices of the mesh can be given a Y height, set by using setVertexY(int vertexX, int vertexZ, float y), or 
// more easily by using an image as a height-map, setHeightsFromImage(PImage im, float maxAltitude),  so as to form a landscape
//
// The mesh can also be texture mapped
//
// SimTriangles and SimFactes are defined in the SimFunctions tab


class SimSurfaceMesh  extends Sim3DObject{

    int numFacetsX, numFacetsZ;
    
    // The "model-space", or cannonical form of the mesh
    PVector[] meshVertices;

    //public int numTriangles = 0;
    // mesh coordinates are stored in this array. It is made at the start
    
    //SimRay pick information
    //public int rayIntersectionTriangleNum; 
    //public PVector rayIntersectionPoint;
    
    PImage textureMap;
    
    public SimSurfaceMesh(int numInX, int numInZ, float sizeOfFacet)
    {
        // numInX and Z represent the number of Facets generated.
        // The number of triangles is (number of Facets)*2
        
        // the number of vertices to make this is (numFacetsX+1) * (numFacetsY+1) 
        numFacetsX = numInX;
        numFacetsZ = numInZ;
        //meshVertices = new ArrayList<PVector>();
        meshVertices = new PVector[(numFacetsX+1)*(numFacetsZ+1)];
        
        float centreOffsetX = (numFacetsX * sizeOfFacet)/2f;
        float centreOffsetZ = (numFacetsZ * sizeOfFacet)/2f;
        
        
        for(int z = 0; z < numFacetsZ+1; z++)
        {
            for (int x = 0; x < numFacetsX+1; x++)
            {
                float xf = x * sizeOfFacet - centreOffsetX;
                float yf = 0.0f;
                float zf = z * sizeOfFacet - centreOffsetZ;
                setMeshVertex(x,z,  new PVector(xf, yf, zf) );
            }
            
        }

    }
    
    
    void setHeightsFromImage(PImage im, float maxAltitude){
    
      int numInX = getNumVerticesX();
      int numInZ = getNumVerticesZ();
      int imWidth = im.width;
      int imHeight = im.height;
      
      for(int z = 0; z < numInZ; z++)
          {
              for (int x = 0; x < numInX; x++)
              {
                 int imx = (int) map(x,0,numInX,0,imWidth);
                 int imy = (int) map(z,0,numInZ,0,imHeight);
                 color col = im.get(imx,imy);
                 float hght = map(red(col),0,255,0,maxAltitude);
                 setVertexY(x,z,hght );
              }
              
          }
    
    }
    
    
    void setTextureMap(PImage t){
      textureMap = t.copy();
    }
    
    
    // this permanently applies the transform. It is only availbale on Surface Meshes
    // as these items are often ised for stationary landscapes, which do not move once established
    void bakeInTransform(){
      meshVertices = transformVertices(meshVertices);
      setTransform(1.0,0.0,0.0,0.0, vec(0,0,0));
    }
    
    //////////////////////////////////////////////////////////////////////////////////
    // drawing methods. Just call drawMe()
    //
    void drawMe(){
      if ( textureMap != null) {
      drawMe_Texture();
      return;
      }
      int numFacets = getNumFacets();
      beginShape(TRIANGLES);
        
        // Center point
        
        for (int i = 0; i < numFacets; i++) {
          SimFacet f = getFacet(i);
          SimTriangle t1 = f.tri1;
          SimTriangle t2 = f.tri2;
          // draws ok
          drawTransformedVertex(t1.p1);
          drawTransformedVertex(t1.p2);
          drawTransformedVertex(t1.p3);
          // doenst draw
          drawTransformedVertex(t2.p1);
          drawTransformedVertex(t2.p2);
          drawTransformedVertex(t2.p3);
        }
        endShape();
    }
    
    void drawMe_Texture() {
      int numFacets = getNumFacets();
      beginShape(TRIANGLES);
      texture(textureMap);
      //g3d.blendMode(REPLACE); 
      for (int i = 0; i < numFacets; i++) {
       
        SimFacet f = getFacet(i);
        SimTriangle t1 = f.tri1;
        SimTriangle t2 = f.tri2;
   
        drawTransformedVertex_Texture(t1.p1);
        drawTransformedVertex_Texture(t1.p2);
        drawTransformedVertex_Texture(t1.p3);
  
        drawTransformedVertex_Texture(t2.p1);
        drawTransformedVertex_Texture(t2.p2);
        drawTransformedVertex_Texture(t2.p3);
        }
      
      endShape();
  }
  
  //////////////////////////////////////////////////////////////
  // getting the transformed shapes
  //
  //
  public void  drawTransformedVertex_Texture(PVector vertex) {
    PVector transformedVector = transform(vertex);
    PVector uv = getTextureUV(vertex);
    vertex(transformedVector.x, transformedVector.y, transformedVector.z, uv.x, uv.y);
  }
  
  SimFacet getTransformedFacet(int index){
      SimFacet facet = getFacet( index);
      PVector[] verts = facet.getVertices();
      PVector[] transformedVerts = new PVector[4];
      for(int n = 0; n < 4; n++) transformedVerts[n] = transform(verts[n]);
      return new SimFacet(transformedVerts[0],transformedVerts[1],transformedVerts[2],transformedVerts[3]);
    }
    
   
    
   
   SimTriangle[] getTransformedTriangles(){
      int numFacets = getNumFacets();
      int numTriangles = numFacets*2;
      
      SimTriangle[] triangles = new SimTriangle[numTriangles];
      int triangleIndex = 0;
      for (int i = 0; i < numFacets; i++) {
       
        SimFacet f = getTransformedFacet(i);
        
        // this caches the extents in the triangles
        f.tri1.cacheExtents();
        f.tri2.cacheExtents();
        
        triangles[triangleIndex] = f.tri1;
        triangleIndex++;
        triangles[triangleIndex] = f.tri2;
        triangleIndex++;

      }
      
      return triangles;
     
   }
    
  
  public PVector[] getTransformedVertices(){
    return transformVertices(meshVertices);
  }
  
  public SimExtents getTransformedExtents(){
    PVector[] tv = getTransformedVertices();
    return new SimExtents(tv);
  }
  
  
  SimTriangle getClosestTransformedTriangle(PVector p){
      SimTriangle closestTriangle = null;
      float closestDistance = 1000000000.0;
      int numFacets = getNumFacets();
      for (int i = 0; i < numFacets; i++) {
       
        SimFacet f = getTransformedFacet(i);
        PVector closestPoint = f.tri1.closestPointOnTriangle(p);
        float dist = closestPoint.dist(p);
        if(dist < closestDistance){
          closestDistance = dist;
          closestTriangle = f.tri1;
        }
        
        closestPoint = f.tri2.closestPointOnTriangle(p);
        dist = closestPoint.dist(p);
        if(dist < closestDistance){
          closestDistance = dist;
          closestTriangle = f.tri2;
        }
        
      }
      
      return closestTriangle;
      
    }
    
  
  PVector getClosestPointOnTransformedSurface(PVector p){
      SimTriangle closestTriangle = getClosestTransformedTriangle(p);
      return closestTriangle.closestPointOnTriangle(p);
    }
    
    
  //////////////////////////////////////////////////////////////////////
  // Utility methods,and methods that access the model-space (untransformed) mesh data
  //  
  //  
  
  PVector getTextureUV(PVector vertex){
    int w = textureMap.width;
    int h = textureMap.height;
    PVector minVertex = getMeshVertex(0, 0);
    PVector maxVertex = getMeshVertex(numFacetsX, numFacetsZ);
    float u = map(vertex.x, minVertex.x, maxVertex.x, 0, w-1);
    float v = map(vertex.z, minVertex.z, maxVertex.z, 0, h-1);
    return new PVector(u,v);
  }
  
  
  
   
   
   
   
  

   //////////////////////////////////////////////// 
    public void setVertexY(int vertexX, int vertexZ, float y){
      // there are meshSizeX+1, meshSizeY+1 vertices in this messh
      if(vertexX < 0 || vertexX > numFacetsX || vertexZ < 0 || vertexZ > numFacetsZ){
        println("SimSurfaceMesh::setVertexY - illegal vertices index ", vertexX, vertexZ);
        return;
      }
      int vertexGridWidth = numFacetsX + 1;
      int index =  vertexZ * vertexGridWidth + vertexX;
      PVector p = meshVertices[index];
      p.y = y;
      meshVertices[index] = p;
    }
    
    public PVector getMeshVertex(int vertexX, int vertexZ){
      int vertexGridWidth = numFacetsX + 1;
      int index =  vertexZ * vertexGridWidth + vertexX;
      return meshVertices[index];
    }
    
    public void setMeshVertex(int vertexX, int vertexZ, PVector v){
      int vertexGridWidth = numFacetsX + 1;
      int index =  vertexZ * vertexGridWidth + vertexX;
      meshVertices[index] = v;
    }
    
    /////////////////////////////////////////////
    // private below here

    int getNumFacets(){
      return (numFacetsX)* (numFacetsZ); 
    }
    
    int getNumTriangles(){
        return (numFacetsX)* (numFacetsZ)*2;
    }
    
    private int getNumVerticesX(){ return  numFacetsX+1;}
    private int getNumVerticesZ(){ return  numFacetsZ+1;}

    
    
    
    SimFacet getFacet(int index){
        
        //the vertices under consideration
        // A B
        // C D
        // as indices into the meshVertices array
        int vertextGridWidth = numFacetsX+1;
        int rowNum = (int)(index/numFacetsX);
        int A = index + rowNum;
        int B = A + 1;
        int C = A + vertextGridWidth;
        int D = C + 1;

        //println("index ", index, "row ", rowNum," vertices nums ", A,B,C,D);
        SimFacet facet = new SimFacet();
        // triangle 1
        facet.tri1.p1 = meshVertices[D];
        facet.tri1.p2 = meshVertices[B];
        facet.tri1.p3 = meshVertices[A];
        
        // triangle 2
        facet.tri2.p1  = meshVertices[D];
        facet.tri2.p2  = meshVertices[A];
        facet.tri2.p3  = meshVertices[C];

        return facet;

      
    }

    SimFacet getFacet(int x, int z)
    {
        int vertexGridWidth = numFacetsX + 1;
        int index =  z * vertexGridWidth + x;
        
        return getFacet(index); 
    }
    
  
  

}// end SimSurfaceMesh class
