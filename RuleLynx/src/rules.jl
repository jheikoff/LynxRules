# We may want to move this

@enum ConstraintClassification begin
    NO_VARIABLES = 1
    LOCAL_VARIABLES = 2
    GLOBAL_VARIABLES = 3
end

function classify_constraint(constraint::Expr, variables::Vector{Symbol})
    classification = NO_VARIABLES
    for arg in constraint.args
        if isvariable(arg)
            classification = max(classification,
                                 arg ∈ variables ? LOCAL_VARIABLES
                                                 : GLOBAL_VARIABLES)
        elseif isa(arg, Expr)
            classification = max(classification,
                                 classify_constraint(arg, variables))
        end
    end
    return classification
end

"""
    struct Clause

A clause is the parsed information from a rule precondition.

# Fields
- `variable::Union{Symbol, Nothing}`: assertion variable or nothing
- `existential::Union{Symbol, Nothing}`: existential symbol or nothing
- `pattern::Pattern`: full pattern
- `match_pattern::Pattern`: match pattern for unification
- `match_variables::Vector{Symbol}`: variables in match pattern
- `match_constraints::Vector{Expr}`: match constraints
- `match_functions::Vector{Expr}`: functions implementing match constraints
- `join_variables::Vector{Symbol}`: cumulative variables
- `join_constraints::Vector{Expr}`: join constraints
- `join_functions::Vector{Expr}`: functions implementing join constraints

"""
struct Clause
    variable::Union{Symbol, Nothing}
    existential::Union{Symbol, Nothing}
    pattern::Pattern
    match_pattern::Pattern
    match_variables::Vector{Symbol}
    match_constraints::Vector{Expr}
    match_functions::Vector{Expr}
    join_variables::Vector{Symbol}
    join_constraints::Vector{Expr}
    join_functions::Vector{Expr}
end
"""
    struct Precondition

A precondition is a compiled rule precondition.
"""
struct Precondition
    clause::Clause
    variable::Union{Symbol, Nothing}
    existential::Union{Symbol, Nothing}
    match_pattern::Pattern
    match_functions::Vector{Function}
    join_functions::Vector{Function}
end

"""
    struct Rule
"""
struct Rule
    name::Symbol
    pragmas::IdDict{Symbol, Any}
    preconditions::Vector{Precondition}
    action::Function
end

apply(rule::Rule, args::Vector) = rule.action(args...)

struct RuleInstance
    rule::Rule
    match::Match
end

function Base.show(io::IO, rule_instance::RuleInstance)
    priority = get(rule_instance.rule.pragmas, :priority, 0)
    print(io, "$(rule_instance.rule.name)($priority): $(rule_instance.match)")
end

Base.@kwdef struct Ruleset
    name::Symbol
    rules::Vector{Rule} = Vector{Rule}[]
    # Ruleset(name::Symbol) = new(name, Vector{Rule}[])
end

function addRule!(ruleset::Ruleset,
                 name::Symbol,
                 pragmas::IdDict{Symbol, Any},
                 preconditions::Vector{Precondition},
                 action::Function)
    rule = Rule(name, pragmas, preconditions, action)
    push!(ruleset.rules, rule)
    return nothing
end

