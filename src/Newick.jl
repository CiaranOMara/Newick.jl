module Newick

import Automa
import Automa.RegExp: @re_str
import Automa.Stream: @mark, @markpos, @relpos, @abspos

import TranscodingStreams: TranscodingStreams, TranscodingStream

using AbstractTrees

mutable struct Record
    name::Union{Missing, String}
    distance::Union{Missing, Float64}
    parent::Union{Missing, Record}
    children::Union{Missing, Vector{Record}}
end

"Root constructor"
function Record()
    return Record(missing, missing, missing, missing)
end

"Child node constructor"
function Record(parent::Record)
    return Record(missing, missing, parent, missing)
end

function prenatal!(record)
    record.children = Vector{Record}()
    return record
end

function empty!(record::Record)
    record.name = missing
    record.distance = missing
    empty!(record.children)
    record.children = missing
    return record
end

function name(record::Record)
    return record.name
end

function name!(record::Record, name)
    record.name = name
    return record
end

function distance(record::Record)
    return record.distance
end

function distance!(record::Record, distance)
    record.distance = distance
    return record
end

function haschildren(record::Record)
    return !ismissing(record.children)
end

const machine = (function ()

    re = Automa.RegExp

    cat = Automa.RegExp.cat
    rep = Automa.RegExp.rep
    opt = Automa.RegExp.opt
    alt = Automa.RegExp.alt

    name = re"[0-9A-Za-z_-]+?"
    name.actions[:enter] = [:mark]
    name.actions[:exit] = [:name]

    distance = let
        len = cat(re"[0-9]+", opt(re"\.[0-9]*"))
        len.actions[:enter] = [:mark]

        opt(cat(re":", len))
    end
    distance.actions[:exit] = [:distance]

    nodefinish = re","
    nodefinish.actions[:enter] = [:nodefinish]

    cladestart = re"\("
    cladestart.actions[:enter] = [:cladestart]

    cladefinish = re"\)"
    cladefinish.actions[:enter] = [:nodefinish, :cladefinish]

    finish = re";"
    finish.actions[:enter] = [:finish]


    node = cat(
        opt(cladestart),
        opt(name),
        opt(distance),
        alt(nodefinish, cladestart, cladefinish, finish)
    )

    newick = rep(node)

    Automa.compile(newick)
end)()


const actions = Dict(
    :mark => :(@mark),

    :name => quote
        @debug "name $p"
        r = @markpos():p - 1
        if length(r) > 0
            str = String(data[r])
            name!(record, str)
        end
    end,

    :distance => quote
        @debug "distance $p"
        r = @markpos():p - 1
        if length(r) > 0
            str = String(data[r])
            parsed = parse(Float64, str)
            distance!(record, parsed)
        end
    end,

    :nodefinish => quote
        @debug "nodefinish $p"
        push!(record.parent.children, record)
        record = Record(record.parent)
    end,

    :cladestart => quote
        @debug "cladestart $p"
        prenatal!(record)
        record = Record(record) # Setup first child.
    end,

    :cladefinish => quote
        @debug "cladefinish $p"
        record = record.parent # Move to parent.
    end,

    :finish => quote
        @debug "finish $p"
    end
)

initcode = quote
    root = record
end

returncode = :(return cs, root)

context = Automa.CodeGenContext(generator = :goto, checkbounds = false, loopunroll = 8)

Automa.Stream.generate_reader(
    :read!,
    machine,
    arguments = (:(record::Record),),
    actions = actions,
    context = context,
    initcode = initcode,
    returncode = returncode
) |> eval


function Base.show(io::IO, node::Record)
    return print(io, (name=node.name, distance=node.distance, children=node.children))
end

function AbstractTrees.printnode(io::IO, node::Record)
    return print(io, (name=node.name, distance=node.distance))
end

function AbstractTrees.children(r::Record)
    if !haschildren(r)
        return ()
    end
    return r.children
end

end # module
