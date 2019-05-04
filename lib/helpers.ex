defmodule Dotx.Helpers do
  # recursive Edge.flatten 
  def flatten(%Dotx.Graph{children: children}=graph) do 
    %{graph|children: Enum.flat_map(children,&flatten(&1))}
  end
  def flatten(%Dotx.SubGraph{children: children}=graph) do
    [%{graph|children: Enum.flat_map(children,&flatten(&1))}]
  end
  def flatten(%Dotx.Edge{}=e) do Dotx.Edge.flatten(e) end
  def flatten(other) do [other] end

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

  def to_nodes(graph) do
    graph = graph |> identify() |> flatten()
    res = to_nodes(graph,%{nodes: %{},graphs: %{},parent_graph: {nil,0},
                                  nodes_attrs: %{}, edges_attrs: %{}, graphs_attrs: %{}})
    nodes = Enum.into(res.nodes,%{},fn {k,n}-> 
      attrs = %{n.attrs|"graph"=> elem(n.attrs["graph"],0)} # remove graph depth
      attrs = Map.put_new(attrs,"edges_from",[]) # if no edges, add attribute edges_from to empty
      {k,%{n|attrs: attrs}}
    end)
    {nodes,res.graphs}
  end
  def to_nodes(%{children: children}=g,%{parent_graph: {parent,depth}}=acc) do
    ## put graph to db: add parent and children attributes, inherit attributes
    g = %{g|children: [],attrs: Enum.into([
          {"parent",parent},
          {"children",for %Dotx.SubGraph{id: childid}<-children do childid end}
        ],Map.merge(acc.graphs_attrs,g.attrs))}
    acc = %{acc|graphs: Map.put(acc.graphs,g.id,g)}

    nodes_attrs = Map.merge(acc.nodes_attrs,g.nodes_attrs)
    edges_attrs = Map.merge(acc.edges_attrs,g.edges_attrs)
    graphs_attrs = Map.merge(acc.graphs_attrs,g.graphs_attrs)
    Enum.reduce(children,acc,fn e,acc->
      to_nodes(e,%{acc|nodes_attrs: nodes_attrs, edges_attrs: edges_attrs, graphs_attrs: graphs_attrs, 
                       parent_graph: {g.id,depth+1}})
    end)
  end
  def to_nodes(%Dotx.Edge{from: %Dotx.Node{}=from, to: %Dotx.Node{}=to}=e,%{parent_graph: {parent,_}}=acc) do
    e = %{e|attrs: acc.edges_attrs |> Map.merge(e.attrs) |> Map.put("graph",parent)}
    acc = to_nodes(to,to_nodes(from,acc))
    %{acc|nodes: Map.update!(acc.nodes,from.id,fn oldn->
      %{oldn|attrs: Map.update(oldn.attrs,"edges_from",[e],&[e|&1])}
    end)}
  end
  def to_nodes(%Dotx.Node{}=n,%{parent_graph: {_,parentdepth}=pgraph}=acc) do
    n = %{n|attrs: Map.merge(acc.nodes_attrs,n.attrs)}
    default_n = %{n|attrs: Map.put(n.attrs,"graph",pgraph)}
    %{acc|nodes: Map.update(acc.nodes,n.id,default_n,fn oldn->
        n = %{oldn|attrs: Map.merge(oldn.attrs,n.attrs)}
        %{n|attrs: Map.update(n.attrs,"graph",acc.parent_graph, fn {_,depth}=graph->
              if parentdepth > depth do pgraph else graph end
          end)}
      end)}
  end

  def to_edges(%Dotx.Graph{}=g) do g |> to_nodes() |> to_edges() end
  def to_edges({nodes,graphs}) do
    edges = Enum.flat_map(nodes,fn {_,%Dotx.Node{attrs: attrs}}->
      Enum.map(attrs["edges_from"],fn %{from: from, to: to}=e->
        %{e|from: del_edges_from(nodes[from.id]), to: del_edges_from(nodes[to.id])}
      end)
    end)
    {edges,graphs}
  end
  def del_edges_from(n) do %{n|attrs: Map.delete(n.attrs,"edges_from")} end

  def to_digraph(%Dotx.Graph{}=dot) do g=:digraph.new ; fill_digraph(g,flatten(dot)); g end
  def fill_digraph(g,%{children: children}) do for e<-children do fill_digraph(g,e) end end
  def fill_digraph(g,%Dotx.Node{id: id}) do :digraph.add_vertex(g,id) end
  def fill_digraph(g,%Dotx.Edge{from: %Dotx.Node{id: fromid}, to: %Dotx.Node{id: toid}}) do 
    :digraph.add_vertex(g,fromid)
    :digraph.add_vertex(g,toid)
    :digraph.add_edge(g,fromid,toid)
  end
end
