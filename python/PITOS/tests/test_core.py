import numpy as np
import pytest
from pitos.core import pitos, _halton_1d, _indexed_pitcos_bidirectional, _validate_pairs

# Set a seed for reproducibility
np.random.seed(1)

# --- Helper Function Tests ---

def test_halton_1d():
    """Tests the 1D Halton sequence generator."""
    assert _halton_1d(1, 2) == 0.5
    assert _halton_1d(2, 2) == 0.25
    assert _halton_1d(3, 2) == 0.75
    assert np.isclose(_halton_1d(1, 3), 1/3)
    assert np.isclose(_halton_1d(2, 3), 2/3)

def test_indexed_pitcos_bidirectional():
    """Tests the core bidirectional PIT calculation on a perfect uniform sample."""
    n = 10
    # A perfectly sorted vector of order statistics from U(0,1)
    xo = np.arange(1, n + 1) / (n + 1.0)

    # For a perfectly uniform sample, the two-sided p-values should be large
    # Test a pair where start < finish
    u_forward = _indexed_pitcos_bidirectional(xo, n, (2, 5))
    assert 0.9 < u_forward <= 1.0

    # Test a pair where start > finish
    u_backward = _indexed_pitcos_bidirectional(xo, n, (8, 3))
    assert 0.9 < u_backward <= 1.0

# --- Input Validation Tests ---

def test_validate_pairs():
    """Tests that invalid pairs raise a ValueError."""
    n = 10
    with pytest.raises(ValueError):
        _validate_pairs([(0, 5)], n)  # i == 0
    with pytest.raises(ValueError):
        _validate_pairs([(3, 0)], n)  # j == 0
    with pytest.raises(ValueError):
        _validate_pairs([(-1, 7)], n) # i < 0
    with pytest.raises(ValueError):
        _validate_pairs([(7, 11)], n) # j > n

def test_pitos_invalid_pairs():
    """Tests the main pitos function with invalid pairs."""
    x = np.random.rand(10)
    invalid_pairs = [(5, 11)]  # Invalid pair for vector of length 10
    with pytest.raises(ValueError):
        pitos(x, pairs_sequence=invalid_pairs)

# --- Main `pitos` Functionality Tests ---

def test_pitos_main_functionality():
    """Tests the main pitos function's primary behavior."""
    n = 20
    x_rand = np.random.rand(n)

    # Test default mode
    p_default = pitos(x_rand)
    assert 0.0 <= p_default <= 1.0

    # Test mode with custom pairs
    custom_pairs = [(1, 2), (3, 4), (5, 6), (7, 8), (9, 10)]
    p_custom = pitos(x_rand, pairs_sequence=custom_pairs)
    assert 0.0 <= p_custom <= 1.0
    # Running again should yield the exact same result
    assert p_custom == pitos(x_rand, pairs_sequence=custom_pairs)

def test_pitos_edge_case_identical_values():
    """Tests with an edge-case vector (all identical values)."""
    n = 20
    # This is extremely unlikely under U(0,1), so p-value should be ~0
    x_identical = np.full(n, 0.5)
    assert pitos(x_identical) < 1e-5
