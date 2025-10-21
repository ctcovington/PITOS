# PITOS

This repository provides implementations of the PITOS goodness-of-fit test in Julia, R, and Python.

## Repository Structure

The repository is organized by language:

-   `/julia/PITOS/`: Contains the Julia package for PITOS.
-   `/r/PITOS/`: Contains the R package for PITOS.
-   `/python/PITOS/`: Contains the Python package for PITOS.
-   `validate_packages.jl`: A Julia script to run all three implementations on the same data and verify that their outputs are consistent.

## Installation

### Julia

To use the Julia package, you need to activate the project environment and instantiate its dependencies.

1.  Navigate to the Julia package directory:
    ```sh
    cd julia/PITOS
    ```

2.  Start the Julia REPL:
    ```sh
    julia
    ```

3.  In the Julia REPL, press `]` to enter the Pkg mode, then run:
    ```julia
    pkg> activate .
    pkg> instantiate
    ```

### R

The R package can be installed using the `devtools` package.

1.  Start an R session.

2.  Install `devtools` if you haven't already:
    ```R
    install.packages("devtools")
    ```

3.  Install the PITOS package from the local source:
    ```R
    devtools::install("r/PITOS")
    ```

### Python

The Python package can be installed using `pip`. It is recommended to use a virtual environment.

1.  Create and activate a virtual environment from the repository root:
    ```sh
    python3 -m venv venv
    source venv/bin/activate
    ```

2.  Install the package in editable mode:
    ```sh
    pip install -e python/PITOS
    ```

## Usage

### Julia

```julia
using Pkg
Pkg.activate("julia/PITOS")
using PITOS

# Generate some uniform data
uniform_data = rand(50)

# Run the test
p_value = pitos(uniform_data)
println("PITOS p-value: ", p_value)
```

### R

```R
library(PITOS)

# Generate some uniform data
set.seed(123)
uniform_data <- runif(50)

# Run the test
p_value <- pitos(uniform_data)
print(paste("PITOS p-value:", p_value))
```

### Python

```python
import numpy as np
from pitos import pitos

# Generate some uniform data
uniform_data = np.random.rand(50)

# Run the test
p_value = pitos(uniform_data)
print(f"PITOS p-value: {p_value}")
```

## Running Validation and Tests

To ensure that the Julia, R, and Python implementations produce consistent results, you can use the provided validation script and test suites.

### Cross-Language Validation

From the root of the repository, run the `validate_packages.jl` script. This will execute the Julia, R, and Python implementations on a variety of test cases and compare their outputs.

```sh
julia validate_packages.jl
```

### Package-Specific Tests

-   **Julia**:
    To run the Julia package's test suite, navigate to the `julia/PITOS` directory and run:
    ```sh
    julia --project -e 'import Pkg; Pkg.test()'
    ```

-   **R**:
    To run the R package's test suite, start an R session and run:
    ```R
    devtools::test("r/PITOS")
    ```

-   **Python**:
    To run the Python package's test suite, first install the test dependencies, then run `pytest` from the root of the repository:
    ```sh
    pip install pytest
    pytest python/PITOS
    ```
