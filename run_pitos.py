import sys
import numpy as np
from pitos import pitos

def main():
    if len(sys.argv) != 2:
        print("Usage: python run_pitos.py <filepath>", file=sys.stderr)
        sys.exit(1)

    filepath = sys.argv[1]
    data = np.loadtxt(filepath)

    p_value = pitos(data)

    # Print only the final p-value, formatted for consistency
    print(f"{p_value:.18f}")

if __name__ == "__main__":
    main()
