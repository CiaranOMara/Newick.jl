using Test
using Newick

# no nodes are named
(,,(,));

# leaf nodes are named
(A,B,(C,D));

# all nodes are named
(A,B,(C,D)E)F;

# all but root node have a distance to parent
(:0.1,:0.2,(:0.3,:0.4):0.5);

# all have a distance to parent
(:0.1,:0.2,(:0.3,:0.4):0.5):0.0;

# distances and leaf names (popular)
(A:0.1,B:0.2,(C:0.3,D:0.4):0.5);

# distances and all names
(A:0.1,B:0.2,(C:0.3,D:0.4)E:0.5)F;

# a tree rooted on a leaf node (rare)
((B:0.2,(C:0.3,D:0.4)E:0.5)A:0.1)F;
