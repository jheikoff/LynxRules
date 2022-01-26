"Maintains match counts for existential patterns."
struct Counts
    table::IdDict{Match, Int64}
    Counts() = new(IdDict{Match, Int64}())
end

getindex(counts::Counts, match::Match) = get(counts.table, match, 0)

function increment!(counts::Counts, match::Match)
    counts.table[match] = get(counts.table, match, 0) + 1
end

function decrement!(counts::Counts, match::Match)
    counts.table[match] = get(counts.table, match, 0) - 1
end

"A boxed Int64 value to keep a count in an immutable struct."
mutable struct Count
    int::Int64
end
