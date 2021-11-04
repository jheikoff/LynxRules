# RuleLynx.jl
# Licensed under the MIT License. See LICENSE.md file in the project root for
# full license information.

__precompile__()

module RuleLynx

import Base.show
using DataStructures

# variables.jl
export iswildcard, isvariable

# factoid.jl
export Fact, isfact
export Pattern, ispattern

# bindings.jl
export Bindings

# unify.jl
export unify

# rules.jl
export Rule, applyRule
export Ruleset, addRule!, @rule

# assertions.jl
export Assertion

# inference.jl
export current_inference!, current_working_memory, current_assertion_index
export @inference

# control.jl
export assert, @assert
export retract
export wm

# RuleLynx.jl (this file)
export greet

"Print the RuleLynx greeting."
function greet()
    printstyled(raw"""
                          ______      _      _                        _ _  
          `\.      ,/'    | ___ \    | |    | |                      (_) | 
           |\\____//|     | |_/ /   _| | ___| |    _   _ _ __ __  __  _| | 
           )/_ `' _\(     |    / | | | |/ _ \ |   | | | | '_ \\ \/ / | | | 
          ,'/-`__'-\`\    | |\ \ |_| | |  __/ |___| |_| | | | |>  < _| | | 
          /. (_><_) ,\    \_| \_\__,_|_|\___\_____/\__, |_| |_/_/\_(_) |_| 
          '`)/`--'\(`'                              __/ |           _/ |   
            '      '                               |___/           |__/    

        A Hybrid Rule-Based Inference Engine and Language in Julia
        RuleLynx.jl Version 0.2.1 2021-10-26
        University of Colorado in Denver
        Dr. Doug Williams, Adam Durkes, Joe Heikoff
        """, color=:yellow)
end

# Abstract data type declarations

# Include the inference framework
include("variables.jl")
include("factoids.jl")
include("bindings.jl")
include("unify.jl")
include("rules.jl")
include("assertions.jl")
include("inference.jl")
include("control.jl")

end # module