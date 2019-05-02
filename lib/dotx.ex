defmodule Dotx do
  @type graph :: %Dotx.Graph{
          strict: boolean,
          type: :graph | :digraph,
          id: nil | id,
          attrs: %{optional(id) => id},
          nodes_attrs: %{optional(id) => id},
          edges_attrs: %{optional(id) => id},
          graphs_attrs: %{optional(id) => id},
          children: [Dotx.Node.t() | Dotx.Edge.t() | Dotx.SubGraph.t()]
        }
  @type id :: binary | %Dotx.HTML{html: binary}
  @type t :: %Dotx.SubGraph{
          id: nil | id,
          attrs: %{optional(id) => id},
          nodes_attrs: %{optional(id) => id},
          edges_attrs: %{optional(id) => id},
          graphs_attrs: %{optional(id) => id},
          children: [Dotx.Node.t() | Dotx.Edge.t() | Dotx.SubGraph.t()]
        }
  def encode(graph) do
    to_string(graph)
  end

  def decode(bin) do
    Dotx.Graph.parse(bin)
  end

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

  #def nodes(%{children: children, nodes_attrs: inherit_attrs}=graph) do
  #  curr_nodes = for %Dotx.Node{}=n<-children do 
  #    {%{n|attrs: Map.merge(inherit_attrs,n.attrs)},[%{graph|children: []}]}
  #  end
  #  Enum.reduce(for %Dotx.SubGraph{}=g<-children do g end,curr_nodes, fn subgraph,curr_nodes->
  #    sub_nodes = nodes(subgraph)
  #    Enum.reduce(sub_nodes,curr_nodes,fn {%{id: subid,attrs: subattrs}=sub_node,subgraphs},curr_nodes->
  #      case Enum.find_index(curr_nodes,fn {%{id: id},_}-> id == subid end) do
  #        nil-> curr_nodes ++ [{%{sub_node|attrs: Map.merge(inherit_attrs,subattrs)},subgraphs}]
  #        idx-> List.update_at(curr_nodes,idx, fn {curr_node,curr_graph}->
  #          {%{curr_node| attrs: Map.merge(curr_node.attrs,subattrs)},subgraphs ++ curr_graph}
  #        end)
  #      end
  #    end)
  #  end)
  #end
  #def edges(graph) do {edges,_} = edges(graph,%{}); Enum.reverse(edges) end
  #def edges(parent,nodeattrs) do
  #  Enum.reduce(parent.children,{[],nodeattrs},fn
  #    %Dotx.Edge{from: from, to: to}=e,{edges,nodeattrs}-> 
  #      listwrap = fn
  #        %Dotx.SubGraph{nodes_attrs}=g-> for %Dotx.Node(}=n<-g.children do n end
  #        %Dotx.Node{}=n-> [n]
  #      end
  #      for from<-listwrap.(from), to<-listwrap.(to) do
  #        %{e|from: %{from|attrs: Map.merge(parent.nodes_attrs,from.attrs}, 
  #            to: %{to|attrs: Map.merge(parent.nodes_attrs,to.attrs}}
  #      end
  #      e = %{e|attrs: Map.merge(parent.edges_attrs,e.attrs)}
  #      {[%{e|from: ,
  #            to: ,
  #            attrs: Map.merge(parent.edges_attrs,e.attrs)}|edges],nodeattrs}
  #    %Dotx.Edge{from: %Dotx.SubGraph{}=from, to: %Dotx.Node{}=to}=e,{edges,nodeattrs}-> 
  #      {[%{e|from: %{from|attrs: Map.merge(parent.nodes_attrs,from.attrs},
  #            to: %{to|attrs: Map.merge(parent.nodes_attrs,to.attrs},
  #            attrs: Map.merge(parent.edges_attrs,e.attrs)}|edges],nodeattrs}
  #    %Dotx.Node{}=n,{edges,nodeattrs}-> 
  #     {edges,Map.update(nodeattrs,n.id,n.attrs,&Map.merge(&1,Map.merge(parent.nodes_attrs,n.attrs)))}
  #    %Dotx.SubGraph{}=g,{edges,nodeattrs}->
  #      {subedges,nodeattrs} = 
  #        edges(%{g|edges_attrs: Map.merge(parent.edges_attrs,g.edges_attrs),
  #                  nodes_attrs: Map.merge(parent.nodes_attrs,g.nodes_attrs),
  #                  graphs_attrs: Map.merge(parent.nodes_attrs,g.nodes_attrs)},nodeattrs)
  #      {subedges++edges,nodeattrs}
  #  end)
  #end
end
