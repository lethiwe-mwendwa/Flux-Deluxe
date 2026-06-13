import javax.swing.JOptionPane;
/////////////////////////////////////////////////////////////////
// SimUI_Classes version 1, was SimpleUI up to 02/08/2025
// SimpleUI was started Dec 12th 2018
// written by Simon Schofield



//////////////////////////////////////////////////////////////////
// SimUI() is the only class you have to use in your 
// application to build and use the UI. 
// With it you can add buttons, sliders, menus and text boxes
// You can use a file dialogue to load and save files
//
//
// 
//
// Once a mouse event has been received by a UI item (button, menu etc) it calls a function called
// handleSimUIEvent(...) which you have to include in the 
// main part of the project (below setup() and draw() etc.)
//
// Also, you need to call mySimUI.update() in the main draw() function, where mySimUI is your instantiated SimUI object
//

// This variable can double the size of the components (by setting to 2) if so required.
//

int gSimUIScale = 2;

public class SimUI {

  
  
  SimUIRect canvasRect;
  
  boolean isActive = true;

  boolean useAutomaticMouseEventHandling = true;

  ArrayList<Widget> widgetList = new ArrayList<Widget>();

  SimUIRect backgroundRect = null;
  color backgroundRectColor; 

  // these are for capturing user events
  boolean pmousePressed = false;
  boolean pkeyPressed = false;
  String fileDialogPrompt = "";

  public SimUI() {
    //try {
    //  PApplet.class.getMethod("handleSimUIEvent", SimUIEvent.class);
    //} catch (NoSuchMethodException  e) {
    //  println(" Please add the handleSimUIEvent() to your main tab");
    //}
  }

  
  void setUIScale(int s){
    if(s == 1 || s == 2) gSimUIScale = s;
  }
  
  ////////////////////////////////////////////////////////////////////////////
  // file dialogue
  //

  public void openFileLoadDialog(String prompt) {
    fileDialogPrompt = prompt;
    selectInput(prompt, "fileLoadCallback", null, this);
  }

  void fileLoadCallback(File selection) {

    // cancelled
    if (selection == null) {
      return;
    }


    // is directory not file
    if (selection.isDirectory()) {
      return;
    }

    SimUIEvent uied = new SimUIEvent("fileLoadDialog", "fileLoadDialog", "mouseReleased", mouseX, mouseY);
    uied.fileSelection = selection.getPath();
    uied.fileDialogPrompt = this.fileDialogPrompt;
    handleSimUIEvent( uied);
  }



  public void openFileSaveDialog(String prompt) {
    fileDialogPrompt = prompt;
    selectOutput(prompt, "fileSaveCallback", null, this);
  }

  void fileSaveCallback(File selection) {

    // cancelled
    if (selection == null) {
      return;
    }

    String path = selection.getPath();
    //System.out.println(path);

    SimUIEvent uied = new SimUIEvent("fileSaveDialog", "fileSaveDialog", "mouseReleased", mouseX, mouseY);
    uied.fileSelection = selection.getPath();
    uied.fileDialogPrompt = this.fileDialogPrompt;
    handleSimUIEvent(uied);
  }
  
  
   public void openFolderSelectDialogue(String prompt){
      this.fileDialogPrompt = prompt;
      //java.io.File defaultLocation = new java.io.File(location); 
      selectFolder(prompt, "folderSelectCallback", null,this);
    }
    
    void folderSelectCallback(File selection) {
      
      // cancelled
      if(selection == null){
      return;
      }
      
      String path = selection.getPath();
      println("in folder seclect callback ", path);

      SimUIEvent uied = new SimUIEvent("folderSelectDialog" , "folderSelectDialog", "mouseReleased", mouseX, mouseY);
      uied.fileSelection = selection.getPath();
      uied.fileDialogPrompt = this.fileDialogPrompt;
      handleSimUIEvent(uied);
    }
    
    // popup confirm dialogue
    
    int showYesNoDialogue(String str){
      // returns 0 for yes
      // returns 1 for no
       return JOptionPane.showConfirmDialog(null,str, str,JOptionPane.YES_NO_OPTION);
    }

  ////////////////////////////////////////////////////////////////////////////
  // canvas creation
  //
  public void addCanvas(int x, int y, int w, int h) {

    canvasRect = new SimUIRect(x, y, x+w, y+h);
  }

  public void checkForCanvasEvent(String mouseEventType, int x, int y) {
    if (canvasRect==null) return;
    if (   canvasRect.isPointInside(x, y)) {
      SimUIEvent uied = new SimUIEvent("canvas", "canvas", mouseEventType, x, y);
      handleSimUIEvent(uied);
    }
  }

  public void drawCanvas() {
    if (canvasRect==null) return;


    // now draw "surrounds"
    int appWidth = width;
    int appHeight = height;

    // left, top, right, bottom 
    pushStyle();
    fill(200, 200, 200);
    //stroke(0, 0, 0);
    noStroke();
    rect(0, 0, canvasRect.left, appHeight);
    rect(canvasRect.left, 0, canvasRect.getWidth(), canvasRect.top);
    rect(canvasRect.right, 0, appWidth-canvasRect.left, appHeight);
    rect(canvasRect.left, canvasRect.bottom, canvasRect.getWidth(), appHeight-canvasRect.getHeight());

    // fine line round the outside of canvas rect
    noFill();
    stroke(0, 0, 0); 
    strokeWeight(1);
    rect(canvasRect.left, canvasRect.top, canvasRect.getWidth(), canvasRect.getHeight());
    popStyle();
  }

