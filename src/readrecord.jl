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

    record = let
        space = re"[\t ]+"

        name = re"\w+"
        name = re"\w+"

        distance = re"\w+"

        leaf = let
            # optional name
            # optional distance
        end

        nodeliststart = re"\("
        position.actions[:enter] = [:nodeliststart]

        nodelistfinish = let

        end

        leaffinish = re","
        nodelistfinish = re"\)"

        node = let
            cat(
                opt(nodeliststart),
                opt(name),
                opt(cat(re":", distance)),
                alt(leaffinish, nodelistfinish)
            )
        end


        alt(
            re",",


        )


        nodelist = let



        end

        pfm = let
            position = re"[0-9]*"
            position.actions[:enter] = [:record_pfm_position]

            frequency = re"[0-9]*"
            frequency.actions[:enter] = [:mark]
            frequency.actions[:exit] = [:record_pfm_frequency]

            nucleotide = re"[ACGT]"
            nucleotide.actions[:enter] = [:mark]
            nucleotide.actions[:exit] = [:record_pfm_nucleotide]

            rep1(cat(position, space, frequency, space, frequency, space, frequency, space, frequency, space, nucleotide, newline))
        end

        cat("DE", space, header, newline, pfm, "XX", newline)
    end
    record.actions[:exit] = [:record]

    newick = rep(cat(record, rep(newline)))

    Automa.compile(newick)
end)()


const actions = Dict(
    :mark => :(@mark),
    # :countline => :(linenum += 1),

    :nodename => quote
        str = String(data[@markpos():p - 1])
        name!(record, str)
        @debug "name" str
    end,

    :nodedistance => quote
        str = String(data[@markpos():p - 1])
        parsed = parse(Float64, str)
        distance!(record, parsed)
        @debug "distance" str parsed
    end,

    :nodelist => quote
        prenatal!(record)
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

    :node => quote
            record.frequencies = reshape(frequencies, 4, :)
            record.sequence = sequence
            found = true
            @escape
    end,
    :nodelist => quote
            record.frequencies = reshape(frequencies, 4, :)
            record.sequence = sequence
            found = true
            @escape
        end
    )
)



initcode = quote

    found = false


    cs, linenum = state
end

loopcode = quote
    found && @goto __return__
end

returncode = :(return cs, linenum, found)

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
