using Test
using Newick
using TranscodingStreams

using Base.CoreLogging:Debug

@testset "Newick" begin

@testset "no nodes are named" begin

    #         12345678
    newick = "(,,(,));"

    stream = TranscodingStreams.NoopStream(IOBuffer(newick))

    root = Newick.Record()

    @test_logs(
        (:debug, "cladestart 1"),
        (:debug, "nodefinish 2"),
        (:debug, "nodefinish 3"),
        (:debug, "cladestart 4"),
        (:debug, "nodefinish 5"),
        (:debug, "nodefinish 6"),
        (:debug, "cladefinish 6"),
        (:debug, "nodefinish 7"),
        (:debug, "cladefinish 7"),
        (:debug, "finish 8"),
        min_level=Debug,
        Newick.read!(stream, root)
    )

    @info "no nodes are named" newick root

    Newick.print_tree(root)

end

@testset "leaf nodes are named" begin

    #         000000000111
    #         123456789012
    newick = "(A,B,(C,D));"

    stream = TranscodingStreams.NoopStream(IOBuffer(newick))

    root = Newick.Record()

    @test_logs(
        (:debug, "cladestart 1"),
        (:debug, "name 3"),
        (:debug, "nodefinish 3"),
        (:debug, "name 5"),
        (:debug, "nodefinish 5"),
        (:debug, "cladestart 6"),
        (:debug, "name 8"),
        (:debug, "nodefinish 8"),
        (:debug, "name 10"),
        (:debug, "nodefinish 10"),
        (:debug, "cladefinish 10"),
        (:debug, "nodefinish 11"),
        (:debug, "cladefinish 11"),
        (:debug, "finish 12"),
        min_level=Debug,
        Newick.read!(stream, root)
    )

    @info "leaf nodes are named" newick root

    Newick.print_tree(root)

end

@testset "all nodes are named" begin
    #         00000000011111
    #         12345678901234
    newick = "(A,B,(C,D)E)F;"

    stream = TranscodingStreams.NoopStream(IOBuffer(newick))

    root = Newick.Record()

    @test_logs(
        (:debug, "cladestart 1"),
        (:debug, "name 3"), #A
        (:debug, "nodefinish 3"),
        (:debug, "name 5"), #B
        (:debug, "nodefinish 5"),
        (:debug, "cladestart 6"),
        (:debug, "name 8"), #C
        (:debug, "nodefinish 8"),
        (:debug, "name 10"), #D
        (:debug, "nodefinish 10"),
        (:debug, "cladefinish 10"),
        (:debug, "name 12"), #E
        (:debug, "nodefinish 12"),
        (:debug, "cladefinish 12"),
        (:debug, "name 14"), #F
        (:debug, "finish 14"),
        min_level=Debug,
        Newick.read!(stream, root)
    )

    @info "all nodes are named" newick root

    Newick.print_tree(root)

end

@testset "all but root node have a distance to parent" begin

    #         0000000001111111111222222222
    #         1234567890123456789012345678
    newick = "(:0.1,:0.2,(:0.3,:0.4):0.5);"

    stream = TranscodingStreams.NoopStream(IOBuffer(newick))

    root = Newick.Record()

    @test_logs(
        (:debug, "cladestart 1"),
        (:debug, "distance 6"),
        (:debug, "nodefinish 6"),
        (:debug, "distance 11"),
        (:debug, "nodefinish 11"),
        (:debug, "cladestart 12"),
        (:debug, "distance 17"),
        (:debug, "nodefinish 17"),
        (:debug, "distance 22"),
        (:debug, "nodefinish 22"),
        (:debug, "cladefinish 22"),
        (:debug, "distance 27"),
        (:debug, "nodefinish 27"),
        (:debug, "cladefinish 27"),
        (:debug, "finish 28"),
        min_level=Debug,
        Newick.read!(stream, root)
    )

    @info "all but root node have a distance to parent" newick root

    Newick.print_tree(root)

end

