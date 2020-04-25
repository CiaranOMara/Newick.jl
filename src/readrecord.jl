const machine = (function ()

    re = Automa.RegExp

    cat = Automa.RegExp.cat
    rep = Automa.RegExp.rep
    rep1 = Automa.RegExp.rep1
    opt = Automa.RegExp.opt

    # newline = let
    #     lf = re"\n"
    #     lf.actions[:enter] = [:countline]
    #
    #     cat(opt('\r'), lf)
    # end

    space = re"[\t ]+"

    leaf = let
        name = re"\w+"
        name.actions[:enter] = [:mark]
        name.actions[:exit] = [:leafname]

        distance = re"\w+"
        distance.actions[:enter] = [:mark]
        distance.actions[:exit] = [:leafdistance]

        cat(opt(name), opt(cat(re":", distance)))
    end
    leaf.actions[:exit] = [:leaf]

    leaffinish = re","
    leaffinish.actions[:exit] = [:leaffinish]

    nodeliststart = re"\("
    nodeliststart.actions[:enter] = [:mark] # Note: marking to clear previous.
    nodeliststart.actions[:exit] = [:nodeliststart]

    nodelistfinish = let
        nodelistname = re"\w+"
        nodelistname.actions[:enter] = [:mark]
        nodelistname.actions[:exit] = [:nodelistname]

        nodelistdistance = re"\w+"
        nodelistdistance.actions[:enter] = [:mark]
        nodelistdistance.actions[:exit] = [:nodelistdistance]

        cat(re")", opt(nodelistname), opt(cat(re":", nodelistdistance)))
    end
    nodelistfinish.actions[:exit] = [:nodelistfinish]

    node = let
        cat(
            opt(nodeliststart),
            leaf,
            alt(leaffinish, nodelistfinish)
        )
    end

    newick = cat(rep(node), re";")

    Automa.compile(newick)
end)()


const actions = Dict(
    :mark => :(@mark),
    :countline => :(linenum += 1),

    :leafname => quote
        str = String(data[@markpos():p - 1])
        name!(record, str)
        @debug "name" str
    end,

    :leaffinish => quote
        @escape
        @debug "leaffinish"
    end,

    :leafdistance => quote
        str = String(data[@markpos():p - 1])
        parsed = parse(Float64, str)
        distance!(record, parsed)
        @debug "distance" str parsed
    end,

    :nodeliststart => quote
        prenatal!(record)
        treestate = :prenatal
        @escape
        @debug "prenatal"
    end,

    :nodelistname => quote
        str = String(data[@markpos():p - 1])
        name!(record.parent, str)
        @debug "name" str
    end,

    :nodelistdistance => quote
        str = String(data[@markpos():p - 1])
        parsed = parse(Float64, str)
        distance!(record.parent, parsed)
        @debug "distance" str parsed
    end,

    :nodelistfinish => quote
        treestate = :lastchild
        @debug "nodelistfinish"
        @escape
    end

)

initcode = quote

    treestate = :leaf

    cs, linenum = state
end

# loopcode = quote
#     prenatal && @goto __return__
#     lastchild && @goto __return__
# end

returncode = :(return cs, linenum, treestate)

context = Automa.CodeGenContext(generator = :goto, checkbounds = false, loopunroll = 8)

Automa.Stream.generate_reader(
    :readrecord!,
    machine,
    arguments = (:(record::Record), :(state::Tuple{Int,Int})),
    actions = actions,
    context = context,
    initcode = initcode,
    loopcode = loopcode,
    returncode = returncode
) |> eval