  ////////////////////////////////////////////////////////////////////////////
  // widget creation
  //

  boolean widgetNameAlreadyExists(String label, String  uiComponentType) {

    for (Widget w : widgetList) {
      if (w.UILabel.equals(label) && w.UIComponentType.equals(uiComponentType) ) {
        System.out.println("SimUI: that label name - "+ label+ " - already exists for widget of type "+ uiComponentType);
        return true;
      }
    }
    return false;
  }

  // label creation
  public SimpleLabel addSimpleLabel(String label, int x, int y, String txt) {
    if (widgetNameAlreadyExists(label, "SimpleLabel")) return null;
    SimpleLabel l = new SimpleLabel(x, y, label, txt);

    widgetList.add(l);
    return l;
  }

  // button creation
  public SimpleButton addSimpleButton(String label, int x, int y) {
    if (widgetNameAlreadyExists(label, "SimpleButton")) return null;
    SimpleButton b = new SimpleButton(x, y, label);

    widgetList.add(b);
    return b;
  }

  public ToggleButton addToggleButton(String label, int x, int y) {
    if (widgetNameAlreadyExists(label, "SimpleButton")) return null;
    ToggleButton b = new ToggleButton(x, y, label);

    widgetList.add(b);
    return b;
  }

  public ToggleButton addToggleButton(String label, int x, int y, boolean initialState) {
    if (widgetNameAlreadyExists(label, "SimpleButton")) return null;
    ToggleButton b = new ToggleButton(x, y, label);

    b.selected = initialState;
    widgetList.add(b);
    return b;
  }

  public RadioButton addRadioButton(String label, int x, int y, String groupID) {
    if (widgetNameAlreadyExists(label, "SimpleButton")) return null;
    RadioButton b = new RadioButton(x, y, label, groupID, this);

    widgetList.add(b);
    return b;
  }

  // label creation
  public TextDisplayBox addLabel(String label, int x, int y, String txt) {
    if (widgetNameAlreadyExists(label, "SimpleLabel")) return null;
    TextDisplayBox sl = new TextDisplayBox(label, x, y, txt);

    widgetList.add(sl);
    return sl;
  }

  // menu creation
  public Menu addMenu(String label, int x, int y, String[] menuItems) {
    if (widgetNameAlreadyExists(label, "Menu")) return null;
    Menu m = new Menu(label, x, y, menuItems, this);

    widgetList.add(m);
    return m;
  }

  // slider creation
  public Slider addSlider(String label, int x, int y) {
    if (widgetNameAlreadyExists(label, "Slider")) return null;
    Slider s = new Slider(label, x, y);

    widgetList.add(s);
    return s;
  }

  // text display creation
  public TextDisplayBox addTextDisplayBox(String label, int x, int y, String txt) {
    if (widgetNameAlreadyExists(label, "SimpleLabel")) return null;
    TextDisplayBox sl = new TextDisplayBox(label, x, y, txt);

    widgetList.add(sl);
    return sl;
  }


  // text input box creation
  public TextInputBox addTextInputBox(String label, int x, int y) {
    int maxNumChars = 14;
    if (widgetNameAlreadyExists(label, "TextInputBox")) return null;
    TextInputBox tib = new TextInputBox(label, x, y, maxNumChars);
    widgetList.add(tib);
    return tib;
  }

  public TextInputBox addTextInputBox(String label, int x, int y, String content) {
    if (widgetNameAlreadyExists(label, "TextInputBox")) return null;
    TextInputBox tib = addTextInputBox( label, x, y);

    tib.setText(content);
    return tib;
  }



  void removeWidget(String uilabel) {
    Widget w = getWidget(uilabel);
    if (w == null) return;
    widgetList.remove(w);
  }



  // getting widget data by lable
  //
  Widget getWidget(String uilabel) {
    for (Widget w : widgetList) {
      if (w.UILabel.equals(uilabel)) return w;
    }
    System.out.println(" getWidgetByLabel: cannot find widget with label "+ uilabel);
    return null;
  }


  // get toggle state
  public boolean getToggleButtonState(String uilabel) {
    Widget w = getWidget(uilabel);
    if ( w.UIComponentType.equals("ToggleButton") || w.UIComponentType.equals("RadioButton")) return w.selected;
    System.out.println(" getToggleButtonState: cannot find widget with label "+ uilabel);
    return false;
  }

  // get selected radio button in a group - returns the label name
  public String getRadioGroupSelected(String groupName) {
    for (Widget w : widgetList) {
      if ( w.UIComponentType.equals("RadioButton")) {
        if ( ((RadioButton)w).radioGroupName.equals(groupName) && w.selected) return w.UILabel;
      }
    }
    return "";
  }



  public float getSliderValue(String uilabel) {
    Widget w = getWidget(uilabel);
    if ( w.UIComponentType.equals("Slider") ) return ((Slider)w).getSliderValue();
    return 0;
  }

  public void setSliderValue(String uilabel, float v) {
    Widget w = getWidget(uilabel);
    if ( w.UIComponentType.equals("Slider") )  ((Slider)w).setSliderValue(v);
  }






  public String getText(String uilabel) {
    Widget w = getWidget(uilabel);

    if (w.UIComponentType.equals("TextInputBox")) {
      return ((TextInputBox)w).getText();
    }

    if (w.UIComponentType.equals("SimpleLabel")) {
      return ((TextDisplayBox)w).getText();
    }
    return "";
  }

