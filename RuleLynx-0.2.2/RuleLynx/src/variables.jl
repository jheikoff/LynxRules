# Wildcards and Variable Symbols
# The wildcard symbol is :_ and variable symbols are symbols that begin with an
# underscore followed by an identifier, for example: :_x and :_parent.

"Returns true when its argument is the wildcard symbol."
iswildcard(::Any) = false
iswildcard(x::Symbol) = x === :_

"Returns true when its argument is a variable symbol."
isvariable(::Any) = false
isvariable(x::Symbol) = !iswildcard(x) && string(x)[1] === '_'
