"""
    assert(fact::Fact)::Assertion

Assert a fact in the current working memory. Usually, you will use the
RuleLynx.@assert macro, which is more convenient.
"""
function assert(fact::Fact)::Assertion
    if haskey(current_inference.assertion_index, fact)
        return current_inference.assertion_index[fact]
    end
    next_seq = current_next_seq()
    assertion = Assertion(next_seq, fact)
    current_inference.working_memory[next_seq] = assertion
    current_inference.assertion_index[fact] = assertion
    return assertion
end

"""
    @assert(clause)

Assert a fact in the current working memory. Arguments are not evaluated usless
preceded by a dollar sign "\$" - i.e., interpolated.
"""
macro assert(clause)
    dump(clause)
    quote
        let args = []
            for arg in $(clause.args[2:end])
                if typeof(arg) === Symbol
                    if iswildcard(arg)
                        push!(args, nothing)
                    elseif isvariable(arg)
                        # dump(arg)
                        push!(args, :(eval(esc($(arg)))))
                    else
                        push!(args, arg)
                    end
                elseif typeof(arg) === Expr && arg.head == Symbol("\$")
                    dump(arg)
                    push!(args, :(eval(esc($(arg.args[1])))))
                else
                    error("unknown arg type $arg")
                end
            end
            assert(Fact($(QuoteNode(clause.args[1])), Tuple(args)))
        end
    end
end

function retract(assertion::Assertion)::Nothing
    delete!(current_inference.working_memory, assertion.seq)
    delete!(current_inference.assertion_index, assertion.fact)
    nothing
end

function wm()
    for assertion in values(current_inference.working_memory)
        println("$(assertion.seq): $(assertion.fact)")
    end
end

macro test_assert(clause)
    quote
        let args = []
            for arg in [x -> Quotenode(x) for x in (esc.($(clause.args[2:end]...)))]
                dump(QuoteNode()arg)
            end
        end
        nothing
    end
end