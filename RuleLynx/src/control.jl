# ------------------------------------------------------------------------------
#
# Assert, Retract, and replace
#
# ------------------------------------------------------------------------------

"""
    assert(assertion::Assertion)::Assertion

Add the assertion to the assertion indexes and match against match nodes.
"""
function assert(assertion::Assertion)::Assertion
    # Trace assertion
    @inference_trace(">>> f-$(assertion.seq): $(assertion.fact)")
    # Add assertion to assertion indexes
    current_inference.working_memory[assertion.seq] = assertion
    current_inference.assertion_index[assertion.fact] = assertion
    # Propagate assertion
    for match_node in get(current_inference_match_index(), assertion.fact.predicate, MatchNode[])
        match(match_node, assertion)
    end
    return assertion
end

"""
    assert(fact::Fact)::Assertion

Assert a `fact` into the current working memory. If the `fact` has already been
asserted, then just return the existing assertion. Otherwise, create a new
assertion, add it to the working memory (i.e., update the indexes in the current
inference), and propagate it to the rule network.

Usually, you will use the RuleLynx.@assert macro, which is more convenient.
"""
function assert(fact::Fact)::Assertion
    # If fact is already asserted, return the existing assertion
    if haskey(current_inference_assertion_index(), fact)
        @inference_trace("=== f-$(current_inference_assertion_index()[fact].seq) $fact")
        return current_inference_assertion_index()[fact]
    end
    # Create new assertion
    seq = current_inference_next_seq()
    assertion = Assertion(seq, fact)
    # Add assertion to indexes and propagate
    return assert(assertion)
end

"""
    assert(predicate::Symbol, arguments...)::Assertion

Assert the fact given by its predicate and arguments. This version is used by
the @assert macro for convenience.
"""
function assert(predicate::Symbol, arguments...)::Assertion
    assert(Fact(predicate, Tuple(arguments)))
end

"""
    @assert(clause)

Assert a fact in the current working memory. Arguments are not evaluated usless
preceded by a dollar sign "\$" - i.e., interpolated.
"""
macro assert(clause)
    args = []
    for arg in clause.args[2:end]
        if isa(arg, Symbol) # Symbols - including wildcards and variables
            if iswildcard(arg) # wildcard - insert nothing
                push!(args, nothing)
            elseif isvariable(arg) # variable - use its (escaped) value
                push!(args, esc(arg))
            else # otherwise quote it
                push!(args, QuoteNode(arg))
            end
        elseif isa(arg, Expr) && arg.head == :$ # interpolation
            push!(args, esc(arg.args[1]))
        else
            push!(args, esc(arg))
        end
    end
    quote
        assert($(QuoteNode(clause.args[1])), $(args...))
    end
end

function retract(assertion::Assertion)::Nothing
    # Do nothing if assertion isn't found in index.
    # To do: Is this the right thing to do?
    if !haskey(current_inference.assertion_index, assertion.fact)
        return nothing
    end
    # Trace retraction
    @inference_trace("<<< f-$(assertion.seq) $(assertion.fact)")
    # Remove assertion from the indexes
    delete!(current_inference.working_memory, assertion.seq)
    delete!(current_inference.assertion_index, assertion.fact)
    # Propagate retraction
    for match_node in get(current_inference_match_index(), assertion.fact.predicate, MatchNode[])
        unmatch(match_node, assertion)
    end
    return nothing
end

macro replace(assertion, clause)
    # dump(clause)
    nothing
end

# ------------------------------------------------------------------------------
#
# Rule Network
#
# ------------------------------------------------------------------------------

function get_match_node(precondition::Precondition)
    # Look for existing match Node
    for node in get!(current_inference_match_index(), precondition.match_pattern.predicate, MatchNode[])
        if node.precondition.clause.pattern == precondition.clause.pattern
            return node
        end
    end
    # Create and return new match node
    node = MatchNode(AbstractNode[],
                     Match[],
                     precondition,
                     precondition.match_functions,
                     Count(0))
    push!(current_inference_match_index()[precondition.match_pattern.predicate], node)
    return node
