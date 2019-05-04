# public interface and doc main library file

defmodule Dotx do
  @typedoc """
    An `id` type is a value in DOT : either a simple string or an HTML string.
    The `%Dotx.HTML{}` allows you to match the latter.
    """
  @type id :: binary | %Dotx.HTML{html: binary}
  @typedoc """
    A `nodeid` type is a either a simple node id `["myid"]` or a node id with a port : `["myid","myport"]`
    """
  @type nodeid :: [binary]
  @type graph :: graph(edge) | graph(flatedge)
  @typedoc """
    The main structure containing all parsed info from a DOT graph : 
    - `strict` is `true` if the strict prefix is present
    - `type` is `:digraph` if graph is a directed graph, `:graph` otherwise
    - `attrs` are the attributes of the graph itself : any key-values are allowed 
    - `(nodes|edges|graphs)_attrs` are attributes which all subelements
       (respectively node, edge or subgraph) will inherited (`node [key=value]` in DOT)
    - `children` is the list of childs : dot, edge or subgraph
    """
  @type graph(edgetype) :: %Dotx.Graph{
          strict: boolean,
          type: :graph | :digraph,
          id: nil | id,
          attrs: %{optional(id) => id},
          nodes_attrs: %{optional(id) => id},
          edges_attrs: %{optional(id) => id},
          graphs_attrs: %{optional(id) => id},
          children: [dotnode | edgetype | subgraph(edgetype)]
        }
  @typedoc """
    A `dotnode` is the leaf structure of the graph: only an id and its attributes as a free map.
    """
  @type dotnode :: %Dotx.Node{id: nodeid, attrs: %{optional(id) => id}}

  @typedoc """
    An `edge` is a link between nodes (from:,to:), it has attributes which are set by itself or inherited (see `graph()`)

    `to` can be another edge (`a->b->c->d`) to inline multiple edges or subgraph `{a b}->{c d}` as a shortcut to
    `a->c a->d b->c b->d`. You can use `Dotx.flatten/1` to expand edges and get only `flatedge()` with link between raw nodes.
    """
  @type edge :: %Dotx.Edge{
    attrs: %{optional(id) => id}, bidir: boolean,
    from: dotnode | subgraph(edge), to: dotnode | subgraph(edge) | edge
  }
  @typedoc "see `edge()` : an edge with raw `dotnode()`, after `Dotx.flatten` all edges are `flatedge()`"
  @type flatedge :: %Dotx.Edge{
    attrs: %{optional(id) => id}, bidir: boolean,
    from: dotnode, to: dotnode
  }
  @typedoc "see `graph()` : same as graph without graph type specification"
  @type subgraph(edgetype) :: %Dotx.SubGraph{
    id: nil | id,
    attrs: %{optional(id) => id},
    nodes_attrs: %{optional(id) => id},
    edges_attrs: %{optional(id) => id},
    graphs_attrs: %{optional(id) => id},
    children: [dotnode | edgetype | subgraph(edgetype)]
  }
  @moduledoc """
  This library is a DOT parser and generator.
  Main functions are `encode/1` and `decode/1` (usable also via `to_string`
  and the `String.Chars` protocol).

  The structure of type `graph()` allows easy handling of decoding dot graph,
  the principle is that the structure is exactly homogeneous with a dot graph :
  - it contains all inherited attributes for nodes, edges and subgraphs (`*_attrs`)
  - it contains `attrs` of itself in addition of the `id`
  - it is a recursive structure containing `children`: either `subgraph` or `node` or `edge`
  - and edge can be `from` and `to` nodes but also subgraph (`a->{c d}`) or
    other edge (`a->c->d`). They are *edge shorthands* which are actually
    sugars to define lists of `node->node` edges.

  The structure is usable by itself, but subgraph tree, edge shorthands and attribute
  inheritance make it non trivial to handle. So to help you manage this complexity Dotx provides 
  helper functions : 
  - `flatten/1` create unitary edge for every DOT shortand (inline edge
     `a->b->c` or graph edge `{a b}->c`) so all edges are expanded to get only
     `node->node` edges (`a->b a->c b->c`)
  - `spread_attributes/1` spread default attributes from graph/subgraphs tree to
     all children handling inheritance of attributes, but keeping original graph structure.
  - `identify/1` add an identifier to all graph and subgraph without id in
     original graph : `xN` where `N` is the index of the subgraph in the order
     of appearance in the file.
  - `to_nodes/1` returns a flat databases of nodes and graphs containing
     additional special attributes to preserve the graph informations
     (`"graph"`,`"edges_from"`,`"parent"`,`"children"`), and where all
     inherited attributes are filled.
  - `to_edges/1` returns a flat databases of edges and graphs containing
     additional special attributes to preserve the graph informations
     (`"graph"`,`"parent"`,`"children"`) and where the `from` and `to` fields
     are filled with complete node structures with inherited attributes.
  - `to_digraph/1` returns an erlang `digraph` structure where vertices are
     nodes id. This allows you to use `:digraph_utils` module to do complex graph
     computations.
  """

  @doc "Main lib function: same as `to_string(graph)`, encode (pretty) graph as a DOT binary string"
  @spec encode(graph) :: binary
  def encode(graph) do to_string(graph) end

  @doc "Main lib function: parse a DOT graph to get a `Dotx.Graph` structure"
  @spec decode(binary) :: {:ok,graph(edge)} | {:error,msg :: binary}
  defdelegate decode(bin), to: Dotx.Graph, as: :parse

  @doc "Same as `decode/1` but with an `BadArgument` error if DOT file is not valid"
  @spec decode!(binary) :: graph(edge)
  defdelegate decode!(bin), to: Dotx.Graph, as: :parse!

  @doc """
    flatten all dot edge shortcuts (`a->{b c}->d` became `a->b a->c b->d c->d`), so that all `Dotx.Edge` 
    have only `Dotx.Node` in both sides (from and to).
    """
  @spec flatten(graph(edge)) :: graph(flatedge)
  defdelegate flatten(graph), to: Dotx.Helpers

  @doc """
    Spread all inherited attributes `(nodes|edges|graphs)_attrs` or graphs to
    descendants `attrs`
    """
  @spec spread_attributes(graph) :: graph
  defdelegate spread_attributes(graph), to: Dotx.Helpers

  @doc """
    Give an `id` to all graph and subgraph if none are given :
    `{ a { b c } }` became `subgraph x0 { a subgraph x1 { b c } }`
    """
  @spec identify(graph(edge)) :: graph(edge)
  defdelegate identify(graph), to: Dotx.Helpers

  @doc """
    Returns a flat databases of nodes and graphs containing
    additional special attributes to preserve the graph informations
    (`"graph"`,`"edges_from"`,`"parent"`,`"children"`), and where all
    inherited attributes are filled : 

    - `identify/1` is called to ensure every subgraph has an id
    - `flatten/1` is called to ensure that every unitary edges are expanded from DOT shorthands.

    For nodes returned :
    - the attrs are filled with inherited attributes from parent subgraphs `nodes_attrs` (`node [k=v]`)
    - `"graph"` attribute is added to each node and contains the identifier of
       the subgraph owning the node (the deepest subgraph containing the node in the DOT graph tree)
    - `"edges_from"` attribute is added to every node and contains the list of
      `%Dotx.Edge{}` from this node in the graph. For these edges structures :
        - the `"graph"` is also filled (the graph owning the edge is not
          necessary the one owning the nodes on both sides)
        - the attrs are filled with inherited attributes from parent subgraphs `edges_attrs` (`edge [k=v]`)
        - the `from` and `to` `%Dotx.Node` contains only `id`, attributes
          `attrs` are not set to avoid redundancy of data with parent nodes
           data.

    For graphs returned : 
    - the attrs are filled with inherited attributes from parent subgraphs `graphs_attrs` (`graph [k=v]`)
    - the `"parent"` attribute is added containing parent graph id in the subgraph tree
    - the `"children"` attribute is added containing childs graph id list in the subgraph tree
    - the `:children` is set to empty list `[]` to only use the graph
      structure to get attributes and not nodes and edges already present in the
      nodes map returned.
    """
  @type nodes_db :: {
    nodes  :: %{ nodeid() => node() },
    graphs :: %{ id() => graph() }
  }
  @spec to_nodes(graph) :: nodes_db
  defdelegate to_nodes(graph), to: Dotx.Helpers

  @doc """
    Other variant of `to_nodes/1` : fill edges and nodes with all inherited
    attributes and also with a `"graph"` attribute. But instead of returning
    nodes with edges filled in attribute `edges_from`, it returns the list of all edges
    where all nodes in `from` and `to` are fully filled `%Dotx.Node{}` structures.

    - The function actually call `to_nodes/1` so you can put `to_nodes/1` result as parameter
      to avoid doing heavy computation 2 times.
    - all rules for graphs, nodes and edges fullfilment are the same as `to_nodes/1`
    """
  @spec to_edges(graph | nodes_db) :: {edges :: [flatedge()], graphs :: %{ id() => graph() }}
  defdelegate to_edges(graph_or_nodesdb), to: Dotx.Helpers

  @doc """
    Create an erlang `:digraph` structure from graph (see [erlang doc](http://erlang.org/doc/man/digraph.html))
    where vertices are `nodeid()`.
    This allows to easily use `:digraph` and `:digraph_utils` handlers to go
    through the graph and make complex analysis of the graph.
    """
  @spec to_digraph(graph) :: :digraph.graph()
  defdelegate to_digraph(graph), to: Dotx.Helpers
end
