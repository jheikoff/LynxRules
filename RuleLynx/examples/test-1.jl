using RuleLynx

greet()

# Rulesets and rules
printstyled("Test rulesets and rules\n", color=:blue)
rs = Ruleset(name = :test)

printstyled("Defining rule test_1\n", color=:light_blue)
@rule (test_1, rs) begin
    parents(penelope, _mother, _father)
  =>
    @show _mother
    @show _father
end

printstyled("Defining rule test_2\n", color=:light_blue)
@rule (test_2, rs) begin
    _request = request(_name)
    parents(_name, _mother, _father)
  =>
    @show _name
    @show _mother
    @show _father
end

printstyled("Defining rule test_3\n", color=:light_blue)
@rule (test_3, rs) begin
    test(_x, _y, _z, a, 1, $(1+2), "test")
  =>
    @show (_x, _y, _z)
end

printstyled("Defining rule test_4\n", color=:light_blue)
@rule (test_4, rs) begin
    _request = request(_name)
  =>
    @show _request
end

printstyled("Defining rule test_5\n", color=:light_blue)
@rule (test_5, rs) begin
  =>
    println("Rule with no preconditions")
end

printstyled("Defining rule test_6\n", color=:light_blue)
@rule (test_6, rs) begin
    parents(_name, _mother:(_mother === :loree), _)
  =>
    println("$_name is a child of $_mother")
end

printstyled("Inference\n", color=:blue)
@inference begin
    current_inference_trace!(true)
    current_inference_strategy!(:breadth)
    activate(rs)
    graph_network("test-1.dot")
    RuleLynx.@assert(parents(penelope, jessica, jeremy))
    RuleLynx.@assert(parents(jessica, mary_elizabeth, homer))
    RuleLynx.@assert(parents(jeremy, jenny, steven))
    RuleLynx.@assert(parents(steven, loree, john))
    RuleLynx.@assert(parents(loree, _, jason))
    RuleLynx.@assert(parents(homer, stephanie, _))
    RuleLynx.@assert(request(penelope))
    printstyled("After asserts\n", color=:light_blue)
    wm()
    printstyled("Start inference\n", color=:light_blue)
    start_inference()
    printstyled("Nested inference\n", color=:light_blue)
    @inference begin
        RuleLynx.@assert(request(jeremy))
        wm()
    end
    printstyled("Retracts\n", color=:light_blue)
    retract(RuleLynx.@assert(parents(steven, loree, john)))
    retract(RuleLynx.@assert(request(penelope)))
    printstyled("After retracts\n", color=:light_blue)
    wm()
    printstyled("Fact interpolation\n", color=:light_blue)
    _steven = :steven123
    RuleLynx.@assert(parents(jeremy, jenny, _steven))
    _john = :john123
    RuleLynx.@assert(parents(steven, loree, $_john))
    i = 10
    RuleLynx.@assert(test(penelope, _steven, $_john, 1, i, :i, $i, i+10, "this is a test"))
    wm()
end

nothing