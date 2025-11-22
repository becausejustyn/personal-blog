// ==============================================================================
// B-SPLINE STAN MODEL
// ==============================================================================

functions {
  /**
   * Compute B-spline basis functions using Cox-de Boor recursion
   * 
   * @param x Point at which to evaluate basis functions
   * @param degree Degree of the B-spline (1=linear, 2=quadratic, 3=cubic, etc.)
   * @param knots Full knot vector including boundary repetitions
   * @return Vector of basis function values
   */
  vector bspline_basis(real x, int degree, vector knots) {
    int n_knots = num_elements(knots);
    int n_bases = n_knots - degree - 1;
    vector[n_bases] basis = rep_vector(0.0, n_bases);
    vector[n_bases] basis_prev = rep_vector(0.0, n_bases);
    vector[n_bases] basis_curr;
    int span;
    real denom;
    
    // Find knot span containing x
    if (x == knots[n_knots]) {
      span = n_bases;
    } else {
      span = 1;
      while (span < n_knots && x >= knots[span + 1]) {
        span += 1;
      }
      if (span < degree + 1) span = degree + 1;
      if (span > n_bases) span = n_bases;
    }
    
    // Initialize degree 0 (piecewise constant)
    if (span <= n_bases) {
      basis_prev[span] = 1.0;
    }
    
    // Cox-de Boor recursion
    for (d in 1:degree) {
      basis_curr = rep_vector(0.0, n_bases);
      
      for (i in 1:n_bases) {
        // Left term
        if (basis_prev[i] != 0) {
          denom = knots[i + d] - knots[i];
          if (denom != 0) {
            basis_curr[i] += (x - knots[i]) / denom * basis_prev[i];
          }
        }
        
        // Right term
        if (i + 1 <= n_bases && basis_prev[i + 1] != 0) {
          denom = knots[i + d + 1] - knots[i + 1];
          if (denom != 0) {
            basis_curr[i] += (knots[i + d + 1] - x) / denom * basis_prev[i + 1];
          }
        }
      }
      
      basis_prev = basis_curr;
    }
    
    return basis_prev;
  }
  
  /**
   * Compute B-spline basis matrix for multiple observations
   * 
   * @param x Vector of data points
   * @param degree Degree of the B-spline
   * @param knots Full knot vector
   * @return Matrix where each row contains basis functions for one observation
   */
  matrix bspline_basis_matrix(vector x, int degree, vector knots) {
    int n = num_elements(x);
    int n_bases = num_elements(knots) - degree - 1;
    matrix[n, n_bases] basis_matrix;
    
    for (i in 1:n) {
      basis_matrix[i, ] = bspline_basis(x[i], degree, knots)';
    }
    
    return basis_matrix;
  }
}

data {
  int<lower=1> N;                    // Number of observations
  vector[N] x;                        // Predictor variable
  vector[N] y;                        // Response variable
  int<lower=1> degree;                // Degree of B-spline
  int<lower=1> n_interior_knots;      // Number of interior knots
}

transformed data {
  int n_knots_total = n_interior_knots + 2 * (degree + 1);
  vector[n_knots_total] knots;
  int n_bases = n_knots_total - degree - 1;
  matrix[N, n_bases] B;
  real x_min = min(x);
  real x_max = max(x);
  
  // Create knot vector with boundary repetitions
  {
    vector[n_interior_knots] interior_knots;
    
    // Place interior knots at quantiles
    for (i in 1:n_interior_knots) {
      real quantile = (i * 1.0) / (n_interior_knots + 1.0);
      interior_knots[i] = x_min + quantile * (x_max - x_min);
    }
    
    // Build full knot vector
    for (i in 1:(degree + 1)) {
      knots[i] = x_min - 1e-10 * (x_max - x_min);
    }
    
    for (i in 1:n_interior_knots) {
      knots[degree + 1 + i] = interior_knots[i];
    }
    
    for (i in 1:(degree + 1)) {
      knots[degree + 1 + n_interior_knots + i] = x_max + 1e-10 * (x_max - x_min);
    }
  }
  
  // Compute basis matrix
  B = bspline_basis_matrix(x, degree, knots);
}

parameters {
  vector[n_bases] beta;               // Spline coefficients
  real<lower=0> sigma;                // Residual standard deviation
}

model {
  // Priors
  beta ~ normal(0, 5);
  sigma ~ exponential(1);
  
  // Likelihood
  y ~ normal(B * beta, sigma);
}

generated quantities {
  vector[N] y_pred = B * beta;
  vector[N] log_lik;
  
  for (i in 1:N) {
    log_lik[i] = normal_lpdf(y[i] | y_pred[i], sigma);
  }
}