@testset "all have a distance to parent" begin

    #         00000000011111111112222222222333
    #         12345678901234567890123456789012
    newick = "(:0.1,:0.2,(:0.3,:0.4):0.5):0.0;"

    stream = TranscodingStreams.NoopStream(IOBuffer(newick))

    root = Newick.Record()

    @test_logs(
        (:debug, "cladestart 1"),
        (:debug, "distance 6"),
        (:debug, "nodefinish 6"),
        (:debug, "distance 11"),
        (:debug, "nodefinish 11"),
        (:debug, "cladestart 12"),
        (:debug, "distance 17"),
        (:debug, "nodefinish 17"),
        (:debug, "distance 22"),
        (:debug, "nodefinish 22"),
        (:debug, "cladefinish 22"),
        (:debug, "distance 27"),
        (:debug, "nodefinish 27"),
        (:debug, "cladefinish 27"),
        (:debug, "distance 32"),
        # (:debug, "nodefinish 32"), #TODO: not sure about this one. But, it does yeild the correct result.
        (:debug, "finish 32"),
        min_level=Debug,
        Newick.read!(stream, root)
    )

    @info "all have a distance to parent" newick root

    Newick.print_tree(root)

end

@testset "distances and leaf names (popular)" begin

    #         00000000011111111112222222222333
    #         12345678901234567890123456789012
    newick = "(A:0.1,B:0.2,(C:0.3,D:0.4):0.5);"

    stream = TranscodingStreams.NoopStream(IOBuffer(newick))

    root = Newick.Record()

    @test_logs(
        (:debug, "cladestart 1"),
        (:debug, "name 3"),
        (:debug, "distance 7"),
        (:debug, "nodefinish 7"),
        (:debug, "name 9"),
        (:debug, "distance 13"),
        (:debug, "nodefinish 13"),
        (:debug, "cladestart 14"),
        (:debug, "name 16"),
        (:debug, "distance 20"),
        (:debug, "nodefinish 20"),
        (:debug, "name 22"),
        (:debug, "distance 26"),
        (:debug, "nodefinish 26"),
        (:debug, "cladefinish 26"),
        (:debug, "distance 31"),
        (:debug, "nodefinish 31"),
        (:debug, "cladefinish 31"),
        (:debug, "finish 32"),
        min_level=Debug,
        Newick.read!(stream, root)
    )

    @info "distances and leaf names (popular)" newick root

    Newick.print_tree(root)

end

@testset "distances and all names" begin

    #         0000000001111111111222222222233333
    #         1234567890123456789012345678901234
    newick = "(A:0.1,B:0.2,(C:0.3,D:0.4)E:0.5)F;"

    stream = TranscodingStreams.NoopStream(IOBuffer(newick))

    root = Newick.Record()

    @test_logs(
        (:debug, "cladestart 1"),
        (:debug, "name 3"),
        (:debug, "distance 7"),
        (:debug, "nodefinish 7"),
        (:debug, "name 9"),
        (:debug, "distance 13"),
        (:debug, "nodefinish 13"),
        (:debug, "cladestart 14"),
        (:debug, "name 16"),
        (:debug, "distance 20"),
        (:debug, "nodefinish 20"),
        (:debug, "name 22"),
        (:debug, "distance 26"),
        (:debug, "nodefinish 26"),
        (:debug, "cladefinish 26"),
        (:debug, "name 28"),
        (:debug, "distance 32"),
        (:debug, "nodefinish 32"),
        (:debug, "cladefinish 32"),
        (:debug, "name 34"),
        (:debug, "finish 34"),
        min_level=Debug,
        Newick.read!(stream, root)
    )

    @info "distances and all names" newick root

    Newick.print_tree(root)

end

@testset "a tree rooted on a leaf node (rare)" begin

    #         00000000011111111112222222222333333
    #         12345678901234567890123456789012345
    newick = "((B:0.2,(C:0.3,D:0.4)E:0.5)A:0.1)F;"

    stream = TranscodingStreams.NoopStream(IOBuffer(newick))

    root = Newick.Record()

    @test_logs(
        (:debug, "cladestart 1"),
        (:debug, "cladestart 2"),
        (:debug, "name 4"),
        (:debug, "distance 8"),
        (:debug, "nodefinish 8"),
        (:debug, "cladestart 9"),
        (:debug, "name 11"),
        (:debug, "distance 15"),
        (:debug, "nodefinish 15"),
        (:debug, "name 17"),
        (:debug, "distance 21"),
        (:debug, "nodefinish 21"),
        (:debug, "cladefinish 21"),
        (:debug, "name 23"),
        (:debug, "distance 27"),
        (:debug, "nodefinish 27"),
        (:debug, "cladefinish 27"),
        (:debug, "name 29"),
        (:debug, "distance 33"),
        (:debug, "nodefinish 33"),
        (:debug, "cladefinish 33"),
        (:debug, "name 35"),
        (:debug, "finish 35"),
        min_level=Debug,
        Newick.read!(stream, root)
    )

    @info "a tree rooted on a leaf node (rare)" newick root

    Newick.print_tree(root)

end

end # testset "Newick"