  public void setText(String uilabel, String content) {
    Widget w = getWidget(uilabel);
    if (w.UIComponentType.equals("TextInputBox")) {
      ((TextInputBox)w).setText(content);
    }
    if (w.UIComponentType.equals("SimpleLabel")) {
      ((TextDisplayBox)w).setText(content);
    }
  }



  // setting a background Color region for the UI. This is drawn first.
  // to do: this should also set an offset for subsequent placement of the buttons

  void setBackgroundRect(int left, int top, int right, int bottom, int r, int g, int b) {
    backgroundRect = new SimUIRect(left, top, right, bottom);
    backgroundRectColor = color(r, g, b);
  }

  void setRadioButtonOff(String groupName) {
    for (Widget w : widgetList) {
      if ( w.UIComponentType.equals("RadioButton")) {
        if ( ((RadioButton)w).radioGroupName.equals(groupName))  w.selected = false;
      }
    }
  }

  void setRadioButtonOn(String buttonName, String groupName) {
    // used for controlling group via code, eg using quick keys
    setRadioButtonOff(groupName);
    getWidget(buttonName).selected = true;
  }

  void setMenusOff() {
    for (Widget w : widgetList) {
      if ( w.UIComponentType.equals("Menu")) {
        ((Menu)w).visible = false;
      }
    }
  }

  boolean menuIsOpen(){
      for(Widget w: widgetList){
        if( w.UIComponentType.equals("Menu")){
          if(((Menu)w).visible) {
            return true;}
        }
      }
     return false;
      
    }
  // this is an alternative to using the seperate event handlers provided by Processing
  // It therefor easier to use, but more sluggish in response
  void checkForUserInputEvents() {
    // this gets called in the drawMe() method, instead of having to link up
    // to the native mousePressed() etc. methods

    if ( pmousePressed == false  && mousePressed) {
      handleMouseEvent("mousePressed", mouseX, mouseY);
    }

    if ( pmousePressed == true  && mousePressed == false) {
      handleMouseEvent("mouseReleased", mouseX, mouseY);
    }

    if ( (pmouseX != mouseX || pmouseY != mouseY) && mousePressed ==false) {
      handleMouseEvent("mouseMoved", mouseX, mouseY);
    }
    if ( (pmouseX != mouseX || pmouseY != mouseY) && mousePressed) {
      handleMouseEvent("mouseDragged", mouseX, mouseY);
    }


    if ( pkeyPressed == false && keyPressed == true) {
      handleKeyEvent(key, keyCode, "pressed");
    }

    if ( pkeyPressed == true && keyPressed == false) {
      handleKeyEvent(key, keyCode, "released");
    }

    pmousePressed = mousePressed;
    pkeyPressed = keyPressed;
  }




  // this is a key method. It is either called by the above method checkForUserInputEvents() (for a simpler implementation) or by the 
  // individual application-level mouse-event handlers. The widgets are polled to see if any one is handling this event
  // if it is handled, then the loop is broken and the event is handled. The allows for addition and removal of
  // widgets during run-time, which would othrwise create a concurrency issue.
  void handleMouseEvent(String mouseEventType, int x, int y) {
    if(isActive==false) return;
    checkForCanvasEvent(mouseEventType, x, y);
    Widget widgetActing = null;

    for (Widget w : widgetList) {
      boolean eventAbsorbed = w.handleMouseEvent(mouseEventType, x, y);

      if (eventAbsorbed) { 
        widgetActing = w;
      }
      if (eventAbsorbed) break;
    }
    if (widgetActing == null) return;
    if (widgetActing.isVisible() == false) return;
    widgetActing.doEventAction(mouseEventType, x, y);
  }



  boolean handleKeyEvent(char k, int kcode, String keyEventType) {
    for (Widget w : widgetList) {
      boolean eventHandled = w.handleKeyEvent( k, kcode, keyEventType);
      if (eventHandled) return true;
    }
    return false;
  }


  void update() {
    if ( useAutomaticMouseEventHandling ) checkForUserInputEvents();

    if ( backgroundRect != null ) {
      pushStyle();
      fill(backgroundRectColor);
      rect(backgroundRect.left, backgroundRect.top, backgroundRect.getWidth(), backgroundRect.getHeight());
      popStyle();
    }

    drawCanvas();
    for (Widget w : widgetList) {
      if (w.isVisible()==false) continue;
      w.drawMe();
    }
  }

  void clearAll() {
    widgetList = new ArrayList<Widget>();
  }
}// end of SimUIManager



//////////////////////////////////////////////////////////////////
// SimUIEvent
// when a UI component calls the simpleUICallback() function, it passes this object back
// which contains EVERY CONCEIVABLE bit of extra information about the event that you could imagine
//
public class SimUIEvent {
  // set by the constructor
  
  public String uiComponentType; // this is the type of widet e.g. SimpleButton, ToggleButton, Slider - it is identical to the class name
  
  public String uiLabel; // this is the unique shown label for each widget, and is used to idetify the calling widget
  public String mouseEventType;
  public int mousex; // this is the x location of the recieved mouse event, in window space
  public int mousey;

  // extra stuff, which is specific to particular widgets
  public boolean toggleSelectState = false;
  public String radioGroupName = "";
  public String menuItem = "";
  public int menuItemNum = 0;
  public float sliderValue = 0.0;
  public String fileDialogPrompt = "";
  public String fileSelection = "";

  // key press and text content information for text widgets
  public char keyPress;
  public String textContent;

  public SimUIEvent() {
  }



  public SimUIEvent(String thingType, String label, String mouseEvent, int x, int y) {
    initialise(thingType, label, mouseEvent, x, y);
  }

