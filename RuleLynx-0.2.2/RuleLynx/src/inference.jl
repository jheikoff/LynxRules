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
    Inference() = new(false,
	                  1,
	                  SortedDict{Int64, Assertion}(),
					  Dict{Fact, Assertion}())
end

# The current inference is a global variable designating the currently active
# inference. Unfortunately, there is no way (currently) to associate a type
# with a global variable but we would like to have:
# current_inference::Union{Inference, Nothing} = nothing

"The current active inference"
current_inference = nothing # Union{Inference, Nothing}

function current_inference!(inference::Union{Inference, Nothing})
	global current_inference = inference
	return nothing
end

current_inference_trace() = current_inference.trace

current_inference_trace!(trace::Bool) = current_inference.trace = trace

function current_next_seq()
	next_seq = current_inference.next_seq
	current_inference.next_seq += 1
	return next_seq
end

current_working_memory() = current_inference.working_memory

current_assertion_index() = current_inference.assertion_index

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
