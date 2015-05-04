import peasy.*;
import controlP5.*;
import oscP5.*;
import netP5.*;
import themidibus.*;

PeasyCam camera;

ControlP5 cp5;
Knob angleKnob;
Knob tiltKnob;
Knob lengthKnob;
Knob depthKnob;
Knob windKnob;
ListBox presetsList;
Button randomizeButton;
SizeableColorPicker[] colorPickers;
int currentColorIndex;

MidiBus midiBus;
static class MidiBindings {
  // TODO: Implement MIDI learn?
  static final int INPUT_DEVICE_ID = 0;
  static final int OUTPUT_DEVICE_ID = -1;

  static final int ANGLE_KNOB = 20;
  static final int TILT_KNOB = 18;
  static final int LENGTH_KNOB = 14;
  static final int DEPTH_KNOB = 27;
  static final int WIND_KNOB = 76;

  static final int RED_COLOR_FADER = 30;
  static final int GREEN_COLOR_FADER = 85;
  static final int BLUE_COLOR_FADER = 79;

  static final int PREVIOUS_COLOR_BTN = 58;
  static final int NEXT_COLOR_BTN = 59;

  static final int PREVIOUS_PRESET_BTN = 61;
  static final int NEXT_PRESET_BTN = 62;

  static final int RANDOMIZE_BTN = 60;
}

OscP5 op5;
NetAddress remote;
static class OscConfigs {
  static final int SEND_PORT = 6788;
  static final String SEND_ADDRESS = "127.0.0.1";
  static final int BUFFER_SIZE = 64000;
}

LSystem[] fractalPresets;
int currentFractalIndex;
String currentFractalCache;
ILSystemRenderer fractalRenderer;
color[] fractalRenderColors;
boolean useCache;

void setup() {
  size(1024, 768, P3D);
  smooth(8);

  setupFractals();
  setupCommunication();
  setupCamera();
  setupUserInterface();

  useCache = false;
}

/**
 * Initialize the fractal presets with specific L-Systems.
 * Initialize the L-System renderer.
 */
void setupFractals() {
  fractalPresets = new LSystem[7];
  fractalPresets[0] = new LSystem("F", new Rule[]{
    new Rule('F', "C0FF-[C1-F+F+F]+[C2+F-F-F]")});

  fractalPresets[1] = new LSystem("FX", new Rule[]{
    new Rule('F', "C0FF-[C1-F+F]+[C2+F-F]"),
    new Rule('X', "C0FF+[C1+F]+[C3-F]")});

  fractalPresets[2] = new LSystem("F", new Rule[]{
    new Rule('F', new String[]{"C0FF[C1-F++F][C2+F--F]C3++F--F"})});

  fractalPresets[3] = new LSystem("X", new Rule[]{
    new Rule('X', "C0F-[C2[X]+C3X]+C1F[C3+FX]-X"),
    new Rule('F', "FF")});

  fractalPresets[4] = new LSystem("F", new Rule[]{
    new Rule('F', "C0F[C1+F]F[C2-F]F")});

  fractalPresets[5] = new LSystem("F", new Rule[]{
    new Rule('F', "C0F[C1+F]F[C2-F][C3F]")});

  fractalPresets[6] = new LSystem("X", new Rule[]{
    new Rule('X', "C0F[C1+X][C1-X]C2FX"),
    new Rule('F', "FF")});

  currentFractalIndex = 0;
  currentFractalCache = null;

  fractalRenderColors = new color[]{
    color(140, 80, 60, 192),
    color(24, 180, 24, 192),
    color(48, 220, 48, 127),
    color(64, 255, 64, 127)};
  println(fractalRenderColors);

  fractalRenderer = new TurtleRenderer();
  fractalRenderer.setSegmentColors(fractalRenderColors);
}

/**
 * Initialize, position and bind events on user interface elements such as
 * color pickers, knobs, buttons & checkboxes.
 */