  void initialise(String thingType, String label, String mouseEvent, int x, int y) {

    
    uiComponentType = thingType;
    uiLabel = label;
    mouseEventType = mouseEvent;
    mousex = x;
    mousey = y;
    
  }

  boolean eventIsFromWidget(String lab) {
    if ( uiLabel.equals( lab )) return true;
    if ( menuItem.equals(lab) ) return true;
    return false;
  }

 

  void print(int verbosity) {
    if (verbosity != 3 && this.mouseEventType.equals("mouseMoved")) return;


    if (verbosity == 0) return;

    if (verbosity >= 1) {
      System.out.println("UIEventData:" + this.uiComponentType + " UILabel " + this.uiLabel);

      if ( this.uiComponentType.equals("canvas")) {
        System.out.println("mouse event:" + this.mouseEventType + " at (" + this.mousex +"," + this.mousey + ")");
      }
    }

    if (verbosity >= 2) {
      System.out.println("toggleSelectState " + this.toggleSelectState);
      System.out.println("radioGroupName " + this.radioGroupName);
      System.out.println("sliderValue " + this.sliderValue);
      System.out.println("menuItem " + this.menuItem);
      System.out.println("keyPress " + keyPress);
      System.out.println("textContent " + textContent);
      System.out.println("fileDialogPrompt " + this.fileDialogPrompt);
      System.out.println("fileSelection " + this.fileSelection);
    }

    if (verbosity == 3 ) {
      if (this.mouseEventType.equals("mouseMoved")) {
        System.out.println("mouseMove at (" + this.mousex +"," + this.mousey + ")");
      }
    }

    System.out.println(" ");
  }
}





//////////////////////////////////////////////////////////////////
// Everything below here is stuff wrapped up by the SimUI class
// so you don't need to to look at it, or use it directly. But you can if you
// want to!
// 





//////////////////////////////////////////////////////////////////
// Base class to all components
class Widget {

  // Color for overall application
  color SimUIAppBackgroundColor = color(240, 240, 240);// the light neutralgrey of the overall application surrounds

  // Color for UI components
  color SimUIBackgroundRectColor = color(230, 230, 240); // slightly purpley background rect Color for alternative UI's
  color SimUIWidgetFillColor = color(200, 200, 200);// darker grey for butttons
  color SimUIWidgetRolloverColor = color(215, 215, 215);// slightly lighter rollover Color
  color SimUITextColor = color(0, 0, 0);


  // should any widgets need to "talk" to other widgets (RadioButtons, Menus)
  SimUI parentManager = null; 

  // this should be the best way to identify a widget, so make sure
  // that all UILabels are unique
  String UILabel;
  boolean displayLabel  = true;

  // type of component e.g. "UIButton", should be absolutely same as class name
  public String UIComponentType = "WidgetBaseClass";

  // location and size of widget
  int widgetWidth, widgetHeight;
  int locX, locY;
  public SimUIRect bounds;

  // needed by most, but not all widgets
  boolean rollover = false;

  // needed by some widgets but not all
  boolean selected = false;

  boolean isVisible = true;

  public Widget() {

    
  }

  public Widget(String uilabel, int x, int y, int w, int h) {
    UILabel = uilabel;
    setBounds(x*gSimUIScale, y*gSimUIScale, w*gSimUIScale, h*gSimUIScale);
  }

  
  // virtual functions
  // 
  public void setBounds(int x, int y, int w, int h) {
    locX = x;
    locY = y;
    widgetWidth = w;
    widgetHeight = h;
    bounds = new SimUIRect(x, y, x+w, y+h);
  }

  void setVisible(boolean v) {
    isVisible = v;
  }

  boolean isVisible() {
    return isVisible;
  }

  public boolean isInMe(int x, int y) {
    if (   bounds.isPointInside(x, y)) return true;
    return false;
  }

  public void setParentManager(SimUI manager) {
    parentManager = manager;
  }

  public void setWidgetDims(int w, int h) {
    setBounds(locX, locY, w, h);
  }

  public void setWidth(int w) {
    setBounds(locX, locY, w, widgetHeight);
  }

  public void setHeight(int h) {
    setBounds(locX, locY, widgetWidth, h);
  }

  public void showLabel(boolean show) {
    displayLabel = show;
  }



  // "virtual" functions here
  //
  public void drawMe() {
  }

  // every widget implements this - it returns true or false only, but does not "do" the actual event action.
  // All it does is report whereter of not this widget handles the mouse event, after whihc the mouse event is "absorbed"
  public boolean handleMouseEvent(String mouseEventType, int x, int y) { 
    return false;
  }

  // this happens IF this widget handles this mouse event.
  public void doEventAction(String mouseEventType, int x, int y) {
    SimUIEvent uied = new SimUIEvent(UIComponentType, UILabel, mouseEventType, x, y);
    handleSimUIEvent(uied);
  }


  boolean handleKeyEvent(char k, int kcode, String keyEventType) { 
    return false;
  }

  void setSelected(boolean s) {
    selected = s;
  }
  
  boolean isSelected(){ return selected; }
}

//////////////////////////////////////////////////////////////////
// A label class for just showing some text, with or without a boarder. End-user uneditable.
// the displayed text can be set at run-time
// Because there is no interaction with the SimpleLabel, it does not show its
// UILabel ever, but shows the text field.
class SimpleLabel extends Widget {
  boolean showBoarders = true;
  int textPad = 5;
  String text;
  int textSize = 12*gSimUIScale;


  public SimpleLabel(int x, int y, String uilable, String txt) {
    super(uilable, x, y, 100, 20);
    UIComponentType = "SimpleLabel";
    this.text = txt;
  }

