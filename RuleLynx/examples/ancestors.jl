using RuleLynx

greet()

ruleset = Ruleset(name = :ancestor_ruleset)

@rule (initialize, ruleset) begin
  =>
    println("Please enter the first name of a")
    println("person whose ancestors you would")
    println("like to find:")
    RuleLynx.@assert request($(Symbol(readline())))
    # RuleLynx.@assert request(penelope)
end

@rule (print_ancestors, ruleset) begin
    _request = request(_name)
    parents(_name, _mother, _father)
  =>
    if !isnothing(_mother)
        println("$_mother is an ancestor via $_name")
        RuleLynx.@assert request(_mother)
    end
    if !isnothing(_father)
        println("$_father is an ancestor via $_name")
        RuleLynx.@assert request(_father)
    end
    retract(_request)
end

@rule (remove_request, ruleset) begin
    pragma(priority = -100)
    _request = request(_)
  =>
    retract(_request)
end

function main()
    @inference begin
        current_inference_trace!(true) # pragma(trace(true))
        current_inference_strategy!(:breadth) # pragma(strategy(breadth))
        activate(ruleset)
        graph_network("ancestors.dot")
        RuleLynx.@assert parents(:penelope, :jessica, :jeremy)
        RuleLynx.@assert parents(:jessica, :mary_elizabeth, :homer)
        RuleLynx.@assert parents(:jeremy, :jenny, :steven)
        RuleLynx.@assert parents(:steven, :loree, :john)
        RuleLynx.@assert parents(:loree, _, :jason)
        RuleLynx.@assert parents(:homer, :stephanie, _)
        printstyled("Find ancestors using $(current_inference_strategy()) strategy.\n", color=:blue)
        start_inference()
        # wm()
    end
end

main()