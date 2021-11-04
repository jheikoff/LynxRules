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