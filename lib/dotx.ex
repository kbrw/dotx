# public interface and doc main library file

defmodule Dotx do
  @type id :: binary | %Dotx.HTML{html: binary}
  @type nodeid :: [binary]
  @type graph :: graph(edge) | graph(flatedge)
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
  @type dotnode :: %Dotx.Node{id: nodeid, attrs: %{optional(id) => id}}
  @type edge :: %Dotx.Edge{
    attrs: %{optional(id) => id}, bidir: boolean,
    from: dotnode | subgraph(edge), to: dotnode | subgraph(edge) | edge
  }
  @type flatedge :: %Dotx.Edge{
    attrs: %{optional(id) => id}, bidir: boolean,
    from: dotnode, to: dotnode
  }
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

  Some additional helper function are useful to inspect a graph and use them :
  - `flatten/1` create unitary edge for every DOT shortand (inline edge
     `a->b->c` or graph edge `{a b}->c`)
  - `spread_attributes/1` spread default attributes from graph/subgraphs to
     all children handling inheritance of attributes.
  """
  @spec encode(graph) :: binary
  def encode(graph) do to_string(graph) end

  @spec decode(binary) :: {:ok,graph(edge)} | {:error,msg :: binary}
  defdelegate decode(bin), to: Dotx.Graph, as: :parse

  @spec decode!(binary) :: graph(edge)
  defdelegate decode!(bin), to: Dotx.Graph, as: :parse!

  @spec flatten(graph(edge)) :: graph(flatedge)
  defdelegate flatten(graph), to: Dotx.Helpers

  @spec spread_attributes(graph) :: graph
  defdelegate spread_attributes(graph), to: Dotx.Helpers

  @spec identify(graph(edge)) :: graph(edge)
  defdelegate identify(graph), to: Dotx.Helpers

  defdelegate to_nodes(graph), to: Dotx.Helpers
  defdelegate to_edges(graph), to: Dotx.Helpers
  defdelegate to_digraph(graph), to: Dotx.Helpers
end
