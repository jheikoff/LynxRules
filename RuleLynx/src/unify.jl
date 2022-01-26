# Unify
# The unification algorithm is the heart of the inference engine. It matches
# a pattern against a fact and returns a list of unifying bindings or false if
# none exist.

"""Matches the pattern to the fact under the given bindings and returns a new 
extended set of binding if there a match and false otherwise."""
function unify(pattern::Pattern, fact::Fact, bindings::Base.ImmutableDict{Symbol, Any})
    if pattern.predicate !== fact.predicate ||
       length(pattern.arguments) > length(fact.arguments)
        return nothing
    end
    for (pitem, fitem) in zip(pattern.arguments, fact.arguments)
        isa(pitem, Bool) && isa(fitem, Bool) && pitem === fitem && continue
        isa(pitem, Number) && isa(fitem, Number) && pitem == fitem && continue
        isa(pitem, String) && isa(fitem, String) && pitem == fitem && continue
        iswildcard(pitem) && continue
        isdunderwildcard(pitem) && break
        if isvariable(pitem)
            if haskey(bindings, pitem)
                typeof(bindings[pitem]) === typeof(fitem) && bindings[pitem] == fitem && continue
                return nothing
            else
                # I'm not sure why Bindings(...) doesn't work here, but neither
                # does Base.ImmutableDict{Symbol, Any}(...).
                bindings = Base.ImmutableDict(bindings, pitem => fitem)
                continue
            end
        end
        isa(pitem, Symbol) && isa(fitem, Symbol) && pitem === fitem && continue
        return nothing
    end
    return bindings
end