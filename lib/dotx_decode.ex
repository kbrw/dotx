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

  def flatten(edge) do do_flatten(edge,false) end

  # do_flatten: a->b->c becomes a->b b->c
  def do_flatten(%__MODULE__{from: from,to: %__MODULE__{from: to} = toedge, attrs: attrs} = edge,nested?) do
    do_flatten2(edge,from,to,nested?) ++ do_flatten(%{toedge | attrs: attrs}, true)
  end
  def do_flatten(%__MODULE__{from: from, to: to} = edge, nested?) do 
    do_flatten2(edge,from,to,nested?)
  end

  # do_flatten2: {a b}->{c d} becomes {a b} {c d} a->c a->d b->c b->d
  def do_flatten2(edge,from,to,nested?) do
    case {from,to} do
      {%Dotx.Node{},%Dotx.Node{}}-> [%{edge| from: from, to: to}]
      {%Dotx.SubGraph{}=g,%Dotx.Node{}=n}->
        if nested? do [] else [g] end ++ 
          for %Dotx.Node{}=from<-g.children do %{edge|from: from} end
      {%Dotx.Node{}=n,%Dotx.SubGraph{}=g}->
        [g| for %Dotx.Node{}=to<-g.children do %{edge|to: to} end]
      {%Dotx.SubGraph{}=gfrom,%Dotx.SubGraph{}=gto}->
        if nested? do [] else [gfrom] end ++ [gto] ++
          for %Dotx.Node{}=from<-gfrom.children, 
              %Dotx.Node{}=to<-gto.children do %{edge|from: from, to: to} end
    end
  end
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
