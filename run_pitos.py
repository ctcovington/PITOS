# run_pitos.py
import sys
import numpy as np
from pitos import pitos

def main():
    if len(sys.argv) != 2:
        print("Usage: python run_pitos.py <filepath>", file=sys.stderr)
        sys.exit(1)

    filepath = sys.argv[1]
    # Load the entire matrix of simulations.
    # np.atleast_2d ensures it works even if there's only one row.
    data_matrix = np.atleast_2d(np.loadtxt(filepath))

    # Calculate p-value for each row (each simulation)
    p_values = np.apply_along_axis(pitos, 1, data_matrix)

    # Print each p-value on a new line
    for p_value in p_values:
        print(f"{p_value:.18f}")

if __name__ == "__main__":
    main()