void setupUserInterface() {
  cp5 = new ControlP5(this);
  cp5.setAutoDraw(false); // Disable auto-draw to control when the GUI is rendered.

  // Buttons.
  String[] presetLabels = new String[fractalPresets.length];
  for (int i = 0; i < presetLabels.length; ++i) {
    presetLabels[i] = "Preset " + (i + 1);
  }

  int buttonHeight = 25;
  int buttonWidth = 100;
  float buttonPadding = 25;
  float presetGroupOffsetY = (height / 2) - (buttonHeight * presetLabels.length / 2) - (buttonHeight + buttonPadding) / 2;

  presetsList = cp5.addListBox("preset")
     .setItemHeight(buttonHeight)
     .setPosition(0, presetGroupOffsetY)
     .hideBar()
     .addItems(presetLabels);

  randomizeButton = cp5.addButton("randomize")
     .setSize(buttonWidth, buttonHeight)
     .setPosition(0, presetGroupOffsetY + buttonHeight * presetLabels.length + buttonPadding);

  // Color pickers.
  colorPickers = new SizeableColorPicker[fractalRenderColors.length];
  currentColorIndex = 0;

  float colorPickerWidth = 100;
  float colorPickerHeight = 50;
  float colorPickerPadding = 25;
  float colorPickerGroupOffsetY = (height / 2) -
    (colorPickerHeight + colorPickerPadding) * (colorPickers.length / 2);

  for (int i = 0; i < fractalRenderColors.length; ++i) {
    SizeableColorPicker cp = new SizeableColorPicker(cp5, "color" + i);

    cp.setColorValue(fractalRenderColors[i]);
    cp.setPosition(width - colorPickerWidth - colorPickerPadding,
      colorPickerGroupOffsetY + i * (colorPickerHeight + colorPickerPadding));

    colorPickers[i] = cp;
  }

  // Knobs.
  int numOfKnobs = 5;
  float knobRadius = 25;
  float knobDiameter = knobRadius * 2;
  float knobPadding = 25;
  float knobGroupOffsetY = 25;
  float knobGroupOffsetX = (width / 2) -
    (knobDiameter * numOfKnobs + knobPadding * (numOfKnobs - 1)) / 2;

  angleKnob = cp5.addKnob("angle")
    .setRange(0, HALF_PI)
    .setValue(radians(25))
    .setPosition(knobGroupOffsetX, knobGroupOffsetY)
    .setRadius(knobRadius)
    .setDragDirection(Knob.HORIZONTAL);

  tiltKnob = cp5.addKnob("tilt")
    .setRange(-HALF_PI, HALF_PI)
    .setValue(0)
    .setPosition(angleKnob.getPosition().x + knobDiameter + knobPadding,
     knobGroupOffsetY)
    .setRadius(knobRadius)
    .setDragDirection(Knob.HORIZONTAL);

  lengthKnob = cp5.addKnob("length")
    .setRange(0, height/12)
    .setValue(height/24)
    .setPosition(tiltKnob.getPosition().x + knobDiameter + knobPadding, knobGroupOffsetY)
    .setRadius(knobRadius)
    .setDragDirection(Knob.HORIZONTAL);

  depthKnob = cp5.addKnob("depth")
    .setRange(0, 6)
    .setValue(1)
    .setPosition(lengthKnob.getPosition().x + knobDiameter + knobPadding, knobGroupOffsetY)
    .setRadius(knobRadius)
    .setNumberOfTickMarks(6)
    .setTickMarkLength(4)
    .setDragDirection(Knob.HORIZONTAL);

  windKnob = cp5.addKnob("wind")
    .setRange(0.1, 2)
    .setValue(0)
    .setPosition(depthKnob.getPosition().x + knobDiameter + knobPadding, knobGroupOffsetY)
    .setRadius(knobRadius)
    .setDragDirection(Knob.HORIZONTAL);

  // Checkboxes.
  cp5.addCheckBox("toggles")
     .setSize(10, 10)
     .setPosition(width - 135, height - 25)
     .setItemsPerRow(2)
     .setSpacingColumn(50)
     .addItem("Camera", 0)
     .addItem("Controls", 0)
     .activateAll();
}

/**
 * Initialize a 2D orthographic camera fixed on the Z axis.
 */
void setupCamera () {
  camera = new PeasyCam(this, width / 2, height / 2, 0, height * 6 / 7);
  camera.setLeftDragHandler(null);
  camera.setCenterDragHandler(camera.getPanDragHandler());
  camera.setRightDragHandler(null);
  camera.setActive(false);
}

/**
 * Initialize MIDI and OSC protocols.
 */
void setupCommunication() {
  MidiBus.list();
  midiBus = new MidiBus(this, MidiBindings.INPUT_DEVICE_ID, MidiBindings.OUTPUT_DEVICE_ID);

  OscProperties properties = new OscProperties();
  properties.setDatagramSize(OscConfigs.BUFFER_SIZE);
  properties.setNetworkProtocol(OscProperties.UDP);
  op5 = new OscP5(this, properties);

  remote = new NetAddress(OscConfigs.SEND_ADDRESS, OscConfigs.SEND_PORT);
}

