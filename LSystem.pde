import javax.xml.bind.DatatypeConverter;
import java.util.zip.*;
import java.io.*;

public class LSystem {
  private Rule[] productionRules;
  private String sentence;
  private String axiom;
  private float iterationDepth;

  /**
   * Constructor.
   * @param axiom           The starting sentence from which sentences of deeper iterations are generated.
   * @param roductionRules  The set of rules from which the sentences are generated.
   */
  public LSystem(String axiom, Rule[] productionRules) {
    this.axiom = axiom;
    this.sentence = axiom;
    this.productionRules = productionRules;
    this.iterationDepth = 0;
  }

  /**
   * Compute the sentence of the L-System according to the current iteration depth.
   * @param  percentage  The fraction of the current iteration depth that needs to be computed.
   */
  private void generate(float percentage) {
    StringBuffer next = new StringBuffer();
    int limit = round(this.sentence.length() * percentage);

    for (int i = 0; i < this.sentence.length(); ++i) {
      char predecessor = this.sentence.charAt(i);
      String successor = str(predecessor);

      if (i < limit) {
        for (int j = 0; j < this.productionRules.length; ++j) {
          if (this.productionRules[j] != null && this.productionRules[j].matches(predecessor)) {
            successor = this.productionRules[j].getSuccessor();
            break;
          }
        }
      }

      next.append(successor);
    }

    this.sentence = next.toString();
  }

  /**
   * Reinitialize the L-System's state to default.
   */
  private void reset() {
    this.sentence = this.axiom;
    this.iterationDepth = 0;
  }

  /**
   * Retrieve the sentence of the L-System for a specific iteration depth.
   * @param  iterationDepth  The iteration depth.
   * @return                 The generated sentence.
   */
  public String getSentence(float iterationDepth) {
    this.reset();
    this.iterationDepth = iterationDepth;

    int integerIterationPart = int(iterationDepth);
    float fractionalIterationPart = iterationDepth - integerIterationPart;

    for (int i = 0; i <= integerIterationPart; ++i) {
      this.generate((i == integerIterationPart) ? fractionalIterationPart : 1);
    }

    return this.sentence;
  }

  /**
   * Retrieve the sentence of the L-System for a specific iteration depth.
   * @param  iterationDepth  The iteration depth.
   * @param  useCache        Whether or not the last computation can be used if the iteration depth is the same.
   * @return                 The generated sentence.
   */
  public String getSentence(float iterationDepth, boolean useCache) {
    if (useCache && iterationDepth == this.iterationDepth) {
      return this.sentence;
    }

    return this.getSentence(iterationDepth);
  }

  /**
   * Convert a sentence into a gzipped (and converted into base64) version of it.
   * @param  sentence  The sentence to be converted.
   * @return           The gzipped (in base64) version of the sentence.
   */
  private String compressSentence(String sentence) {
    try {
      if (sentence == null || sentence.length() == 0) {
        return null;
      } else {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        GZIPOutputStream os = new GZIPOutputStream(baos);

        byte[] input = sentence.getBytes("UTF-8");
        os.write(input, 0, input.length);
        os.close();
        byte[] output = baos.toByteArray();

        return DatatypeConverter.printBase64Binary(output);
      }
    } catch (java.io.IOException ex) {
      return null;
    }
  }

  /**
   * Retrieve a gzipped (in base64) version of the sentence of the L-System for a specific iteration depth.
   * @param  iterationDepth  The iteration depth.
   * @return                 The gzipped (in base64) generated sentence.
   */
  public String getCompressedSentence(float iterationDepth) {
    return this.compressSentence(this.getSentence(iterationDepth));
  }

  /**
   * Retrieve a gzipped (in base64) version of the sentence of the L-System for a specific iteration depth.
   * @param  iterationDepth  The iteration depth.
   * @param  useCache        Whether or not the last computation can be used if the iteration depth is the same.
   * @return                 The gzipped (in base64) generated sentence.
   */
  public String getCompressedSentence(float iterationDepth, boolean useCache) {
    return this.compressSentence(this.getSentence(iterationDepth, useCache));
  }

  /**
   * Retrieve the current iteration depth.
   * @return The iteration depth.
   */
  public float getIterationDepth() {
    return this.iterationDepth;
  }
}