  void showBoarders(boolean b) {
    this.showBoarders = b;
  }

  public void drawMe() {

    pushStyle();
    stroke(100, 100, 100);
    strokeWeight(1);
    fill(SimUIBackgroundRectColor);
    
    if (showBoarders) rect(locX, locY, widgetWidth, widgetHeight);

    if ( this.text.length() < width/5) {
      textSize = 12*gSimUIScale;;
    } else { 
      textSize = 8*gSimUIScale;;
    }
    fill(SimUITextColor);  
    textSize(textSize);
    strokeWeight(1);
    text(this.text, locX+textPad-2, locY+textPad, widgetWidth, widgetHeight);
    popStyle();
  }

  void setText(String txt) {
    this.text = txt;
  }

  String getText() {
    return this.text;
  }
}




//////////////////////////////////////////////////////////////////
// Base button class, functions as a simple button, and is the base class for
// toggle and radio buttons
class SimpleButton extends Widget {

  int textPad = 5;
  int textSize = 10*gSimUIScale;;

  PImage icon = null;

  public SimpleButton(int x, int y, String uilable) {
    super(uilable, x, y, 60, 20);

    UIComponentType = "SimpleButton";
  }

  void setIcon(PImage iconImg) {
    icon = iconImg.copy();
    icon.resize(widgetWidth-2, widgetHeight-2);
  }


  public void setButtonDims(int w, int h) {
    setBounds(locX, locY, w, h);
  }

  public boolean handleMouseEvent(String mouseEventType, int x, int y) {
    if ( isInMe(x, y) /*&& (mouseEventType.equals("mouseMoved") || mouseEventType.equals("mousePressed"))*/) {
      rollover = true;
    } else { 
      rollover = false;
    }

    if ( isInMe(x, y) && mouseEventType.equals("mouseReleased")) {
      return true;
    }
    return false;
  }



  public void drawMe() {

    pushStyle();
    stroke(0, 0, 0);
    strokeWeight(1);
    if (rollover) {
      fill(SimUIWidgetRolloverColor);
    } else {
      fill(SimUIWidgetFillColor);
    }

    rect(locX, locY, widgetWidth, widgetHeight);
    fill(SimUITextColor);
    if ( this.UILabel.length() < 10) {
      textSize = 12*gSimUIScale;;
    } else { 
      textSize = 9*gSimUIScale;;
    }

    textSize(textSize);
    strokeWeight(1);
    text(this.UILabel, locX+textPad, locY+textPad, widgetWidth, widgetHeight);
    popStyle();

    drawIconImage();
  }

  void drawIconImage() {

    if (icon == null) return;

    pushStyle();
    tint(127, 127, 127, 255);
    if (rollover) tint(200, 200, 200, 255);
    if (rollover && mousePressed) tint(255, 255, 255, 255);
    if (selected) tint(255, 255, 255, 255);
    image(icon, locX+1, locY+1, widgetWidth-2, widgetHeight-2);

    popStyle();
  }
}

//////////////////////////////////////////////////////////////////
// ToggleButton

class ToggleButton extends SimpleButton {



  public ToggleButton(int x, int y, String labelString) {
    super(x, y, labelString);

    UIComponentType = "ToggleButton";
  }

  public boolean handleMouseEvent(String mouseEventType, int x, int y) {
    if ( isInMe(x, y) && (mouseEventType.equals("mouseMoved") || mouseEventType.equals("mousePressed"))) {
      rollover = true;
    } else { 
      rollover = false;
    }

    if ( isInMe(x, y) && mouseEventType.equals("mouseReleased")) {
      return true;
    }
    return false;
  }

  public void doEventAction(String mouseEventType, int x, int y) {
    swapSelectedState();
    SimUIEvent uied = new SimUIEvent(UIComponentType, UILabel, mouseEventType, x, y);
    uied.toggleSelectState = selected;
    handleSimUIEvent(uied);
  }

  public void swapSelectedState() {
    selected = !selected;
  }

  public void drawMe() {

    pushStyle();
    stroke(0, 0, 0);
    if (rollover) {
      fill(SimUIWidgetRolloverColor);
    } else {
      fill(SimUIWidgetFillColor);
    }

    if (selected) {
      strokeWeight(2);
      rect(locX+1, locY+1, widgetWidth-2, widgetHeight-2);
    } else {
      strokeWeight(1);
      rect(locX, locY, widgetWidth, widgetHeight);
    }





    stroke(0, 0, 0);
    strokeWeight(1);
    fill(SimUITextColor);
    textSize(textSize);
    strokeWeight(1);
    text(this.UILabel, locX+textPad, locY+textPad, widgetWidth, widgetHeight);
    popStyle();
  }
}

//////////////////////////////////////////////////////////////////
// RadioButton

class RadioButton extends ToggleButton {


  // these have to be part of the base class as is accessed by manager
  public String radioGroupName = "";

  public RadioButton(int x, int y, String labelString, String groupName, SimUI manager) {
    super(x, y, labelString);
    radioGroupName = groupName;
    UIComponentType = "RadioButton";
    parentManager = manager;
  }


  public boolean handleMouseEvent(String mouseEventType, int x, int y) {
    if ( isInMe(x, y) && (mouseEventType.equals("mouseMoved") || mouseEventType.equals("mousePressed"))) {
      rollover = true;
    } else { 
      rollover = false;
    }

    if ( isInMe(x, y) && mouseEventType.equals("mouseReleased")) {
      return true;
    }

    return false;
  }


