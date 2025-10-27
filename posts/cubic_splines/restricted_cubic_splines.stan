// ==============================================================================
// RESTRICTED CUBIC SPLINE STAN MODEL
// ==============================================================================

functions {
  /**
   * Linear spline component (positive part function)
   */
  real linear_spline(real x) {
    return fmax(x, 0.0);
  }
  
  /**
   * Compute restricted cubic spline basis for a single observation
   * 
   * @param x Data point
   * @param knots Vector of knot locations
   * @return Vector of basis function values
   */
  vector rcs_basis(real x, vector knots) {
    int k = num_elements(knots);
    vector[k - 1] basis;
    real range = knots[k] - knots[1];
    real t_km2 = knots[k - 1];
    real t_k = knots[k];
    
    // First basis function is just x
    basis[1] = x;
    
    // Compute remaining basis functions
    for (j in 1:(k - 2)) {
      real t_j = knots[j];
      real term1 = pow(linear_spline(x - t_j), 3);
      real term2 = pow(linear_spline(x - t_km2), 3) * (t_k - t_j) / (t_k - t_km2);
      real term3 = pow(linear_spline(x - t_k), 3) * (t_km2 - t_j) / (t_k - t_km2);
      
      basis[j + 1] = (term1 - term2 + term3) / pow(range, 2);
    }
    
    return basis;
  }
  
  /**
   * Compute RCS basis matrix for multiple observations
   */
  matrix rcs_basis_matrix(vector x, vector knots) {
    int n = num_elements(x);
    int n_bases = num_elements(knots) - 1;
    matrix[n, n_bases] basis_matrix;
    
    for (i in 1:n) {
      basis_matrix[i, ] = rcs_basis(x[i], knots)';
    }
    
    return basis_matrix;
  }
}

data {
  int<lower=1> N;              // Number of observations
  vector[N] x;                  // Predictor variable
  vector[N] y;                  // Response variable
  int<lower=3,upper=7> k;       // Number of knots (3-7)
}

transformed data {
  vector[k] knots;
  matrix[N, k - 1] R;
  
  // Knot locations based on Harrell's recommendations
  if (k == 3) {
    knots = quantile(x, [0.1, 0.5, 0.9]');
  } else if (k == 4) {
    knots = quantile(x, [0.05, 0.365, 0.65, 0.95]');
  } else if (k == 5) {
    knots = quantile(x, [0.05, 0.275, 0.5, 0.725, 0.95]');
  } else if (k == 6) {
    knots = quantile(x, [0.05, 0.23, 0.41, 0.59, 0.77, 0.95]');
  } else { // k == 7
    knots = quantile(x, [0.025, 0.1833, 0.3417, 0.5, 0.6583, 0.8167, 0.975]');
  }
  
  // Compute RCS basis matrix
  R = rcs_basis_matrix(x, knots);
}

parameters {
  vector[k - 1] beta;          // Spline coefficients
  real<lower=0> sigma;         // Residual standard deviation
}

model {
  // Priors
  beta ~ normal(0, 5);
  sigma ~ exponential(1);
  
  // Likelihood
  y ~ normal(R * beta, sigma);
}

generated quantities {
  vector[N] y_pred = R * beta;
  vector[N] log_lik;
  
  for (i in 1:N) {
    log_lik[i] = normal_lpdf(y[i] | y_pred[i], sigma);
  }
}