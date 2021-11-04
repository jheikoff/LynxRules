"""
An assertion is a fact asserted into working memory.

There is a conflict for the verb 'assert', specifically with the @assert macro.
We can use a different verb/noun combination like 'affirm'/'affirmation'.
"""
struct Assertion
    seq::Int64
    fact::Fact
end