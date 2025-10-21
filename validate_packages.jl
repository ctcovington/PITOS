# validate_all.jl

using DelimitedFiles
using Printf
using Random
using Distributions

# --- Configuration ---
const JULIA_MODULE_PATH = joinpath("julia", "PITOS", "src", "PITOS.jl")

# Include and use the Julia implementation
include(JULIA_MODULE_PATH)
using .PITOS

# --- Runner Functions ---

function run_external_script(command, data_filepath)
    full_command = `$(command) $data_filepath`
    output = read(full_command, String)
    return parse(Float64, strip(output))
end

# --- Main Validation Logic ---

function run_all_implementations(data::Vector{Float64})
    # 1. Run Julia version directly
    pval_jl = pitos(data)

    # Create a temporary file to pass data to external scripts
    (temp_filepath, io) = mktemp()
    writedlm(io, data, ' ')
    close(io)

    try
        # 2. Run R version
        pval_r = run_external_script(`Rscript run_pitos.R`, temp_filepath)

        # 3. Run Python version
        pval_py = run_external_script(`venv/bin/python3 run_pitos.py`, temp_filepath)

        return (julia=pval_jl, r=pval_r, python=pval_py)
    finally
        rm(temp_filepath) # Clean up
    end
end

function main()
    println("Running cross-language validation for PITOS implementations...")

    Random.seed!(0)
    test_cases = Dict(
        "Uniform (n=50)"       => () -> rand(50),
        "Beta (n=100)"         => () -> rand(Distributions.Beta(1.2, 1.2), 100),
        "Small n (n=10)"       => () -> rand(10),
        "Large n (n=500)"      => () -> rand(500),
        "With Duplicates"      => () -> rand(1:20, 100) ./ 21.0,
        "U-shaped Dist (Beta)" => () -> rand(Distributions.Beta(0.5, 0.5), 150),
        "Asymmetric Dist"      => () -> rand(Distributions.Beta(1, 2), 200)
    )

    all_consistent = true

    println("-"^70)
    @printf "%-25s | %-18s | %-18s | %-18s\n" "Test Case" "Julia" "R" "Python"
    println("-"^70)

    for (name, data_generator) in test_cases
        data = data_generator()
        try
            results = run_all_implementations(data)
            p_jl, p_r, p_py = results.julia, results.r, results.python

            is_consistent = isapprox(p_jl, p_r, atol=1e-4) && isapprox(p_jl, p_py, atol=1e-4)
            if !is_consistent
                all_consistent = false
            end

            status = is_consistent ? "✅" : "❌"
            @printf "%-25s | %-18.12f | %-18.12f | %-18.12f %s\n" name p_jl p_r p_py status

        catch e
            all_consistent = false
            @printf "%-25s | %-18s | %-18s | %-18s %s\n" name "ERROR" "ERROR" "ERROR" "❌"
            println("  -> $e")
        end
    end

    println("-"^70)
    if all_consistent
        println("\n🎉 Success! All implementations are consistent.")
    else
        println("\n🚨 Failure! Some implementations produced different results.")
    end
end

main()