  public void doEventAction(String mouseEventType, int x, int y) { 
    parentManager.setRadioButtonOff(this.radioGroupName);
    selected = true;
    SimUIEvent uied = new SimUIEvent(UIComponentType, UILabel, mouseEventType, x, y);
    uied.toggleSelectState = selected;
    uied.radioGroupName  = this.radioGroupName;
    handleSimUIEvent(uied);
  }

  public void turnOff(String groupName) {
    if (groupName.equals(radioGroupName)) {
      selected = false;
    }
  }
}



/////////////////////////////////////////////////////////////////////////////
// menu stuff
//
//

/////////////////////////////////////////////////////////////////////////////
// the menu class
//
class Menu extends Widget {


  int textPad = 5;
  //String title;
  int textSize = 12*gSimUIScale;;

  int numItems = 0;
  SimUI parentManager;

  boolean showLastSelection = false;
  String lastSelection = "";

  public boolean visible = false;


  ArrayList<String> itemList = new ArrayList<String>();



  public Menu(String uilabel, int x, int y, String[] menuItems, SimUI manager) {

    super(uilabel, x, y, 100, 20);
    parentManager = manager;
    UIComponentType = "Menu";

    setMenuItems(menuItems);
  }



  public void drawMe() {

    //System.out.println("drawing menu " + title);
    drawTitle();
    if ( visible ) {
      drawItems();
    }
  }


  void setMenuItems(String[] menuItems) {
    itemList = new ArrayList<String>();
    numItems = 0;
    for (String s : menuItems) {
      itemList.add(s);
      numItems++;
    }
    if (menuItems.length == 0) {
      lastSelection = "";
    } else {
      lastSelection = itemList.get(0);
    }
  }

  void drawTitle() {
    pushStyle();
    strokeWeight(1);
    stroke(0, 0, 0);
    if (rollover) {
      fill(SimUIWidgetRolloverColor);
    } else {
      fill(SimUIWidgetFillColor);
    }

    rect(locX, locY, widgetWidth, widgetHeight);
    fill(SimUITextColor);
    textSize(textSize);

    String displayString;
    if (displayLabel) { 
      displayString = this.UILabel;
    } else {
      displayString = "";
    }
    if (showLastSelection) {
      if (displayString.equals("")) {
        displayString = lastSelection;
      } else {
        displayString = displayString + ":" + lastSelection;
      }
    }
    if (displayString == null) return;
    text(displayString, locX+textPad, locY+3, widgetWidth, widgetHeight);
    popStyle();
  }


  void drawItems() {
    pushStyle();
    strokeWeight(1);
    if (rollover) {
      fill(SimUIWidgetRolloverColor);
    } else {
      fill(SimUIWidgetFillColor);
    }



    int thisY = locY + widgetHeight;
    rect(locX, thisY, widgetWidth, (widgetHeight*numItems));

    if (isInItems(mouseX, mouseY)) {
      hiliteItem(mouseY);
    }

    fill(SimUITextColor);

    textSize(textSize);

    for (String s : itemList) {

      if (s.length() > 14)
      {
        textSize(textSize-1);
      } else {
        textSize(textSize);
      }


      text(s, locX+textPad, thisY, widgetWidth, widgetHeight);
      thisY += widgetHeight;
    }
    popStyle();
  }


  void hiliteItem(int y) {
    pushStyle();
    int topOfItems =this.locY + widgetHeight;
    float distDown = y - topOfItems;
    int itemNum = (int) distDown/widgetHeight;
    fill(230, 210, 210);
    rect(locX, topOfItems + itemNum*widgetHeight, widgetWidth, widgetHeight);
    popStyle();
  }

  public boolean handleMouseEvent(String mouseEventType, int x, int y) {
    rollover = false;

    //System.out.println("here1 " + mouseEventType);
    if (isInMe(x, y)==false) {
      visible = false;
      return false;
    }
    if ( isInMe(x, y)) {
      rollover = false;
    }

    //System.out.println("here2 " + mouseEventType);
    if (mouseEventType.equals("mousePressed") && visible == false) {
      //System.out.println("mouseclick in title of " + title);
      parentManager.setMenusOff();
      visible = true;
      rollover = true;
      return false;
    }
    if (mouseEventType.equals("mousePressed") && isInItems(x, y)) {
      parentManager.setMenusOff();
      return true;
    }
    return false;
  }

  public void doEventAction(String mouseEventType, int x, int y) { 
    // Commented this out cause its annoying
    //System.out.println("menu event "+ UIComponentType + " " + UILabel+ " " + mouseEventType+ " " + x+ " " + y);
    String pickedItem = getItem(y);

    SimUIEvent uied = new SimUIEvent(UIComponentType, UILabel, mouseEventType, x, y);
    uied.menuItemNum = getItemNumber(y);
    uied.menuItem = pickedItem;
    lastSelection = pickedItem;
    handleSimUIEvent(uied);
  }

  String getItem(int y) {
    int topOfItems =this.locY + widgetHeight;
    float distDown = y - topOfItems;
    int itemNum = (int) distDown/widgetHeight;
    //System.out.println("picked item number " + itemNum);
    return itemList.get(itemNum);
  }


  int getItemNumber(int y) {
    int topOfItems =this.locY + widgetHeight;
    float distDown = y - topOfItems;
    return (int) distDown/widgetHeight;
  }

  boolean isInMe(int x, int y) {
    if (isInTitle(x, y)) {
      //System.out.println("mouse in title of " + title);
      return true;
    }
    if (isInItems(x, y)) {
      return true;
    }
    return false;
  }

