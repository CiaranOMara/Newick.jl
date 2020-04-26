using Test
using Newick
using TranscodingStreams

newicks = [
    "(,,(,));",# 1) no nodes are named
    "(A,B,(C,D));",# 2) leaf nodes are named
    "(A,B,(C,D)E)F;",# 3) all nodes are named
    "(:0.1,:0.2,(:0.3,:0.4):0.5);",# 4) all but root node have a distance to parent
    "(:0.1,:0.2,(:0.3,:0.4):0.5):0.0;",# 5) all have a distance to parent
#    00000000011111111112222222222333
#    12345678901234567890123456789012
    "(A:0.1,B:0.2,(C:0.3,D:0.4):0.5);",# 6) distances and leaf names (popular)
    "(A:0.1,B:0.2,(C:0.3,D:0.4)E:0.5)F;",# 7) distances and all names
    "((B:0.2,(C:0.3,D:0.4)E:0.5)A:0.1)F;",# 8) a tree rooted on a leaf node (rare)
]


@testset "popular" begin
    stream = TranscodingStreams.NoopStream(IOBuffer(newicks[6]))

    root = Newick.Record()
    record = root

    @test !Newick.haschildren(record)

    # @test_logs (:debug, "nodeliststart") min_level=Base.CoreLogging.Debug Newick.readrecord!(stream, root, (1,1))
    @test_logs (:debug, "nodeliststart 1") min_level=Base.CoreLogging.Debug Newick.readrecord!(stream, record)

    @test Newick.haschildren(record)
    parent = record

    record = Newick.Record(parent)
    @test_logs (:debug, "leafname 16") (:debug, "leafdistance 20") (:debug, "leaffinish 20") min_level=Base.CoreLogging.Debug Newick.readrecord!(stream, record)

    push!(root.children, record)

    record = Newick.Record(root)
    @test_logs (:debug, "leafname 22") (:debug, "leafdistance 26") (:debug, "leaffinish 13") min_level=Base.CoreLogging.Debug Newick.readrecord!(stream, record)

    push!(root.children, record)

    record = Newick.Record(root)
    @test_logs (:debug, "nodeliststart 14") min_level=Base.CoreLogging.Debug Newick.readrecord!(stream, root)

    push!(root.children, record)

    parent = record
    record = Newick.Record(parent)
    @test_logs (:debug, "leafname 3") (:debug, "leafdistance 7") (:debug, "leaffinish 7") min_level=Base.CoreLogging.Debug Newick.readrecord!(stream, record)
    push!(root.children, record)

    record = Newick.Record(parent)
    @test_logs (:debug, "leafname 3") (:debug, "leafdistance 7") (:debug, "leaffinish 7") min_level=Base.CoreLogging.Debug Newick.readrecord!(stream, record)
    push!(root.children, record)


end