end

function get_join_node(left::JoinNode,
                       right::MatchNode,
                       existential::Union{Symbol, Nothing},
                       join_functions::Vector{Function})
    node = JoinNode(AbstractNode[],
                    Match[],
                    left,
                    right,
                    existential,
                    join_functions,
                    Counts())
    return node
end

# ------------------------------------------------------------------------------
#
# Ruleset Activation
#
# ------------------------------------------------------------------------------

"Activate a ruleset in the current environment."
function activate(ruleset::Ruleset)
    for rule in ruleset.rules
        activate_rule(rule, current_inference_initial_join())
    end
    return Nothing
end

function activate_rule(rule::Rule, initial_join_node::JoinNode)
    # Process precondition clauses
    previous_join_node = initial_join_node
    for precondition in rule.preconditions
        # Get/create match node
        match_node = get_match_node(precondition)
        # Get/create join node
        join_node = get_join_node(previous_join_node,
                                  match_node,
                                  precondition.existential,
                                  precondition.join_functions)
        # Link the nodes
        link_nodes(previous_join_node, join_node)
        link_nodes(match_node, join_node)
        previous_join_node = join_node
    end
    # Create rule node and link to previous join node
    rule_node = RuleNode(AbstractNode[], Match[], previous_join_node, rule)
    link_nodes(previous_join_node, rule_node)
    push!(current_inference_rule_nodes(), rule_node)
    return nothing
end

"""
    merge(bindings_1::Base.ImmutableDict, bindings_2::Base.ImmutableDict)

Merge two sets of bindings. We had to write this because the builtin merge for
immutable dictionaries for some reason returns a regular dictionary.

This is a brute force method but serves our purpose for now.
"""
function merge(bindings_1::Base.ImmutableDict, bindings_2::Base.ImmutableDict)
    merged = Base.ImmutableDict{Symbol, Any}()
    for (key, value) in bindings_1
        merged = Base.ImmutableDict(merged, key=>value)
    end
    for (key, value) in bindings_2
        if !haskey(merged, key)
            merged = Base.ImmutableDict(merged, key=>value)
        end
    end
    return merged
end

# ------------------------------------------------------------------------------
#
# Match Node Processing
#
# ------------------------------------------------------------------------------

"""
    match(match_node::MatchNode, assertion::Assertion)

Match the fact in the assertion against the pattern in the match node and
propagate any matches.
"""
function match(match_node::MatchNode, assertion::Assertion)
    # increment n
    match_node.n.int += 1
    # Create the initial binding including the assertion variable if there is
    # one.
    # Not sure why I have to use Base.ImmutableDict here instead of Bindings.
    initial_bindings = isnothing(match_node.precondition.variable) ? 
        null_bindings :
        Base.ImmutableDict(null_bindings, match_node.precondition.variable=>assertion)
    # Unify the match node pattern with the assertion fact.
    bindings = unify(match_node.precondition.match_pattern, assertion.fact, initial_bindings)
    if !isnothing(bindings)
        for func in match_node.precondition.match_functions
            args = [arg for arg in values(bindings)]
            # Need to figure out why we need the reverse here
            if !func(reverse(args)...)
                bindings = nothing
                break
            end
        end
    end
    # Create and propagate the new match.
    if !isnothing(bindings)
        new_match = Match([assertion], bindings)
        add_match(new_match, match_node)
        for successor in match_node.successors
            propagate_match(new_match, match_node, successor)
        end
    else
        for successor in match_node.successors
            propagate_nonmatch(match_node, successor)
        end
    end
end

function unmatch(match_node::MatchNode, assertion::Assertion)
    match_node.n.int -= 1
    matches = assertion_matches(match_node, assertion)
    if !isempty(matches)
        for successor in match_node.successors
            propagate_retract(successor, assertion)
        end
        setdiff!(match_node.matches, matches)
    end