  boolean isInTitle(int x, int y) {
    if (x >= this.locX   && x < this.locX+this.widgetWidth &&
      y >= this.locY && y < this.locY+this.widgetHeight) return true;
    return false;
  }


  boolean isInItems(int x, int y) {
    if (visible == false) return false;
    if (x >= this.locX   && x < this.locX+this.widgetWidth &&
      y >= this.locY+this.widgetHeight && y < this.locY+(this.widgetHeight*(this.numItems+1))) return true;


    return false;
  }

  /////////////////////////////////////////////////////////
  // to do with showing the last selection in the title
  void showSelectedInTitle(boolean v) {
    showLastSelection = v;

    // if you are not showing the label, then at least show the first item in the menu title
    if (displayLabel == false)  setSelectedInTitle(0);
  }

  void setSelectedInTitle(int itemNum) {
    if (itemNum >= 0 && itemNum < itemList.size()) {
      lastSelection = itemList.get(itemNum);
    }
  }

  String getSelelctedInTitle() {
    return lastSelection;
  }
}// end of menu class

/////////////////////////////////////////////////////////////////////////////
// Slider class stuff

/////////////////////////////////////////////////////////////////////////////
// Slider Class
//
// calls back with value on  both release and drag

class Slider extends Widget {

  boolean showValue = true;
  public float currentValue  = 0.0;
  boolean mouseEntered = false;
  int textPad = 5;
  int textSize = 12*gSimUIScale;;
  boolean rollover = false;

  public String HANDLETYPE = "ROUND";

  public Slider(String label, int x, int y) {
    super(label, x, y, 102, 30); 
    UIComponentType = "Slider";
  }

  void showValue(boolean sv) {
    showValue = sv;
  }

  public boolean handleMouseEvent(String mouseEventType, int x, int y) {
    PVector p = new PVector(x, y);

    if ( mouseLeave(p) ) {
      return false;
      //System.out.println("mouse left sider");
    }

    if ( bounds.isPointInside(p) == false) {
      mouseEntered = false;
      return false;
    }



    if ( (mouseEventType.equals("mouseMoved") || mouseEventType.equals("mousePressed"))) {
      rollover = true;
    } else { 
      rollover = false;
    }


    if (  mouseEventType.equals("mousePressed") /*|| mouseEventType.equals("mouseReleased") || mouseEventType.equals("mouseDragged")*/ ) {
      mouseEntered = true;
      return true;
    }

    if ( mouseEventType.equals("mouseDragged") && mouseEntered) return true;

    return false;
  }

  public void doEventAction(String mouseEventType, int x, int y) { 
    float val = getSliderValueAtMousePos(x);
    //System.out.println("slider val",val);
    setSliderValue(val);
    SimUIEvent uied = new SimUIEvent(UIComponentType, UILabel, mouseEventType, x, y);
    uied.sliderValue = val;
    handleSimUIEvent(uied);
  }

  float getSliderValueAtMousePos(int pos) {
    float val = map(pos, bounds.left, bounds.right, 0, 1);
    return val;
  }

  float getSliderValue() {
    return currentValue;
  }

  void setSliderValue(float val) {
    currentValue =  constrain(val, 0, 1);
  }

  boolean mouseLeave(PVector p) {
    // is only true, if the mouse has been in the widget, has been depressed
    if ( mouseEntered && bounds.isPointInside(p)== false) {
      mouseEntered = false;
      return true;
    }

    return false;
  }

  public void drawMe() {
    pushStyle();
    stroke(0, 0, 0);
    strokeWeight(1);
    if (rollover) {
      fill(SimUIWidgetRolloverColor);
    } else {
      fill(SimUIWidgetFillColor);
    }
    rect(bounds.left, bounds.top, bounds.getWidth(), bounds.getHeight());
    fill(SimUITextColor);
    textSize(textSize);
    text(this.UILabel, bounds.left+textPad, bounds.top+26);
    int sliderHandleLocX = (int) map(currentValue, 0, 1, bounds.left, bounds.right);
    sliderHandleLocX = (int)constrain(sliderHandleLocX, bounds.left+10, bounds.right-10 );
    stroke(127);
    float lineHeight = bounds.top+ (bounds.getHeight()/2.0) - 5;
    line(bounds.left+5, lineHeight, bounds.left+bounds.getWidth()-5, lineHeight);
    stroke(0);
    drawSliderHandle(sliderHandleLocX);
    popStyle();

    if (showValue) drawValue();
  }

  void drawValue() {
    pushStyle();
    textSize(10);
    fill(255, 0, 0);

    String currentValueString = nf(currentValue, 1, 4);

    text(currentValueString, bounds.right-60, bounds.top + 10);
    popStyle();
  }

  void drawSliderHandle(int loc) {
    pushStyle();
    stroke(0, 0, 0);
    fill(255, 255, 255, 100);
    if (HANDLETYPE.equals("ROUND")) {
      //if(this.label =="tone"){
      //  System.out.println("drawing slider" + this.label, loc, bounds.top + 10);
      //  
      //}

      ellipse(loc, bounds.top + (10*gSimUIScale), 10*gSimUIScale, 10*gSimUIScale);
    }
    if (HANDLETYPE.equals("UPARROW")) {
      triangle(loc-4, bounds.top + 15, loc, bounds.top - 2, loc+4, bounds.top + 15);
    }
    if (HANDLETYPE.equals("DOWNARROW")) {
      triangle(loc-4, bounds.top + 5, loc, bounds.bottom + 2, loc+4, bounds.top + 5);
    }
    popStyle();
  }
}