macro rule(spec, body)
    # Spec is (<rule name>, <ruleset>)
    name = QuoteNode(spec.args[1]) # quote the rule name
    ruleset = spec.args[2] # we'll evaluate the ruleset
    # Find the => symbol separating the precondition and actions
    ndx = findfirst(node -> node === :(=>), body.args)
    isnothing(ndx) && throw(ArgumentError("Missing => in rule body"))
    # Extract patterns
    pragmas = IdDict{Symbol, Any}() # cumulative pragmas
    clauses = Clause[] # cumulative pattern clauses
    join_variables = Symbol[] # cumulative pattern variables
    for clause in body.args[1:ndx - 1]
        # Ignore LineNumberNode instances in clauses
        isa(clause, LineNumberNode) && continue
        # Process clause
        variable::Union{Symbol, Nothing} = nothing
        existential::Union{Symbol, Nothing} = nothing
        pattern::Union{Pattern, Nothing} = nothing
        if isa(clause, Expr) &&
           clause.head === :call &&
           clause.args[1] === :pragma
            # pragma(<symbol>, <value>)
            if isa(clause.args[2], Expr) &&
               clause.args[2].head === :kw &&
               isa(clause.args[2].args[1], Symbol)
                pragmas[clause.args[2].args[1]] = clause.args[2].args[2]
                continue # pragmas have no pattern, etc.
            else
                throw(ArgumentError("Malformed pragma $clause"))
            end
        elseif isa(clause, Expr) &&
               clause.head === :call &&
               clause.args[1] in (:no, :all)
            # <existential>(<pattern>)
            existential = clause.args[1]
            pattern = Pattern(clause.args[2].args[1], Tuple(clause.args[2].args[2:end]))
        elseif isa(clause, Expr) &&
               clause.head === Symbol("=")
            # <variable> = <pattern>
            variable = clause.args[1]
            pattern = Pattern(clause.args[2].args[1], Tuple(clause.args[2].args[2:end]))
        elseif isa(clause, Expr)
            # <pattern>
            pattern = Pattern(clause.args[1], Tuple(clause.args[2:end]))
        else
            throw(ArgumentError("Unknown precondition clause $clause in rule body"))
        end
        # Process pattern
        match_predicate = pattern.predicate
        match_variables = Symbol[]
        match_arguments = Any[]
        constraints = Expr[]
        for arg in pattern.arguments
            if isvariable(arg)
                push!(match_variables, arg)
                push!(match_arguments, arg)
            elseif isa(arg, Expr) &&
                   arg.head === :call &&
                   arg.args[1] === :(:) &&
                   isvariable(arg.args[2])
                push!(match_variables, arg.args[2])
                push!(constraints, arg.args[3])
                push!(match_arguments, arg.args[2])
            else
                push!(match_arguments, arg)
            end
        end
        # Add assertion variable and new match variables to join variables
        match_pattern = Pattern(match_predicate, Tuple(match_arguments))
        if !isnothing(variable)
            push!(join_variables, variable)
        end
        for var in match_variables
            if var ∉ join_variables
                push!(join_variables, var)
            end
        end
        # Process constraints by their classification
        match_constraints = Expr[]
        match_functions = Expr[]
        join_constraints = Expr[]
        join_functions = Expr[]
        for constraint in constraints
            classification = classify_constraint(constraint, match_variables)
            if classification === NO_VARIABLES
                continue
            elseif classification === LOCAL_VARIABLES
                constraint_arguments = Expr(:tuple, match_variables...)
                constraint_body = Expr(:block, constraint)
                constraint_function = Expr(:->, constraint_arguments, constraint_body)
                push!(match_constraints, constraint)
                push!(match_functions, constraint_function)
            else
                constraint_arguments = Expr(:tuple, join_variables...)
                constraint_body = Expr(:block, constraint)
                constraint_function = Expr(:->, constraint_arguments, constraint_body)
                push!(join_constraints, constraint)
                push!(join_functions, constraint_function)
            end
        end
        # Add clause to list of precondition clauses
        push!(clauses,
              Clause(variable,
                     existential,
                     pattern,
                     match_pattern,
                     match_variables,
                     match_constraints,
                     match_functions,
                     join_variables,
                     join_constraints,
                     join_functions))
    end
    # Build action function
    # arguments = Expr(:tuple, precondition_variables(preconditions)...)
    arguments = Expr(:tuple, join_variables...)
    body = Expr(:block, body.args[ndx + 1:end]...)
    proc = Expr(:->, arguments, body)
    quote
        let preconditions = Precondition[]
        for clause in $clauses
            push!(preconditions,
                  Precondition(clause,
                               clause.variable,
                               clause.existential,
                               clause.match_pattern,
                               Function[eval(expr) for expr in clause.match_functions],
                               Function[eval(expr) for expr in clause.join_functions]))
        end
        addRule!($(esc(ruleset)),
                 $name,
                 $pragmas,
                 preconditions,
                 $(esc(proc)))
        end
    end
end