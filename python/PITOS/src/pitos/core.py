import numpy as np
from scipy.stats import beta, cauchy
from typing import List, Tuple, Union, Optional

def pitos(
    x: Union[List[float], np.ndarray],
    pairs_sequence: Optional[List[Tuple[int, int]]] = None
) -> float:
    """
    Performs the PITOS test to check if a numeric vector follows a
    uniform distribution on the interval (0,1).

    Args:
        x: A numeric vector of values to test.
        pairs_sequence: An optional list of tuples, where each tuple
            represents a pair of indices (start, finish) to be tested. If None,
            a weighted Halton sequence is generated automatically.

    Returns:
        A single p-value from the Cauchy combination test.
    """
    n = len(x)

    if pairs_sequence is None:
        N = round(10 * n * np.log(n))
        pairs_sequence = generate_weighted_halton_sequence(N, n)

    _validate_pairs(pairs_sequence, n)

    xo = np.sort(x)

    p_values = np.array([
        _indexed_pitcos_bidirectional(xo, n, pair) for pair in pairs_sequence
    ])

    return _cauchy_combination(p_values)

# --- Internal Helper Functions ---

def _halton_1d(i: int, b: int) -> float:
    result = 0.0
    f = 1.0
    while i > 0:
        f /= b
        result += f * (i % b)
        i //= b
    return result

def _generate_raw_halton_sequence(N: int, n: int) -> np.ndarray:
    if n <= 0:
        raise ValueError("Sample size n must be a positive integer.")
    base_x, base_y = 2, 3
    i = np.arange(1, N + 1)
    x_raw = np.array([_halton_1d(val, base_x) for val in i])
    y_raw = np.array([_halton_1d(val, base_y) for val in i])
    return np.column_stack((x_raw, y_raw))

def generate_weighted_halton_sequence(N: int, n: int) -> List[Tuple[int, int]]:
    raw_halton = _generate_raw_halton_sequence(N, n)

    weighted_x = beta.ppf(raw_halton[:, 0], 0.7, 0.7)
    weighted_y = beta.ppf(raw_halton[:, 1], 0.7, 0.7)

    weighted_x[weighted_x == 0] = 1 / n
    weighted_y[weighted_y == 0] = 1 / n

    weighted_pairs = np.ceil(np.column_stack((weighted_x * n, weighted_y * n)))

    marginals = np.column_stack((np.arange(1, n + 1), np.arange(1, n + 1)))

    all_pairs = np.vstack((weighted_pairs, marginals)).astype(int)
    return [tuple(row) for row in all_pairs]

def _indexed_pitcos_bidirectional(xo: np.ndarray, n: int, pair: Tuple[int, int]) -> float:
    start, finish = pair
    # Adjust for 0-based indexing
    start_idx, finish_idx = start - 1, finish - 1

    u = 0.0
    if start == finish:
        u = beta.cdf(xo[finish_idx], finish, n - finish + 1)
    elif start < finish:
        if xo[start_idx] == xo[finish_idx]:
            u = 0.0
        else:
            val = (xo[finish_idx] - xo[start_idx]) / (1.0 - xo[start_idx])
            u = beta.cdf(val, finish - start, n - finish + 1)
    else:  # start > finish
        if xo[start_idx] == xo[finish_idx]:
            u = 0.0
        else:
            val = xo[finish_idx] / xo[start_idx]
            u = beta.cdf(val, finish, start - finish)

    return 2.0 * min(u, 1.0 - u)

def _cauchy_combination(pvalues: np.ndarray) -> float:
    if np.any((pvalues < 0) | (pvalues > 1)):
        raise ValueError("All p-values must be in the range [0, 1].")
    
    statistic = np.mean(np.tan(np.pi * (0.5 - pvalues)))
    return cauchy.sf(statistic)

def _validate_pairs(pairs: List[Tuple[int, int]], n: int):
    pairs_arr = np.array(pairs)
    if np.any(pairs_arr < 1) or np.any(pairs_arr > n):
        raise ValueError(f"All pair indices must be between 1 and n (where n={n}).")
