"A Factoid is a abstract type representing a fact-like object."
abstract type Factoid end

# Facts

struct Fact <: Factoid
    predicate::Symbol
    arguments::Tuple
end

function Base.show(io::IO, fact::Fact)
    print(io, "$(fact.predicate)($(join(fact.arguments, ", ")))")
end

"Returns true when its argument is a fact."
isfact(::Any) = false
isfact(x::Fact) = !iswildcard(x.predicate) && !isvariable(x.predicate) &&
                  all(item->(isa(item, Bool) ||
                             isa(item, Number) ||
                             isa(item, String) ||
                             (isa(item, Symbol) &&
                              !iswildcard(item) &&
                              !isvariable(item))),
                      x.arguments)

# Patterns

struct Pattern <: Factoid
    predicate::Symbol
    arguments::Tuple
end
                    
function Base.show(io::IO, pattern::Pattern)
    print(io, "$(pattern.predicate)($(join(pattern.arguments, ", ")))")
end

"Returns true when its argument is a pattern."
ispattern(::Any) = false
ispattern(x::Pattern) = !iswildcard(x.predicate) && !isvariable(x.predicate) &&
                        all(item->(isa(item, Bool) ||
                                   isa(item, Number) ||
                                   isa(item, String) ||
                                   isa(item, Symbol)),
                            x.arguments)

# Pragmas (TBD)

struct Pragma <: Factoid
    predicate::Symbol
    arguments::Tuple
end
                    
function Base.show(io::IO, pragma::Pragma)
    print(io, "$(pragma.predicate)($(join(pragma.arguments, ", ")))")
end

ispragma(::Any) = false