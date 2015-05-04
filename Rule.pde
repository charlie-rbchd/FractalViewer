public class Rule {
  private char predecessor;
  private String[] successors;
  private float[] weights;

  /**
   * Stochastic rule constructor.
   * @param  predecessor  The character to be substituted.
   * @param  successors   The substitution string or strings in the case of stochastic rules.
   * @param  weights      The weight of each substitution string in the case of stochastic rules.
   */
  public Rule(char predecessor, String[] successors, float[] weights) {
    this.predecessor = predecessor;
    this.successors = successors;
    this.weights = weights;
  }

  /**
   * Stochastic rule with evenly distributed probabilities constructor.
   * @param  predecessor  The character to be substituted.
   * @param  successors   The substitution string or strings in the case of stochastic rules.
   */
  public Rule(char predecessor, String[] successors) {
    float p = 1.0 / successors.length;
    float[] weights = new float[successors.length];

    // All successors have equal weight by default.
    for (int i = 0; i < weights.length; ++i) {
      weights[i] = p;
    }

    this.predecessor = predecessor;
    this.successors = successors;
    this.weights = weights;
  }

  /**
   * Non stochastic rule constructor.
   * @param  predecessor  The character to be substituted.
   * @param  successor    The substitution string.
   */
  public Rule(char predecessor, String successor) {
    this.predecessor = predecessor;
    this.successors = new String[]{successor};
    this.weights = new float[]{1};
  }

  /**
   * Verify whether or not the specified character matches the characted to be substituted.
   * @param  c  The character to be compared.
   * @return    Whether or not the specified character matches the characted to be substituted.
   */
  public boolean matches(char c) {
    return this.predecessor == c;
  }

  /**
   * Retrieve the character to be substituted.
   * @return The character to be substituted.
   */
  public char getPredecessor() {
    return this.predecessor;
  }

  /**
   * Retrieve the subtitution string, which is computed using a weighted random in the case of stochastic rules.
   * @return The substitution string.
   */
  public String getSuccessor() {
    // Sum the weights, wrap around when the number of successors is not equal to the number of weights.
    float sum = 0;
    for (int i = 0; i < this.successors.length; ++i) {
      sum += this.weights[i % this.weights.length];
    }

    // Perform a weighted random.
    float rand = random(0, sum);
    for (int i = 0; i < this.successors.length; ++i) {
      rand -= this.weights[i % this.weights.length];
      if (rand <= 0) {
        return this.successors[i];
      }
    }

    // Return nothing is no successors are specified.
    return "";
  }
}