end

# ------------------------------------------------------------------------------
#
# Match Propagation and Unpropagation
#
# ------------------------------------------------------------------------------

"""
    propagate_match(match::Match, ::MatchNode, join_node::JoinNode)

Propagate a match from a match node to a join node.
"""
function propagate_match(match::Match, match_node::MatchNode, join_node::JoinNode)
    for left_match in join_node.left.matches
        joined_match = join(left_match, match, join_node)
        if !isnothing(join_node.existential)
            if !isnothing(joined_match)
                increment!(join_node.counts, left-match)
            end
            count = get(join_node.counts, left_match, 0)
            if join_node.existential === :no
                if !isnothing(joined_match) && count == 1
                    unpropagate_match(left_match, match_node, join_node)
                end
            elseif join_node.existential === :all
                n = match_node.n.int
                if isnothing(joined_match) && count == n - 1
                    # count went from n to n - 1
                    unpropagate_match(left_match, match_node, join_node)
                end
            end
        else
            isnothing(joined_match) && continue
            add_match(joined_match, join_node)
            for successor in join_node.successors
                propagate_match(joined_match, join_node, successor)
            end
        end
    end
end

function propagate_nonmatch(match_node::MatchNode, join_node::JoinNode)
    for left_match in join_node.left.matches
        if !isnothing(join_node.existential)
            count = get(join_node.counts, left_match, 0)
            if join_node.existential === :all
                n = match_node.n.int
                if count == n - 1
                    unpropagate_match(left_match, match_node, join_node)
                end
            end
        end
    end
end

"""
    propagate_match(match::Match, ::JoinNode, join_node::JoinNode)

Propagate a match from a join node to a join node.
"""
function propagate_match(match::Match, ::JoinNode, join_node::JoinNode)
    for right_match in join_node.right.matches
        joined_match = join(right_match, match, join_node)
        isnothing(joined_match) && continue
        add_match(joined_match, join_node)
        for successor in join_node.successors
            propagate_match(joined_match, join_node, successor)
        end
    end
end

"""
    propagate_match(match::Match, ::JoinNode, rule_node::RuleNode)

Propagate a match from a join node to a rule node.
"""
function propagate_match(match::Match, ::JoinNode, rule_node::RuleNode)
    # println("Match $match propagated to rule node $(rule_node.rule.name)")
    add_match(match, rule_node)
    rule_instance = RuleInstance(rule_node.rule, match)
    agenda_add!(rule_instance)
end

function propagate_retract(join_node::JoinNode, assertion::Assertion)
    matches = assertion_matches(join_node, assertion)
    if !isempty(matches)
        for successor in join_node.successors
            propagate_retract(successor, assertion)
        end
        setdiff!(join_node.matches, matches)
    end
end

function propagate_retract(rule_node::RuleNode, assertion::Assertion)
    matches = assertion_matches(rule_node, assertion)
    for match in matches
        agenda_remove!(rule_node.rule, match)
    end
    setdiff!(rule_node.matches, matches)
end

function unpropagate_match(match::Match, ::MatchNode, join_node::JoinNode)
    nothing
end

function unpropagate_nonmatch(::MatchNode, join_node::JoinNode)
    nothing
end

function unpropagate_match(match::Match, ::JoinNode, join_node::JoinNode)
    nothing
end

function unpropagate_match(match::Match, ::JoinNode, rule_node::RuleNode)
    nothing
end

# ------------------------------------------------------------------------------
#
# Join
#
# ------------------------------------------------------------------------------

"""
    join(left_match::Match, right_match::Match, JoinNode)

Join two matches and return the joined merge if the join or nothing otherwise.
Currently, the join node argument is used, but may be in the future.
"""
function join(left_match::Match, right_match::Match, ::JoinNode)
    for (key, value) in right_match.bindings
        if haskey(left_match.bindings, key) && value != left_match.bindings[key]
            return nothing
        end
    end
    return Match([right_match.assertions; left_match.assertions],
                 merge(left_match.bindings, right_match.bindings))