/**
 * Render loop: fractals and GUI are redrawn every frame.
 */
void draw() {
  background(0);
  drawFractal();
  drawGUI();
}

/**
 * Render currently selected fractal according to current GUI elements state.
 */
void drawFractal() {
  float tilt = tiltKnob.getValue();
  float depth = depthKnob.getValue();
  String sentence = fractalPresets[currentFractalIndex].getSentence(depth, useCache);

  strokeWeight(2);
  pushMatrix();
  translate(width / 2, height); // Start drawing from the bottom center.
  rotate(-HALF_PI + tilt); // Draw upwards and account for tilt.
  fractalRenderer.render(sentence);
  popMatrix();

  if (!useCache) {
    useCache = true;
  }
}

/**
 * Manually redraw the GUI since we disabled auto-redraw.
 */
void drawGUI() {
  hint(DISABLE_DEPTH_TEST);
  camera.beginHUD();
  cp5.draw();
  camera.endHUD();
  hint(ENABLE_DEPTH_TEST);
}

/**
 * Intercept events from GUI element groups.
 * @param  event  ControlP5 GUI event.
 */
void controlEvent(ControlEvent event) {
  // Only groups are handled here, single elements are handled in seprate functions.
  if (event.isGroup()) {
    if (event.name().equals("preset")) {
      // Change selected preset.
      currentFractalIndex = int(event.group().value());
      useCache = false;

      // OscMessage msg = new OscMessage("/preset");
      // msg.add(currentFractalIndex);
      // op5.send(msg, remote);

      float depth = depthKnob.getValue();
      OscMessage msg = new OscMessage("/sentence/compressed");
      msg.add(fractalPresets[currentFractalIndex].getCompressedSentence(depth, useCache));
      op5.send(msg, remote);
    } else if (event.name().equals("toggles")) {
      float[] toggleStates = event.group().getArrayValue();

      // Toggle camera controls.
      if (camera.isActive() && toggleStates[0] == 0) {
        camera.reset(500);
      }
      camera.setActive(toggleStates[0] == 1);

      // Toggle GUI visibility.
      boolean visibility = toggleStates[1] == 1;
      angleKnob.setVisible(visibility);
      tiltKnob.setVisible(visibility);
      lengthKnob.setVisible(visibility);
      depthKnob.setVisible(visibility);
      windKnob.setVisible(visibility);
      presetsList.setVisible(visibility);
      randomizeButton.setVisible(visibility);
      for (int i = 0; i < colorPickers.length; ++i) {
        colorPickers[i].setVisible(visibility);
      }
    } else if (event.name().startsWith("color")) {
      // Change renderer colors.
      int colorIndex = Integer.parseInt(
        event.name().substring(event.name().length() - 1));

      int r = int(event.getArrayValue(0));
      int g = int(event.getArrayValue(1));
      int b = int(event.getArrayValue(2));
      int a = int(event.getArrayValue(3));

      fractalRenderColors[colorIndex] = color(r, g, b, a);
      fractalRenderer.setSegmentColors(fractalRenderColors);

      OscMessage msg = new OscMessage("/colors");
      msg.add(fractalRenderColors);
      op5.send(msg, remote);
    }
  }
}

/**
 * Randomize button event handler: randomize all GUI element values.
 */
void randomize() {
  angleKnob.shuffle();
  tiltKnob.shuffle();
  lengthKnob.shuffle();
  depthKnob.shuffle();
  windKnob.shuffle();
  for (int i = 0; i < colorPickers.length; ++i) {
    colorPickers[i].setColorValue(color(
      random(0, 255), random(0, 255), random(0, 255), random(0, 255)));
  }
}

/**
 * Angle knob event handler: apply new angle value to renderer.
 * @param  value  The new angle value.
 */
void angle(float value) {
  fractalRenderer.setSegmentAngle(value);

  OscMessage msg = new OscMessage("/angle");
  msg.add(value);
  op5.send(msg, remote);
}

/**
 * Tilt knob event handler.
 * @param  value  The new tilt value.
 */
void tilt(float value) {
  OscMessage msg = new OscMessage("/tilt");
  msg.add(value);
  op5.send(msg, remote);
}

