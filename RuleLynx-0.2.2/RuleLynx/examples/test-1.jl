using RuleLynx

greet()

# Facts
printstyled("Test facts\n", color=:blue)
x = Fact(:parents, (:penelope, :jessica, :jeremy))
@show x
@show isfact(x)
@show ispattern(x)

# Patterns
printstyled("Test patterns\n", color=:blue)
y = Pattern(:parents, (:penelope, :_mother, :_father))
@show y
@show isfact(y)
@show ispattern(y)

# unification
printstyled("Test unification\n", color=:blue)
@show unify(y, x, Bindings())

# Rulesets and rules
printstyled("Test rulesets and rules\n", color=:blue)
rs = Ruleset(:test)
@show rs

printstyled("Defining rule test_1\n", color=:light_blue)
@rule (test_1, rs) begin
    parents(penelope, _mother, _father)
  =>
    @show _mother
    @show _father
end

printstyled("Defining rule test_2\n", color=:light_blue)
@rule (test_2, rs) begin
    request(_name)
    parents(_name, _mother, _father)
  =>
    @show _name
    @show _mother
    @show _father
end

printstyled("Defining rule test_3\n", color=:light_blue)
@rule (test_3, rs) begin
    test(_x, _y, _z, a, 1, 1+2, "test")
  =>
    @show (_x, _y, _z)
end

printstyled("Defining rule test_4\n", color=:light_blue)
@rule (test_4, rs) begin
    _request = request(_name)
  =>
    @show _request
end

# dump(rs)

printstyled("Inference\n", color=:blue)
@inference begin
    RuleLynx.@assert(parents(penelope, jessica, jeremy))
    RuleLynx.@assert(parents(jessica, mary_elizabeth, homer))
    RuleLynx.@assert(parents(jeremy, jenny, steven))
    RuleLynx.@assert(parents(steven, loree, john))
    RuleLynx.@assert(parents(loree, _, jason))
    RuleLynx.@assert(parents(homer, stephanie, _))
    printstyled("After asserts\n", color=:light_blue)
    wm()
    printstyled("Nested inference\n", color=:light_blue)
    @inference begin
        RuleLynx.@assert(request(penelope))
        wm()
    end
    retract(RuleLynx.@assert(parents(steven, loree, john)))
    printstyled("After retract\n", color=:light_blue)
    wm()
    printstyled("Fact interpolation\n", color=:light_blue)
    _steven = :steven123
    RuleLynx.@assert(parents(jeremy, jenny, _steven))
    _john = :john123
    RuleLynx.@assert(parents(steven, loree, $_john))
    wm()
end

nothing