end

# ------------------------------------------------------------------------------
#
# Rule Instances
#
# ------------------------------------------------------------------------------

function apply(rule_instance::RuleInstance)
    @inference_trace("<== $rule_instance")
    args = [arg for arg in values(rule_instance.match.bindings)]
    apply(rule_instance.rule, args)
end

"""
    assertion_matches(node::AbstractNode, assertion::Assertion)

Returns a list of the matches  in node for assertion.
"""
function assertion_matches(node::AbstractNode, assertion::Assertion)
    matches = Match[]
    for match in node.matches
        if assertion in match.assertions
            push!(matches, match)
        end
    end
    return matches
end

# Agenda Maintenance

function agenda_add!(rule_instance::RuleInstance)
    @inference_trace("==> $rule_instance")
    priority = get(rule_instance.rule.pragmas, :priority, 0)
    queue = get!(current_inference_agenda(), priority, RuleInstance[])
    strategy = current_inference_strategy()
    if strategy === :depth
        pushfirst!(queue, rule_instance)
    else
        push!(queue, rule_instance)
    end
end

function agenda_remove!(rule::Rule, match::Match)
    priority = get(rule.pragmas, :priority, 0)
    queue = get!(current_inference_agenda(), priority, RuleInstance[])
    ndx = findfirst(rule_instance -> rule_instance.rule === rule && rule_instance.match === match, queue)
    isnothing(ndx) && return nothing
    rule_instance = queue[ndx]
    @inference_trace("<== $rule_instance")
    deleteat!(queue, ndx)
end

# Start Inference

function start_inference(inference::Inference=current_inference)
    initial_join = inference.initial_join
    add_match(null_match, initial_join)
    for successor in initial_join.successors
        propagate_match(null_match, initial_join, successor)
    end
    cont = true
    while cont
        cont = false
        for queue in values(current_inference_agenda())
            isempty(queue) && continue
            rule_instance = popfirst!(queue)
            @inference_trace("---")
            apply(rule_instance)
            cont = true
            break
        end
    end
end

# Graph the rule network

function graph_network(filename)
    open(filename, "w") do f
        println(f, "digraph G {")
        for rule_node in current_inference_rule_nodes()
            println(f, "  node$(objectid(rule_node)) [shape=invhouse, label=\"$(rule_node.rule.name)\"];")
            graph_join_node(f, rule_node.join_node, rule_node)
        end
        println(f, "}")
    end
end

function graph_join_node(f, join_node::JoinNode, successor_node::AbstractNode)
    id = objectid(join_node)
    label = isnothing(join_node.existential) ? "join" : "join ($(join_node.existential))"
    if !isnothing(join_node.right)
        clause = join_node.right.precondition.clause
        strings = [repr(expr) for expr in clause.join_constraints]
        label *= "\\n$(join(strings, "\\n"))"
    end
    println(f, "  node$id [label=\"$label\"];")
    println(f, "  node$id -> node$(objectid(successor_node))")
    if !isnothing(join_node.left)
        graph_join_node(f, join_node.left, join_node)
    end
    if !isnothing(join_node.right)
        graph_match_node(f, join_node.right, join_node)
    end
end

function graph_match_node(f, match_node::MatchNode, successor_node::AbstractNode)
    precondition = match_node.precondition
    clause = precondition.clause
    id = objectid(match_node)
    label = repr(precondition.match_pattern)
    strings = [repr(expr) for expr in clause.match_constraints]
    label *= "\\n$(join(strings, "\\n"))"
    if isnothing(precondition.variable)
        println(f, "  node$id [shape=box, label=\"$label\"];")
    else
        println(f, "  node$id [shape=box, label=\"$(precondition.variable) = $label\"];")
    end
    println(f, "  node$id -> node$(objectid(successor_node))")
end