//////////////////////////////////////////////////////////////////
// TextDisplayBox - To show end user-uneditable text
// The trex can be changed only via code
// It displays label:text, where text is changeable in the widget's lifetime, but label is not
//
class TextDisplayBox extends Widget {

  int textPad = 5;
  String text;
  int textSize = 12;


  public TextDisplayBox(String uilable, int x, int y, String txt) {
    super(uilable, x, y, 100, 20);
    UIComponentType = "TextDisplayBox";
    this.text = txt;
  }

  public void drawMe() {

    pushStyle();
    stroke(100, 100, 100);
    strokeWeight(1);
    fill(SimUIBackgroundRectColor);
    rect(locX, locY, widgetWidth, widgetHeight);

    String seperator = ":";
    if (this.text.equals("")) seperator = " ";
    String displayString;

    if (displayLabel) { 

      displayString = this.UILabel + seperator + this.text;
    } else {

      displayString = this.text;
    }



    if ( displayString.length() < 20) {
      textSize = 9*gSimUIScale;;
    } else { 
      textSize = 9*gSimUIScale;;
    }
    fill(SimUITextColor);  
    textSize(textSize);
    strokeWeight(1);
    text(displayString, locX+textPad, locY+textPad-2, widgetWidth, widgetHeight);
    popStyle();
  }

  void setText(String txt) {
    this.text = txt;
  }

  String getText() {
    return this.text;
  }
}


////////////////////////////////////////////////////////////////////////////////
// self contained simple txt ox input
// simpleUICallback is called after every character insertion/deletion, enabling immediate udate of the system
//
class TextInputBox extends Widget {
  String contents = "";
  int maxNumChars = 14;

  boolean rollover;

  color textBoxBackground = color(235, 235, 255);

  public TextInputBox(String uilabel, int x, int y, int maxNumChars) {
    super(uilabel, x, y, 100, 30);
    UIComponentType = "TextInputBox";
    this.maxNumChars = maxNumChars;

    rollover = false;
  }


  public boolean handleMouseEvent(String mouseEventType, int x, int y) {
    // can only type into an input box if the mouse is hovering over
    // this way we avoid sending text input to multiple widgets
    PVector mousePos = new PVector (x, y);
    rollover = bounds.isPointInside(mousePos);
    // if(rollover) System.out.println("text box rollover", UILabel, " ", rollover);
    return rollover;
  }

  boolean handleKeyEvent(char k, int kcode, String keyEventType) {
    rollover = bounds.isPointInside(mouseX, mouseY);
    if (keyEventType.equals("released")) return true;
    if (rollover == false) return false;

    SimUIEvent uied = new SimUIEvent(UIComponentType, UILabel, "textInputEvent", 0, 0);
    uied.keyPress = k;





    if ( isValidCharacter(k) ) {
      addCharacter(k);
    }

    if (k == BACKSPACE) {
      deleteCharacter();
    }

    handleSimUIEvent(uied);
    return true;
  }

  void addCharacter(char k) {
    if ( contents.length() < this.maxNumChars) {
      contents=contents+k;
    }
  }

  void deleteCharacter() {
    int l = contents.length();
    if (l == 0) return; // string already empty
    if (l == 1) {
      contents = "";
    }// delete the final character
    String cpy  = contents.substring(0, l-1);
    contents = cpy;
  }

  boolean isValidCharacter(char k) {
    if (k == BACKSPACE) return false;
    return true;
  }

  String getText() {
    return contents;
  }

  void setText(String s) {
    contents = s;
  }

  public void drawMe() {
    pushStyle();
    stroke(0, 0, 0);
    fill(textBoxBackground);
    strokeWeight(1);

    if (rollover) {
      stroke(255, 0, 0);
      fill(SimUIWidgetRolloverColor);
    }


    rect(locX, locY, widgetWidth, widgetHeight);
    stroke(0, 0, 0);
    fill(SimUITextColor);

    int textPadX = 5;
    int textPadY = 20;
    fill(SimUITextColor);  
    textSize(12*gSimUIScale);
    strokeWeight(1);
    text(contents, locX + textPadX, locY + textPadY);
    //text(UILabel, locX + textPadX + 50, locY + textPadY);

    if (displayLabel) text(UILabel, locX + widgetWidth + textPadX, locY + textPadY);
    popStyle();
  }
} 


/////////////////////////////////////////////////////////////////
// simple rectangle class especially for this UI stuff
//

class SimUIRect {

  float left, top, right, bottom;
  public SimUIRect() {
  }



  public SimUIRect(float x1, float y1, float x2, float y2) {
    this.left = min(x1, x2);
    this.top = min(y1, y2);
    this.right = max(x1, x2);
    this.bottom = max(y1, y2);
  }
  
  SimUIRect copy() {
    return new SimUIRect(left, top, right, bottom);
  }

 

  boolean isPointInside(float x, float y) {
    return isPointInside(new PVector(x, y));
  }


  boolean isPointInside(PVector p) {
    // inclusive of the boundries
    if (   this.isBetweenInc(p.x, this.left, this.right) && this.isBetweenInc(p.y, this.top, this.bottom) ) return true;
    return false;
  }

  float getWidth() {
    return (this.right - this.left);
  }

  float getHeight() {
    return (this.bottom - this.top);
  }




  boolean isBetweenInc(float v, float lo, float hi) {
    float a = min(lo, hi);
    float b = max(lo, hi);
    if (v >= a && v <= b) return true;
    return false;
  }
}
