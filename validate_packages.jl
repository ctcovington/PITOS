# validate_packages.jl

using DelimitedFiles
using Printf
using Random
using Distributions

# --- configuration ---
const JULIA_MODULE_PATH = joinpath("julia", "PITOS", "src", "PITOS.jl")

# include and use the Julia implementation
include(JULIA_MODULE_PATH)
using .PITOS

# --- runner functions for SINGLE datasets ---

function run_external_script(command, data_filepath)
    output = read(`$(command) $(data_filepath)`, String)
    return parse(Float64, strip(output))
end

function run_all_implementations(data::Vector{Float64})
    pval_jl = pitos(data)
    (temp_filepath, io) = mktemp()
    writedlm(io, data, ' ')
    close(io)
    try
        pval_r = run_external_script(`Rscript run_pitos.R`, temp_filepath)
        pval_py = run_external_script(`venv/bin/python3 run_pitos.py`, temp_filepath)
        return (julia=pval_jl, r=pval_r, python=pval_py)
    finally
        rm(temp_filepath)
    end
end

# --- runner functions for BATCH datasets (for power analysis) ---

function run_external_script_batch(command, data_filepath)
    output = read(`$(command) $(data_filepath)`, String)
    # Read all lines of output and parse them into a vector of p-values
    return [parse(Float64, s) for s in split(strip(output), "\n")]
end

function run_all_implementations_batch(data::Matrix{Float64})
    # Run Julia version (apply pitos to each column)
    pvals_jl = mapslices(pitos, data, dims=1)[:]

    # Create temp files for R and Python
    (temp_filepath_r, io_r) = mktemp()
    (temp_filepath_py, io_py) = mktemp()

    # R expects simulations in columns (n_samples x n_sims)
    writedlm(io_r, data, ' ')
    close(io_r)

    # Python expects simulations in rows (n_sims x n_samples)
    writedlm(io_py, data', ' ') # Note the transpose
    close(io_py)

    try
        pvals_r = run_external_script_batch(`Rscript run_pitos.R`, temp_filepath_r)
        pvals_py = run_external_script_batch(`venv/bin/python3 run_pitos.py`, temp_filepath_py)
        return (julia=pvals_jl, r=pvals_r, python=pvals_py)
    finally
        rm(temp_filepath_r)
        rm(temp_filepath_py)
    end
end


"""
Runs a single test case for various distributions and prints the resulting p-values.
"""
function run_individual_tests(sample_size::Int)
    println("\n" * "="^70)
    @printf "🔬 Starting Individual Test Cases (Sample Size: %d)\n" sample_size
    println("="^70)
    distributions = Dict(
        "Uniform" => Uniform(0, 1), "Beta(1.1, 1)" => Beta(1.1, 1),
        "Beta(0.5, 0.5)" => Beta(0.5, 0.5), "Outliers" => MixtureModel([Uniform(0, 0.001), Uniform(0, 1)], [0.01, 0.99]),
        "Bump (Middle)" => MixtureModel([Uniform(0.45, 0.55), Uniform(0, 1)], [0.1, 0.9])
    )
    println("-"^70)
    @printf "%-25s | %-12s | %-12s | %-12s\n" "Distribution" "Julia p-val" "R p-val" "Python p-val"
    println("-"^70)
    for (name, dist) in distributions
        data = rand(dist, sample_size)
        try
            results = run_all_implementations(data) # Uses the single-run function
            @printf "%-25s | %-12.4f | %-12.4f | %-12.4f\n" name results.julia results.r results.python
        catch e
            @printf "%-25s | %-12s\n" name "ERROR"
            println(e)
        end
    end
    println("-"^70)
end


"""
Performs a power analysis by simulating data from various distributions.
"""
function run_power_simulations(n_sims::Int, sample_size::Int, alpha::Float64)
    println("\n" * "="^70)
    @printf "🚀 Starting Power Analysis Simulations\n"
    @printf "Significance Level (α): %.2f | Simulations: %d | Sample Size: %d\n" alpha n_sims sample_size
    println("="^70)
    distributions = Dict(
        "Uniform (Type I Error)" => Uniform(0, 1), "Beta(2, 1) (Skewed)" => Beta(2, 1),
        "Beta(0.5, 0.5) (U-Shaped)" => Beta(0.5, 0.5), "Normal (Truncated)" => Truncated(Normal(0.5, 0.15), 0, 1),
        "Bimodal Mixture" => MixtureModel([Uniform(0.1, 0.2), Uniform(0.8, 0.9)], [0.5, 0.5]),
        "Outliers" => MixtureModel([Uniform(0, 0.001), Uniform(0, 1)], [0.01, 0.99])
    )
    println("-"^70)
    @printf "%-25s | %-12s | %-12s | %-12s\n" "Distribution" "Julia Power" "R Power" "Python Power"
    println("-"^70)

    for (name, dist) in distributions
        print("Running: $name...")

        # --- BATCH DATA GENERATION ---
        # Generate all n_sims datasets at once into a matrix
        # Each column is one simulation
        all_data = hcat([rand(dist, sample_size) for _ in 1:n_sims]...)

        try
            # --- BATCH EXECUTION ---
            # Call the batch runner once to get all p-values
            all_pvals = run_all_implementations_batch(all_data)

            # --- CALCULATE POWER ---
            # Count how many p-values are below alpha for each implementation
            power_jl = count(p -> p < alpha, all_pvals.julia) / n_sims
            power_r = count(p -> p < alpha, all_pvals.r) / n_sims
            power_py = count(p -> p < alpha, all_pvals.python) / n_sims

            print(" Done.\n")
            @printf "%-25s | %-12.3f | %-12.3f | %-12.3f\n" name power_jl power_r power_py

        catch e
            print(" ERROR.\n")
            println(e)
        end
    end
    println("-"^70)
end


function main()
    println("Running cross-language validation for PITOS implementations...")
    Random.seed!(0)
    n_sims = 1000
    n_individual = 200
    n_power = 20
    alpha = 0.05
    run_individual_tests(n_individual)
    run_power_simulations(n_sims, n_power, alpha)
    println("\nValidation complete.")
end

main()