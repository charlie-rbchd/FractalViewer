public class TurtleRenderer implements ILSystemRenderer {
  private float segmentLength;
  private float segmentAngle;
  private float turbulenceIntensity;
  private color[] segmentColors;

  private float perlinNoiseXOffset;
  private float perlinNoiseYOffset;
  //private int perlinNoiseSeed = 5;

  /**
   * Constructor.
   */
  public TurtleRenderer() {
    this.segmentLength = 0;
    this.segmentAngle = 0;
    this.turbulenceIntensity = 0;
    this.segmentColors = new color[]{0};

    this.perlinNoiseXOffset = 0;
    this.perlinNoiseYOffset = 0;
  }

  /**
   * Constructor.
   * @param  segmentLength  The length of the rendered segments.
   * @param  segmentAngle   The branching angle of the rendered segments.
   */
  public TurtleRenderer(float segmentLength, float segmentAngle) {
    this.segmentLength = segmentLength;
    this.segmentAngle = segmentAngle;
    this.turbulenceIntensity = 0;
    this.segmentColors = new color[]{0};

    this.perlinNoiseXOffset = 0;
    this.perlinNoiseYOffset = 0;
  }

  /**
   * Render an L-System sentence.
   * @param  sentence  The L-System sentence to be renderer.
   */
  public void render(String sentence) {
    // TODO: Implement advanced drawing techniques such as variable strokeWidth and leaf drawing.
    stroke(this.segmentColors[0]);

    this.perlinNoiseXOffset = 0;
    this.perlinNoiseYOffset += 0.005;
    //noiseSeed(perlinNoiseSeed);

    boolean colorChange = false;

    for (int i = 0; i < sentence.length(); i++) {
      char c = sentence.charAt(i);

      // Step the turbulence system.
      this.perlinNoiseXOffset += 0.1;
      float angleNoise = map(noise(this.perlinNoiseXOffset + i, this.perlinNoiseYOffset), 0, 1,
                                   -this.segmentAngle * this.turbulenceIntensity,
                                    this.segmentAngle * this.turbulenceIntensity);

      // The next character after a color change is always the number of the new color.
      if (colorChange) {
        int colorIndex = Integer.parseInt(str(c));
        stroke(this.segmentColors[colorIndex % this.segmentColors.length]);
        colorChange = false;
        continue;
      }

      // Map sentence characters to drawing instructions.
      switch (c) {
        case 'F': // Draw forward and move
          line(0, 0, this.segmentLength, 0);
          translate(this.segmentLength, 0);
          break;
        case 'G': // Move only
          translate(this.segmentLength, 0);
          break;
        case 'C': // Initiates a color change command
          colorChange = true;
          break;
        case '+': // Turn left
          rotateZ(this.segmentAngle + angleNoise);
          break;
        case '-': // Turn right
          rotateZ(-this.segmentAngle + angleNoise);
          break;
        case '|': // Turn around
          rotateZ(PI);
          break;
        case '&': // Pitch down
          rotateY(this.segmentAngle);
          break;
        case '^': // Pitch right
          rotateY(-this.segmentAngle);
          break;
        case '\\': // Roll left
          rotateX(this.segmentAngle);
          break;
        case '/': // Roll right
          rotateX(-this.segmentAngle);
          break;
        case '[': // Save position
          pushMatrix();
          break;
        case ']': // Restore previously-saved position
          popMatrix();
          break;
      }
    }
  }

  /**
   * Retrieve the current segment length.
   * @return The current segment length.
   */
  public float getSegmentLength() {
    return this.segmentLength;
  }

  /**
   * Change the current segment length.
   * @param  newSegmentLength  The new segment length.
   */
  public void setSegmentLength(float newSegmentLength) {
    this.segmentLength = newSegmentLength;
  }

  /**
   * Retrieve the current segment or branching angle.
   * @return The current segment angle.
   */
  public float getSegmentAngle() {
    return this.segmentAngle;
  }

  /**
   * Change the current segment or branching angle.
   * @param  newSegmentAngle  The new segment angle.
   */
  public void setSegmentAngle(float newSegmentAngle) {
    this.segmentAngle = newSegmentAngle;
  }

  /**
   * Retrieve the current turbulence intensity.
   * @return The current turbulence intensity.
   */
  public float getTurbulenceIntensity() {
    return this.turbulenceIntensity;
  }

  /**
   * Change the current turbulence intensity.
   * @param  newTurbulenceIntensity  The new turbulence intensity.
   */
  public void setTurbulenceIntensity(float newTurbulenceIntensity) {
    this.turbulenceIntensity = newTurbulenceIntensity;
  }

  /**
   * Change the current segment colors array.
   * @param  newSegmentColor  The new segment color that is applied to the whole colors array.
   */
  public void setSegmentColor(color newSegmentColor) {
    this.segmentColors = new color[]{newSegmentColor};
  }

  /**
   * Change the current segment colors array.
   * @param  newSegmentColors  The new segment colors.
   */
  public void setSegmentColors(color[] newSegmentColors) {
    this.segmentColors = newSegmentColors;
  }

  /**
   * Retrieve the current segment colors array.
   * @return The current segment colors.
   */
  public color[] getSegmentColors() {
    return this.segmentColors;
  }
}

