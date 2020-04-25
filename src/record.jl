mutable struct Record
    name::Union{Missing, String}
    distance::Union{Missing, Float64}
    parent::Union{Missing, Record}
    children::Union{Missing, Vector{Record}}
end

function Record()
    return Record(missing, missing, missing, missing)
end

function Record(parent::Record)
    return Record(missing, missing, parent, missing)
end

function prenatal!(record)
    record.children = Vector{record}()
end

function empty!(record::Record)
    record.name = missing
    record.distance = missing
    empty!(record.children)
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
