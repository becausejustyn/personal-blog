# Comparison of Spline Types

## Mathematical Definitions

### General Spline of Degree n
A spline function S(x) of degree n with knots at x₀ < x₁ < x₂ < ... < xₖ is defined as:

```
S(x) = Sᵢ(x) for x ∈ [xᵢ, xᵢ₊₁], i = 0, 1, ..., k-1
```

where each Sᵢ(x) is a polynomial of degree ≤ n:

```
Sᵢ(x) = aᵢ,ₙxⁿ + aᵢ,ₙ₋₁xⁿ⁻¹ + ... + aᵢ,₁x + aᵢ,₀
```

**Continuity Requirements:**
- S(x) is continuous (C⁰)
- Typically Cⁿ⁻¹ continuous (derivatives up to order n-1 are continuous at knots)

### Cubic Spline
A cubic spline S(x) with knots at x₀ < x₁ < x₂ < ... < xₖ is defined as:

```
S(x) = Sᵢ(x) for x ∈ [xᵢ, xᵢ₊₁], i = 0, 1, ..., k-1
```

where each Sᵢ(x) is a cubic polynomial:

```
Sᵢ(x) = aᵢx³ + bᵢx² + cᵢx + dᵢ
```

**Continuity Requirements:**
- S(xᵢ) is continuous (C⁰)
- S'(xᵢ) is continuous (C¹)
- S''(xᵢ) is continuous (C²)

**Natural Cubic Spline Boundary Conditions:**
```
S''(x₀) = 0 and S''(xₖ) = 0
```

## Comparison Table

| Feature | Linear Spline (n=1) | Quadratic Spline (n=2) | Cubic Spline (n=3) | Higher-Order Splines (n≥4) |
|---------|-------------------|----------------------|-------------------|--------------------------|
| **Polynomial Degree** | 1 | 2 | 3 | 4 or higher |
| **Continuity at Knots** | C⁰ (function only) | C⁰, C¹ | C⁰, C¹, C² | C⁰, C¹, ..., Cⁿ⁻¹ |
| **Shape** | Piecewise straight lines | Piecewise parabolas | Smooth curves | Very smooth curves |
| **Curvature** | Undefined (discontinuous) | C⁰ (discontinuous derivative) | C¹ (smooth curvature) | Higher-order smooth |

### Pros and Cons

| Aspect | Linear Spline | Quadratic Spline | Cubic Spline | Higher-Order Splines |
|--------|--------------|------------------|--------------|---------------------|
| **PROS** | • Simplest to compute<br>• Guaranteed stable<br>• No overshooting<br>• Minimal computation | • Simple computation<br>• Smooth first derivative<br>• Moderate flexibility | • Optimal smoothness/complexity<br>• Smooth curvature (C²)<br>• Natural-looking curves<br>• Industry standard<br>• Good numerical stability | • Maximum smoothness<br>• Can match complex shapes<br>• Higher-order continuity |
| **CONS** | • Not smooth (sharp corners)<br>• Unrealistic for natural phenomena<br>• No curvature control | • Curvature discontinuities<br>• Less commonly used<br>• Can still have visible "kinks"<br>• Moderate oscillation risk | • More complex than linear/quadratic<br>• Can oscillate between points<br>• Requires boundary conditions | • Computationally expensive<br>• High oscillation risk (Runge phenomenon)<br>• Numerical instability<br>• Overfitting tendency<br>• Rarely needed in practice |
| **Best Use Cases** | • Simple data visualization<br>• When speed is critical<br>• Polygonal approximations<br>• Games/graphics (collision) | • When C¹ continuity needed<br>• Computer-aided design<br>• Font rendering | • Curve fitting<br>• Computer graphics<br>• Animation paths<br>• CAD/CAM systems<br>• Data interpolation<br>• Statistical smoothing | • Specialized applications<br>• When extreme smoothness required<br>• Theoretical mathematics |
| **Computational Cost** | Very Low (O(n)) | Low (O(n)) | Moderate (O(n)) | High (O(n³) or higher) |
| **Parameters per Segment** | 2 coefficients | 3 coefficients | 4 coefficients | n+1 coefficients |

## Visual Characteristics

| Spline Type | Appearance at Knots | Overall Smoothness | Typical Applications |
|-------------|-------------------|-------------------|---------------------|
| **Linear** | Sharp corners (angular) | Not smooth | Technical drawings, polygons |
| **Quadratic** | Smooth tangent, kinked curvature | Moderately smooth | Some CAD systems |
| **Cubic** | Smooth tangent and curvature | Very smooth | Animation, graphics, statistics |
| **Higher-Order** | Extremely smooth | Potentially too smooth | Mathematical analysis |

## Summary

**Cubic splines are the "Goldilocks" solution** — they provide enough smoothness for realistic curves (C² continuity) without the computational cost and instability of higher-order splines. This is why they're the default choice in most practical applications, from computer graphics to data analysis.