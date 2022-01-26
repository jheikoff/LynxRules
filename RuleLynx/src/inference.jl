# inference.jl
# Licensed under the MIT License. See LICENSE.md file in the project root for
# full license information.

"""
    Inference

An inference instance represents the state of an inference. Specifically, it
contains ...

# Fields

You should generally use the @inference macro to create a new inference.
"""
mutable struct Inference
	trace::Bool
	next_seq::Int64
	working_memory::SortedDict{Int64, Assertion}
	assertion_index::Dict{Fact, Assertion}
	match_index::Dict{Symbol, Vector{MatchNode}}
	initial_join::JoinNode
	rule_nodes::Vector{RuleNode}
	agenda::SortedDict{Int, Vector{RuleInstance}}
	rule::Union{Nothing, Rule}
	strategy::Symbol
    Inference() = new(false,
	                  1,
	                  SortedDict{Int64, Assertion}(),
					  Dict{Fact, Assertion}(),
					  Dict{Symbol, Vector{MatchNode}}(),
					  JoinNode(AbstractNode[], Match[], nothing, nothing, nothing, Function[], Counts()),
					  RuleNode[],
					  SortedDict{Int, Vector{RuleInstance}}(Base.Order.Reverse),
					  nothing,
					  :depth)
end

# The current inference is a global variable designating the currently active
# inference. Unfortunately, there is no way (currently) to associate a type
# with a global variable but we would like to have:
# current_inference::Union{Inference, Nothing} = nothing

"The current active inference"
current_inference = Inference() # Union{Inference, Nothing}

function current_inference!(inference::Union{Inference, Nothing})::Nothing
	global current_inference = inference
	return nothing
end

current_inference_trace()::Bool = current_inference.trace

current_inference_trace!(trace::Bool) = current_inference.trace = trace

macro inference_trace(str)
	quote
		current_inference.trace && println($(esc(str)))
	end
end

function current_inference_next_seq()::Int64
	next_seq = current_inference.next_seq
	current_inference.next_seq += 1
	return next_seq
end

current_inference_working_memory()::SortedDict{Int64, Assertion} = current_inference.working_memory

current_inference_assertion_index()::Dict{Fact, Assertion} = current_inference.assertion_index

current_inference_match_index()::Dict{Symbol, Vector{MatchNode}} = current_inference.match_index

current_inference_initial_join()::JoinNode = current_inference.initial_join

current_inference_rule_nodes()::Vector{RuleNode} = current_inference.rule_nodes

current_inference_agenda()::SortedDict{Int, Vector{RuleInstance}} = current_inference.agenda

current_inference_rule()::Rule = current_inference.rule
current_inference_rule!(rule::Rule) = current_inference.rule = rule

current_inference_strategy()::Symbol = current_inference.strategy
current_inference_strategy!(strategy::Symbol) = current_inference.strategy = strategy

# @inference macro

"""
    @inference begin
	    <body>
	end

Execute the body within a new inference environment. This is the easiest way
to ensure a new, clean inference environment.
"""
macro inference(body)
    quote
		begin
		    old_inference = current_inference
		    current_inference!(Inference())
		    try
		        $(esc(body))
		    catch e
		        showerror(stdout, e, catch_backtrace())
		    finally
		        current_inference!(old_inference)
			end
		end
	end
end

"""
    @inference <inference> begin
	    <body>
	end

Execute the body within the specified inference environment.
"""
macro inference(inference::Inference, body)
    quote
		begin
		    old_inference = current_inference
		    current_inference!(inference)
			try
		    	$(esc(body))
			catch e
		    	showerror(stdout, e, catch_backtrace())
			finally
		    	current_inference!(old_inference)
			end
		end
	end
end

" Print working memory."
function wm(inference::Inference = current_inference)
    println("Working Memory: $(length(inference.working_memory)) entries")
    for assertion in values(inference.working_memory)
        println("f-$(assertion.seq): $(assertion.fact)")
    end
end
