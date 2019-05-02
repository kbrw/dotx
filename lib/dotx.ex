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
  def decode(bin) do Dotx.Graph.parse(bin) end

  @spec decode!(binary) :: graph(edge)
  def decode!(bin) do
    case decode(bin) do
      {:ok,graph}->graph
      {:error,msg}->
        raise ArgumentError, "cannot parse DOT : #{msg}"
    end
  end

  @spec flatten(graph(edge)) :: graph(flatedge)
  def flatten(%Dotx.Graph{children: children}=graph) do 
    %{graph|children: Enum.flat_map(children,&flatten(&1))}
  end
  def flatten(%Dotx.SubGraph{children: children}=graph) do
    [%{graph|children: Enum.flat_map(children,&flatten(&1))}]
  end
  def flatten(%Dotx.Edge{}=e) do Dotx.Edge.flatten(e) end
  def flatten(other) do [other] end

  @spec spread_attributes(graph) :: graph
  def spread_attributes(graph) do 
    %{graph|children: Enum.map(graph.children,&spread_attributes(&1,graph))}
  end
  def spread_attributes(%Dotx.SubGraph{children: children}=e,graph) do
    graph = %{graph|nodes_attrs: Map.merge(graph.nodes_attrs,e.nodes_attrs),
                    edges_attrs: Map.merge(graph.edges_attrs,e.edges_attrs),
                    graphs_attrs: Map.merge(graph.graphs_attrs,e.graphs_attrs)}
    %{e|attrs: Map.merge(graph.graphs_attrs,e.attrs),
        children: Enum.map(children,&spread_attributes(&1,graph))}
  end
  def spread_attributes(%Dotx.Edge{attrs: attrs,from: from, to: to}=e,graph) do
    %{e|attrs: Map.merge(graph.edges_attrs,attrs),
        from: spread_attributes(from,graph), to: spread_attributes(to,graph)}
  end
  def spread_attributes(%Dotx.Node{attrs: attrs}=e,graph) do
    %{e|attrs: Map.merge(graph.nodes_attrs,attrs)}
  end

  @spec identify(graph(edge)) :: graph(edge)
  def identify(graph) do {g,_} = identify(graph,0); g end
  def identify(%{id: id, children: children}=graph,i) do
    {graph,i} = case id do nil-> {%{graph| id: id || "x#{i}"},i+1}; _-> {graph,i} end
    {backchildren,i} = Enum.reduce(children,{[],i},fn e, {acc,i}->
      {e,i} = identify(e,i)
      {[e|acc],i}
    end)
    {%{graph|children: Enum.reverse(backchildren)},i}
  end
  def identify(%Dotx.Edge{}=e,i) do
    {from,i} = identify(e.from,i)
    {to,i}   = identify(e.to  ,i)
    {%{e|from: from, to: to},i}
  end
  def identify(o,i) do {o,i} end

  # TODO nodes flatten with a "graph" attribute with deepest subgraph owning node
  # @spec nodes(graph(flatedge)) :: [dotnode]
  # TODO edges flatten with a "graph" attribute containing owning subgraph id
  # @spec edges(graph(flatedge)) :: [flatedge]
end
