using RuleLynx

ruleset = Ruleset(:ancestor_ruleset)

@rule (initialize, ruleset) begin
  =>
    println("Please enter the first name of a")
    println("person whose ancestors you would")
    println("like to find:")
    @assert request($(Symbol(readline())))
end

@rule (print_ancestors, ruleset) begin
    _request = request(_name)
    parents(_name, _mother, _father)
  =>
    if !isnothing(_mother)
        println("$_mother is an ancestor via $_name")
        @assert request($_mother)
    end
    if !isnothing(_father)
        println("$_father is an ancestor via $_name")
        @assert request($_father)
    end
    retract(_request)
end

@rule (remove_request, ruleset) begin
    priority(-100)
    _request <- request(_)
  =>
    retract(_request)
end

function main()
    @inference begin
        activate(ruleset)
        current_inference_trace!(false)
        @assert parents(:penelope, :jessica, :jeremy)
        @assert parents(:jessica, :mary_elizabeth, :homer)
        @assert parents(:jeremy, :jenny, :steven)
        @assert parents(:steven, :loree, :john)
        @assert parents(:loree, nothing, :jason)
        @assert parents(:homer, :stephanie, nothing)
        start_inference()
    end
end

main()