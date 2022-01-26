#                 ______      _      _                        _ _  
# `\.      ,/'    | ___ \    | |    | |                      (_) | 
#  |\\____//|     | |_/ /   _| | ___| |    _   _ _ __ __  __  _| | 
#  )/_ `' _\(     |    / | | | |/ _ \ |   | | | | '_ \\ \/ / | | | 
# ,'/-`__'-\`\    | |\ \ |_| | |  __/ |___| |_| | | | |>  < _| | | 
# /. (_><_) ,\    \_| \_\__,_|_|\___\_____/\__, |_| |_/_/\_(_) |_| 
# '`)/`--'\(`'                              __/ |           _/ |   
#   '      '                               |___/           |__/    
# 
# A Hybrid Rule-Based Inference Engine and Language in Julia
#
# towers.jl
#
# Towers of Hanoi from Artificial Intelligence: Tools, Techniques,
# and Applications, Tim O'Shea and Marc Eisenstadt, Harper & Rowe,
# 1984, pp.45

using RuleLynx

greet()

# The rules of the game are: (1) move one ring at a time and (2)
# never place a larger ring on top of a smaller ring.  The object
# is to transfer the entire pile of rings from its starting
# peg to either of the other pegs - the target peg.

towers_rules = Ruleset(name = :towers_rules)

# If the target peg hold all the rings 1 to n, stop because according
# to game rule (2) they must be in their original order and so the
# problem is solved.
@rule (rule_1, towers_rules) begin
    all(ring(_, right))
    =>
    println("Problem solved")
	succeed()
end

# If there is no current goal - that is, if a ring has just been
# successfully moved, or if no rings have yet to be moved - generate
# a goal.  In this case the goal is to be that of moving to the 
# target peg the largest ring that is not yet on the target peg.
@rule (rule_2, towers_rules) begin
    no(move(__))
	ring(_size, _peg:(_peg !== :right))
	no(ring(_size₁:(_size₁ > _size), _peg₁:(_peg₁ !== :right)))
    =>
    RuleLynx.@assert(move(_size, _peg, right))
end

# If there is a current goal, it can be achieved at once of there is
# no small rings on top of the ring to be moved (i.e. if the latter
# is at the top of its pile), and there are no small rings on the
# peg to which it is to be moved (i.e. the ring to be moved is 
# smaller that the top ring on the peg we intend to move it to).  If
# this is the case, carry out the move and then delete the current
# goal so that rule 2 will apply next time.
@rule (rule_3, towers_rules) begin
    _move = move(_size, _from, _to)
	_ring = ring(_size, _from)
	no(ring(_size₁:(_size₁ < _size), _from))
  	no(ring(_size₂:(_size₂ < _size), _to))
    =>
    println("Move ring $_size from $_from to $_to")
	@replace(_ring, ring(_size, _to))
	retract(_move)
end

# If there is a current goal but its disc cannot be moved as in rule
# 3, set up a new goal: that of moving the largest of the obstructing
# rings to the peg that is neither of those specified in the current
# goal (i.e. well out of the way of the current goal).  Delete the
# current goal, so that rule 2 will apply to the new goal next time.
@rule (rule_4, towers_rules) begin
    _move = move(_size, _from, _to)
    peg(_other:(_other !== _from && _other !== _to))
	ring(_size₁:(_size₁ < _size), _peg₁:(_peg₁ !== _other))
	no(ring(_size₂:(_size₁ < _size₂ < _size), _peg₂:(_peg₂ !== _other)))
    =>
    @replace(_move, move(_size₁, _peg₁, _other))
end

function main()
    @inference begin
        current_inference_trace!(true)
        current_inference_strategy!(:breadth)
        activate(towers_rules)
        graph_network("towers.dot")
        # Create the pegs
        RuleLynx.@assert(peg(left))
        RuleLynx.@assert(peg(middle))
        RuleLynx.@assert(peg(right))
        # Create the rings
        println("How many disks?")
        n = parse(Int, readline())
        for i in 1:n
            RuleLynx.@assert(ring($i, left))
        end
        start_inference()
    end
end

main()
