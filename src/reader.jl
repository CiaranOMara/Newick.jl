struct Reader{S <: TranscodingStream} <: BioGenerics.IO.AbstractReader
    state::State{S}
end

function Reader(input::IO)
    if !(input isa TranscodingStream)
        stream = TranscodingStreams.NoopStream(input)
    end

    return Reader(State(stream, 1, 1, false))
end

function Base.eltype(::Type{<:Reader}) #TODO: reader would not be iterable.
    return Record
end

function BioGenerics.IO.stream(reader::Reader)
    return reader.state.stream
end


function Record(data::Vector{UInt8})
    record = Record()
    stream = TranscodingStreams.NoopStream(IOBuffer(data))
    cs, linenum, found = readrecord!(stream, record, (1, 1))
    if !found
        throw(ArgumentError("invalid record"))
    end
    return record
end

function Record(str::AbstractString)
    return Record(collect(UInt8,str))
end

#TODO: post fill parent name and distance, so as not to read the whole file.

function Base.read!(rdr::Reader, rec::Record)
    cs, ln, f = readrecord!(rdr.state.stream, rec, (rdr.state.state, rdr.state.linenum))
    rdr.state.state = cs
    rdr.state.linenum = ln
    rdr.state.filled = f
    if !f
        cs == 0 && throw(EOFError())
        throw(ArgumentError("malformed file"))
    end
    return rec
end

function Base.close(reader::Reader)
    if reader.state.stream isa IO
        close(reader.state.stream)
    end
    return nothing
end
