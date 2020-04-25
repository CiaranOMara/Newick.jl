module Newick

import Automa
import Automa.RegExp: @re_str
import Automa.Stream: @mark, @markpos, @relpos, @abspos
import BioGenerics: BioGenerics, isfilled
# import BioGenerics.Exceptions: missingerror
import BioGenerics.Automa: State
import TranscodingStreams: TranscodingStreams, TranscodingStream

using AbstractTrees

include("record.jl")
include("readrecord.jl")
include("reader.jl")

end # module
