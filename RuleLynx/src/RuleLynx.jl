# RuleLynx.jl
# Licensed under the MIT License. See LICENSE.md file in the project root for
# full license information.

__precompile__()

module RuleLynx

import Base.show, Base.join
using DataStructures

# variables.jl
export iswildcard, isvariable

# factoid.jl
export Fact, isfact
export Pattern, ispattern

# assertions.jl
export Assertion

# bindings.jl
export Bindings, Match

#counts.jl

# unify.jl
export unify

# rules.jl
export Clause, Rule, RuleInstance, applyRule
export Ruleset, addRule!, @rule

# network.jl
export AbstractNode, MatchNode, JoinNode, RuleNode
export link_node, add_match

# inference.jl
export current_inference!
export current_inference_trace, current_inference_trace!, @inference_trace
export current_inference_working_memory, current_inference_assertion_index
export current_inference_match_index
export current_inference_initial_index
export current_inference_rule_nodes
export current_inference_strategy, current_inference_strategy!
export @inference
export wm

# control.jl
export assert, @assert, @replace
export retract
export activate
export start_inference
export graph_network

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
        RuleLynx.jl Version 0.4.1 2021-12-14
        University of Colorado in Denver
        Dr. Doug Williams, Adam Durkes, Joe Heikoff
        """, color=:yellow)
end

# Abstract data type declarations

# Include the inference framework
include("variables.jl")
include("factoids.jl")
include("assertions.jl")
include("bindings.jl")
include("counts.jl")
include("unify.jl")
include("rules.jl")
include("network.jl")
include("inference.jl")
include("control.jl")

end # module