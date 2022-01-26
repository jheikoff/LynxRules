abstract type AbstractNode end

struct MatchNode <: AbstractNode
    successors::Vector{AbstractNode}
    matches::Vector{Match}
    precondition::Precondition
    match_functions::Vector{Function}
    n::Count
end

struct JoinNode <: AbstractNode
    successors::Vector{AbstractNode}
    matches::Vector{Match}
    left::Union{JoinNode, Nothing}
    right::Union{MatchNode, Nothing}
    existential::Union{Symbol, Nothing}
    join_functions::Vector{Function}
    counts::Counts
end

struct RuleNode <: AbstractNode
    successors::Vector{AbstractNode}
    matches::Vector{Match}
    join_node::JoinNode
    rule::Rule
end

function link_nodes(predecessor::AbstractNode, successor::AbstractNode)
    push!(predecessor.successors, successor)
end

function add_match(match::Match, node::AbstractNode)
    push!(node.matches, match)
end
