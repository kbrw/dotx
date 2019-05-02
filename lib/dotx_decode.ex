# DOT file parsing is done with leex and yecc `src/dot_(lexer.xrl|parser.yrl)`
# This file contains all additional code for parsing 
#  - entry point Dotx.Graph.parse which precompute the file before leex and yecc
#  - different structs models used by the yecc parser
#  - additional functions used by `dot_parser` in order to flatten the dot structure to make it more usable

defmodule Dotx.Graph do
  defstruct strict: false, type: :graph, id: nil, children: [], attrs: %{}, nodes_attrs: %{}, graphs_attrs: %{}, edges_attrs: %{}

  def parse(bin) do
    # tricks : 
    # - since recursive regex is not implemented in leex lexer, replace
    #   <> by \x1e (record separator control char) to make it easy for leex to tokenize html "id"
    # - since ungreedy regex are not implemented in leex lexer, remove multiline c comment
    bin =
      bin
      |> String.replace(~r"<(([^<>]|(?R))*)>", "\x1e\\1\x1e")
      |> String.replace(~r"/\*.*\*/"sU, "")
    case :dot_lexer.string(to_charlist(bin)) do
      {:ok, tokens, _} ->
        case :dot_parser.parse(tokens) do
          {:ok, tree} -> tree
          error -> error
        end
      error -> error
    end
  end

  def childattrs2fields(%{children: children} = graph) do
    graph =
      Enum.reduce(children, %{graph | children: []}, fn
        {:graph, attrs}, graph -> %{graph | graphs_attrs: Enum.into(attrs, graph.graphs_attrs)}
        {:edge, attrs}, graph -> %{graph | edges_attrs: Enum.into(attrs, graph.edges_attrs)}
        {:node, attrs}, graph -> %{graph | nodes_attrs: Enum.into(attrs, graph.nodes_attrs)}
        {key, val}, graph -> %{graph | attrs: Map.put(graph.attrs, key, val)}
        node_edge_subgraph, graph -> %{graph | children: [node_edge_subgraph | graph.children]}
      end)
    %{graph | children: Enum.reverse(graph.children)}
  end
end

defmodule Dotx.SubGraph do
  defstruct id: nil, children: [], attrs: %{}, nodes_attrs: %{}, graphs_attrs: %{}, edges_attrs: %{}
end

defmodule Dotx.Node do
  defstruct id: [], attrs: %{}
end

defmodule Dotx.Edge do
  defstruct from: [], to: [], attrs: %{}, bidir: true

  def flatten(edge) do
    #Enum.flat_map(do_flat_inline(edge),&do_flat_subgraph(&1))
    do_flat_inline(edge)
  end
  def flatten(%__MODULE__{from: from,to: %__MODULE__{from: to} = toedge, attrs: attrs} = edge) do
    do_flat(toedge,from,to,true) ++ flatten(%{toedge | attrs: attrs})
  end
  def flatten(%__MODULE__{from: from, to: to} = edge) do 
    do_flat(edge,from,to,false)
  end

  def do_flat(edge,from,to,nested?) do
    {from_subgraph,from_nodes}=split_graph_nodes(from)
    {to_subgraph,to_nodes}=split_graph_nodes(to)
    # if piped edge (a -> {b c} -> d) then nested? = true : subgraph already added
    List.wrap(if not(nested?) do from_subgraph end)++to_subgraph++
        for from<-from_nodes, to<-to_nodes do %{edge| from: from, to: to} end
  end

  defp split_graph_nodes(%Dotx.SubGraph{}=g), do:
    {[g], for %Dotx.Node{}=n<-g.children do n end}
  defp split_graph_nodes(%Dotx.Node{}=n), do:
    {[], [n]}

  #def do_flat_subgraph(%__MODULE__{from: from, to: to}=e) do
  #  subcheck = fn 
  #    %Dotx.SubGraph{}=g->  {[g], for %Dotx.Node{}=n<-g.children do n end}
  #    %Dotx.Node{}=n->  {[], [n]}
  #  end
  #  {from_subgraph,from_nodes}=subcheck.(from); {to_subgraph,to_nodes}=subcheck.(to)
  #  from_subgraph ++ to_subgraph ++ for from<-from_nodes, to<-to_nodes do
  #    %{e|from: from, to: to}
  #  end
  #end
end

defmodule Dotx.HTML do
  defstruct html: ""

  def trim(%{html: html} = doc) do
    # if html, can be multiline... so remove any existing indentation
    html = String.trim_trailing(html)
    html = case String.split(html, "\n", trim: true) do
        [_] -> html # single line
        lines ->
          case :binary.longest_common_prefix(lines) do
            0 -> html # multi line, but no common prefix
            bytes ->
              <<prefix::binary-size(bytes)>> <> _ = html
              case Regex.run(~r"^\s+$", prefix) do
                nil -> html # common prefix is not blank
                # there is a common prefix for all lines containing only blank chars : remove them
                _ ->
                  Enum.map_join(lines, "\n", fn <<_::binary-size(bytes)>> <> rest -> rest; o -> o end)
              end
          end
      end
    %{doc | html: html}
  end
end