/**
 * Length knob event handler: apply new length value to renderer.
 * @param  value  The new length value.
 */
void length(float value) {
  fractalRenderer.setSegmentLength(value);

  OscMessage msg = new OscMessage("/length");
  msg.add(value);
  op5.send(msg, remote);
}

/**
 * Depth knob event handler.
 * @param  value  The new depth value.
 */
void depth(float value) {
  OscMessage msg = new OscMessage("/depth");
  msg.add(value);
  op5.send(msg, remote);

  msg = new OscMessage("/sentence/compressed");
  msg.add(fractalPresets[currentFractalIndex].getCompressedSentence(value, useCache));
  op5.send(msg, remote);
}

/**
 * Wind knob event handler: apply new wind value to renderer.
 * @param  value  The new wind value.
 */
void wind(float value) {
  fractalRenderer.setTurbulenceIntensity(value);

  OscMessage msg = new OscMessage("/wind");
  msg.add(value);
  op5.send(msg, remote);
}

/**
 * MIDI note on event handler.
 * @param  channel  The MIDI channel.
 * @param  number   The MIDI note number.
 * @param  value    The velocity of the note on (0 - 127).
 */
void noteOn(int channel, int number, int value) {
  println();
  println("Note On:");
  println("--------");
  println("Channel:" + channel);
  println("Number:" + number);
  println("Value:" + value);

  // Map MIDI notes to buttons.
  if (value > 0) {
    switch (number) {
      case MidiBindings.RANDOMIZE_BTN:
        randomizeButton.setValue(1);
        break;
      case MidiBindings.PREVIOUS_COLOR_BTN:
        currentColorIndex = max(currentColorIndex - 1, 0);
        break;
      case MidiBindings.NEXT_COLOR_BTN:
        currentColorIndex = min(currentColorIndex + 1, fractalPresets.length);
        break;
      case MidiBindings.PREVIOUS_PRESET_BTN:
        currentFractalIndex = max(currentFractalIndex - 1, 0);
        break;
      case MidiBindings.NEXT_PRESET_BTN:
        currentFractalIndex = min(currentFractalIndex + 1, fractalPresets.length);
        break;
    }
  }
}

/**
 * MIDI controller change event handler.
 * @param  channel  The MIDI channel.
 * @param  number   The MIDI controller number.
 * @param  value    The value of the controller (0 - 127).
 */
void controllerChange(int channel, int number, int value) {
  println();
  println("Controller Change:");
  println("------------------");
  println("Channel:" + channel);
  println("Number:" + number);
  println("Value:" + value);

  // Map MIDI controllers to knobs & sliders.
  color currentColor;
  switch (number) {
    case MidiBindings.ANGLE_KNOB:
      angleKnob.setValue(map(value, 0, 127, angleKnob.getMin(), angleKnob.getMax()));
      break;
    case MidiBindings.TILT_KNOB:
      tiltKnob.setValue(map(value, 0, 127, tiltKnob.getMin(), tiltKnob.getMax()));
      break;
    case MidiBindings.LENGTH_KNOB:
      lengthKnob.setValue(map(value, 0, 127, lengthKnob.getMin(), lengthKnob.getMax()));
      break;
    case MidiBindings.DEPTH_KNOB:
      depthKnob.setValue(map(value, 0, 127, depthKnob.getMin(), depthKnob.getMax()));
      break;
    case MidiBindings.WIND_KNOB:
      windKnob.setValue(map(value, 0, 127, windKnob.getMin(), windKnob.getMax()));
      break;
    case MidiBindings.RED_COLOR_FADER:
      currentColor = colorPickers[currentColorIndex].getColorValue();
      colorPickers[currentColorIndex].setColorValue(color(
        map(value, 0, 127, 0, 255), green(currentColor), blue(currentColor)));
      break;
    case MidiBindings.GREEN_COLOR_FADER:
      currentColor = colorPickers[currentColorIndex].getColorValue();
      colorPickers[currentColorIndex].setColorValue(color(
        red(currentColor), map(value, 0, 127, 0, 255), blue(currentColor)));
      break;
    case MidiBindings.BLUE_COLOR_FADER:
      currentColor = colorPickers[currentColorIndex].getColorValue();
      colorPickers[currentColorIndex].setColorValue(color(
        red(currentColor), green(currentColor), map(value, 0, 127, 0, 255)));
      break;
  }
}
