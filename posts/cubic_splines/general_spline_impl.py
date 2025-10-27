import numpy as np
from sklearn.base import BaseEstimator, TransformerMixin


class BSpline(BaseEstimator, TransformerMixin):
    """
    B-spline transformer for scikit-learn pipelines.
    
    This implements B-splines of arbitrary degree using the Cox-de Boor
    recursion algorithm, which is numerically stable and efficient.
    
    Parameters
    ----------
    degree : int, default=3
        Degree of the spline polynomials. 
        - degree=1: Linear splines
        - degree=2: Quadratic splines
        - degree=3: Cubic splines (default)
        - degree>=4: Higher-order splines
        
    n_knots : int, default=5
        Number of interior knots (not counting boundary knots).
        Total number of knots will be n_knots + 2.
        
    knots : array-like, optional
        Explicit knot locations. If provided, overrides n_knots.
        Must be sorted in ascending order.
        
    include_bias : bool, default=True
        Whether to include a bias (intercept) column.
        
    Attributes
    ----------
    knots_ : ndarray
        Full knot vector including boundary knots and multiplicities.
        
    n_bases_ : int
        Number of basis functions (output features).
        
    References
    ----------
    de Boor, C. (2001). A Practical Guide to Splines (Revised Edition).
    Springer.
    
    Hastie, T., Tibshirani, R., & Friedman, J. (2009). The Elements of 
    Statistical Learning (2nd ed.). Springer.
    """
    
    def __init__(self, degree=3, n_knots=5, knots=None, include_bias=True):
        self.degree = degree
        self.n_knots = n_knots
        self.knots = knots
        self.include_bias = include_bias
    
    def fit(self, X, y=None):
        """
        Compute knot locations based on the training data.
        
        Parameters
        ----------
        X : array-like of shape (n_samples, 1)
            Training data.
        y : Ignored
            Not used, present for API consistency.
            
        Returns
        -------
        self : object
            Fitted transformer.
        """
        # Convert to numpy array and ensure 2D
        X = np.asarray(X)
        if X.ndim == 1:
            X = X.reshape(-1, 1)
        
        if X.shape[1] != 1:
            raise ValueError("BSpline only supports single feature input")
        
        X_flat = X.ravel()
        
        # Determine knot locations
        if self.knots is not None:
            interior_knots = np.asarray(self.knots)
        else:
            # Place knots at quantiles for even spacing in data distribution
            quantiles = np.linspace(0, 1, self.n_knots + 2)[1:-1]
            interior_knots = np.quantile(X_flat, quantiles)
        
        # Create full knot vector with multiplicities at boundaries
        # For B-splines, we need (degree + 1) repeated knots at each boundary
        x_min, x_max = X_flat.min(), X_flat.max()
        
        # Add small padding to boundaries to ensure all data points are covered
        x_min -= 1e-10 * (x_max - x_min)
        x_max += 1e-10 * (x_max - x_min)
        
        self.knots_ = np.concatenate([
            np.repeat(x_min, self.degree + 1),
            interior_knots,
            np.repeat(x_max, self.degree + 1)
        ])
        
        # Number of basis functions
        # For B-splines: n_bases = n_knots + degree + 1
        self.n_bases_ = len(self.knots_) - self.degree - 1
        
        return self
    
    def transform(self, X, y=None):
        """
        Transform X into B-spline basis expansion.
        
        Parameters
        ----------
        X : array-like of shape (n_samples, 1)
            Data to transform.
        y : Ignored
            Not used, present for API consistency.
            
        Returns
        -------
        basis_expansion : ndarray of shape (n_samples, n_bases)
            Transformed features.
        """
        # Convert to numpy array and ensure 2D
        X = np.asarray(X)
        if X.ndim == 1:
            X = X.reshape(-1, 1)
        
        X_flat = X.ravel()
        n_samples = len(X_flat)
        
        # Compute B-spline basis functions using Cox-de Boor recursion
        basis = np.zeros((n_samples, self.n_bases_))
        
        for i in range(n_samples):
            x = X_flat[i]
            basis[i, :] = self._bspline_basis(x, self.degree, self.knots_)
        
        if not self.include_bias:
            # Remove the first basis function (constant term)
            basis = basis[:, 1:]
        
        return basis
    
    def _bspline_basis(self, x, degree, knots):
        """
        Compute all B-spline basis functions at point x using Cox-de Boor recursion.
        
        Parameters
        ----------
        x : float
            Point at which to evaluate basis functions.
        degree : int
            Degree of the B-spline.
        knots : ndarray
            Full knot vector.
            
        Returns
        -------
        basis : ndarray
            Values of all basis functions at x.
        """
        n_bases = len(knots) - degree - 1
        basis = np.zeros(n_bases)
        
        # Find the knot span that contains x
        # This is the index i such that knots[i] <= x < knots[i+1]
        if x == knots[-1]:
            # Special case: x is exactly at the right boundary
            span = n_bases - 1
        else:
            span = np.searchsorted(knots, x, side='right') - 1
            span = max(degree, min(span, n_bases - 1))
        
        # Initialize: degree 0 basis functions (piecewise constants)
        basis_prev = np.zeros(n_bases)
        if span < n_bases:
            basis_prev[span] = 1.0
        
        # Cox-de Boor recursion: build up from degree 0 to target degree
        for d in range(1, degree + 1):
            basis_curr = np.zeros(n_bases)
            
            for i in range(n_bases):
                # Left term
                if basis_prev[i] != 0:
                    denom = knots[i + d] - knots[i]
                    if denom != 0:
                        basis_curr[i] += (x - knots[i]) / denom * basis_prev[i]
                
                # Right term
                if i + 1 < n_bases and basis_prev[i + 1] != 0:
                    denom = knots[i + d + 1] - knots[i + 1]
                    if denom != 0:
                        basis_curr[i] += (knots[i + d + 1] - x) / denom * basis_prev[i + 1]
            
            basis_prev = basis_curr
        
        return basis_prev


