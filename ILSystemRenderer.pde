/**
 * An interface is defined for L-System renderers so that renderers can be easily swapped.
 */
public interface ILSystemRenderer {
  public void render(String sentence);

  public float getSegmentLength();
  public void setSegmentLength(float newSegmentLength);

  public float getSegmentAngle();
  public void setSegmentAngle(float newSegmentAngle);

  public float getTurbulenceIntensity();
  public void setTurbulenceIntensity(float newTurbulenceIntensity);

  public void setSegmentColor(color newSegmentColor);
  public void setSegmentColors(color[] newSegmentColors);
  public color[] getSegmentColors();
}
