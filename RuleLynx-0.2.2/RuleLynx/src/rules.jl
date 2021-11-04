struct Clause
    variable::Union{Symbol, Nothing}
    pattern::Pattern
end

struct Rule
    name::Symbol
    preconditions::Vector{Clause}
    action::Function
end

applyRule(rule::Rule, args::Vector) = rule.action(args...)

mutable struct Ruleset
    name::Symbol
    rules::Vector{Rule}
    Ruleset(name::Symbol) = new(name, Vector{Rule}[])
end

function addRule!(ruleset::Ruleset,
                 name::Symbol,
                 preconditions::Vector{Clause},
                 action::Function)
    rule = Rule(name, preconditions, action)
    push!(ruleset.rules, rule)
end

function precondition_variables(preconditions)
    variables = Symbol[]
    for clause in preconditions
        if !isnothing(clause.variable)
            push!(variables, clause.variable)
        end
        for arg in clause.pattern.arguments
            if isvariable(arg) && arg ∉ variables
                push!(variables, arg)
            end
        end
    end
    variables
end

macro rule(spec, clauses)
    name = QuoteNode(spec.args[1])
    # dump(clauses)
    ndx = findfirst(node -> node === Symbol("=>"), clauses.args)
    # extract patterns
    preconditions = Clause[]
    for clause in clauses.args[1:ndx - 1]
        if typeof(clause) == Expr
            if clause.head === :call
                push!(preconditions, Clause(nothing, Pattern(clause.args[1], Tuple(clause.args[2:end]))))
            elseif clause.head === Symbol("=")
                push!(preconditions, Clause(clause.args[1], Pattern(clause.args[2].args[1], Tuple(clause.args[2].args[2:end]))))
            else
                error("Unknown precondition clause $clause")
            end
        end
    end
    @show precondition_variables(preconditions)
    body = clauses.args[ndx + 1:end]
    # @show body
    quote
        addRule!($(esc(spec.args[2])),
                 $name,
                 $preconditions,
                 () -> nothing)
    end
end