# Example usage demonstrating different spline degrees
if __name__ == "__main__":
    # Generate sample data
    np.random.seed(42)
    X = np.linspace(0, 10, 100).reshape(-1, 1)
    y = np.sin(X).ravel() + np.random.normal(0, 0.1, 100)
    
    # Linear B-spline
    linear_spline = BSpline(degree=1, n_knots=5)
    linear_spline.fit(X)
    X_linear = linear_spline.transform(X)
    print(f"Linear B-spline: {X_linear.shape[1]} basis functions")
    
    # Quadratic B-spline
    quad_spline = BSpline(degree=2, n_knots=5)
    quad_spline.fit(X)
    X_quad = quad_spline.transform(X)
    print(f"Quadratic B-spline: {X_quad.shape[1]} basis functions")
    
    # Cubic B-spline
    cubic_spline = BSpline(degree=3, n_knots=5)
    cubic_spline.fit(X)
    X_cubic = cubic_spline.transform(X)
    print(f"Cubic B-spline: {X_cubic.shape[1]} basis functions")
    
    # Quartic B-spline
    quartic_spline = BSpline(degree=4, n_knots=5)
    quartic_spline.fit(X)
    X_quartic = quartic_spline.transform(X)
    print(f"Quartic B-spline: {X_quartic.shape[1]} basis functions")
    
    # Example with sklearn pipeline
    from sklearn.linear_model import LinearRegression
    from sklearn.pipeline import Pipeline
    
    pipeline = Pipeline([
        ('spline', BSpline(degree=3, n_knots=4)),
        ('regression', LinearRegression())
    ])
    
    pipeline.fit(X[:80], y[:80])
    y_pred = pipeline.predict(X[80:])
    print(f"\nPipeline fitted successfully")
    print(f"Test predictions shape: {y_pred.shape}")
