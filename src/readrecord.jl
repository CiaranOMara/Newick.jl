const machine = (function ()

    re = Automa.RegExp

    cat = Automa.RegExp.cat
    rep = Automa.RegExp.rep
    rep1 = Automa.RegExp.rep1
    opt = Automa.RegExp.opt
    alt = Automa.RegExp.alt

    name = re"[0-9A-Za-z_-]+?"

    distance = cat(re"[0-9]+", opt(re"\.[0-9]*"))

    # newline = let
    #     lf = re"\n"
    #     lf.actions[:enter] = [:countline]
    #
    #     cat(opt('\r'), lf)
    # end

    space = re"[\t ]+"

    leaf = let
        leafname = name
        leafname.actions[:enter] = [:mark]
        leafname.actions[:exit] = [:leafname]

        leafdistance = distance
        leafdistance.actions[:enter] = [:mark]
        leafdistance.actions[:exit] = [:leafdistance]

        cat(opt(leafname), opt(cat(re":", leafdistance)))
    end

    leaffinish = re","
    leaffinish.actions[:enter] = [:leaffinish]

    nodeliststart = re"\("
    nodeliststart.actions[:enter] = [:nodeliststart]

    # nodelistfinish = let
    #     nodelistname = name
    #     nodelistname.actions[:enter] = [:mark]
    #     nodelistname.actions[:exit] = [:nodelistname]
    #
    #     nodelistdistance = distance
    #     nodelistdistance.actions[:enter] = [:mark]
    #     nodelistdistance.actions[:exit] = [:nodelistdistance]
    #
    #     cat(re"\)", opt(nodelistname), opt(cat(re":", nodelistdistance)))
    # end
    # nodelistfinish.actions[:exit] = [:nodelistfinish]

    # node = cat(
    #         opt(nodeliststart),
    #         leaf,
    #         alt(leaffinish, nodelistfinish)
    #     )

    # newick = cat(rep(node), re";")

    # newick = cat(nodeliststart, re".*?;")
    # newick = cat(opt(nodeliststart), re".*?;")
    newick = cat(opt(nodeliststart), leaf, leaffinish, re".*?;")

    Automa.compile(newick)
end)()


const actions = Dict(
    :mark => :(@mark),
    # :countline => :(linenum += 1),

    :leafname => quote
        @debug "leafname $p"
        str = String(data[@markpos():p - 1])
        name!(record, str)
    end,

    :leafdistance => quote
        @debug "leafdistance $p"
        str = String(data[@markpos():p - 1])
        parsed = parse(Float64, str)
        distance!(record, parsed)
    end,

    :leaffinish => quote
        @debug "leaffinish $p"
        treestate = :leaf
        @escape
    end,

    :nodeliststart => quote
        @debug "nodeliststart $p"
        prenatal!(record)
        treestate = :prenatal
        @escape
    end,

    :nodelistname => quote
        @debug "nodelistname $p"
        str = String(data[@markpos():p - 1])
        name!(record.parent, str)
    end,

    :nodelistdistance => quote
        @debug "nodelistdistance $p"
        str = String(data[@markpos():p - 1])
        parsed = parse(Float64, str)
        distance!(record.parent, parsed)
    end,

    :nodelistfinish => quote
        @debug "nodelistfinish $p"
        treestate = :lastchild
        @escape
    end

)

initcode = quote

    treestate = :empty

    # cs, linenum = state
end

loopcode = quote
    treestate != :empty && @goto __return__
end

# returncode = :(return cs, linenum, treestate)
returncode = :(return cs, treestate)

context = Automa.CodeGenContext(generator = :goto, checkbounds = false, loopunroll = 8)

Automa.Stream.generate_reader(
    :readrecord!,
    machine,
    # arguments = (:(record::Record), :(state::Tuple{Int,Int})),
    arguments = (:(record::Record),),
    actions = actions,
    context = context,
    initcode = initcode,
    loopcode = loopcode,
    returncode = returncode
) |> eval
