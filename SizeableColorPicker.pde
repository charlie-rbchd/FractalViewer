import controlP5.*;

/**
 * Extend the controlP5 color picker in order to implement a resize functionality.
 */
public class SizeableColorPicker extends ColorPicker {
  SizeableColorPicker(ControlP5 cp5, String name) {
    super(cp5, cp5.getTab("default"), name, 0, 0, 100, 10);
  }

  void setItemSize(int w, int h) {
    sliderRed.setSize(w, h);
    sliderGreen.setSize(w, h);
    sliderBlue.setSize(w, h);
    sliderAlpha.setSize(w, h);

    sliderGreen.setPosition(PVector.add(sliderGreen.getPosition(),
        new PVector(0, h - 10)));
    sliderBlue.setPosition(PVector.add(sliderBlue.getPosition(),
        new PVector(0, 2 * (h - 10))));
    sliderAlpha.setPosition(PVector.add(sliderAlpha.getPosition(),
        new PVector(0, 3 * (h - 10))));
  }
}
