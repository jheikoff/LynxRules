# Bindings
# Bindings are stored as immutable dictionaries, which are implemented as
# immutable linked lists.
#
# An empty set of bindings is created using Bindings(). To extend the bindings
# use Base.ImmutableDict(<bindings>, <key> => <value>), where <key> is the
# variable symbol. Note that - as far as I can tell - this is undocumented
# behavior of the Base.ImmutableDict type.
#
# Use keys(<bindings>) to return the variables in <bindings> and use
# values(<bindings>) to return the values in <bindings>.

Bindings = Base.ImmutableDict{Symbol, Any}

null_bindings = Base.ImmutableDict{Symbol, Any}()

struct Match
    assertions::Vector{Assertion}
    bindings::Bindings
end

function Base.show(io::IO, match::Match)
    binding_pairs = ["$(binding.first)=>$(binding.second)" for binding in match.bindings]
    print(io, "([$(join(match.assertions, ", "))], {$(join(binding_pairs, ", "))})")
end

null_match = Match(Assertion[], null_bindings)
