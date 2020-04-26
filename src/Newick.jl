module Newick

import Automa
import Automa.RegExp: @re_str
import Automa.Stream: @mark, @markpos, @relpos, @abspos

import TranscodingStreams: TranscodingStreams, TranscodingStream

using AbstractTrees

include("record.jl")
include("readrecord.jl")
include("reader.jl")

end # module
