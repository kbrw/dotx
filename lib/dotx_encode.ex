# This file contains all code for Dotx.Graph encoding to DOT file format

defimpl String.Chars, for: Dotx.Graph do
  def indent(str, n) do
    str |> String.split("\n") |> Enum.map_join("\n", &"#{List.duplicate(" ", n)}#{&1}")
  end

  def format_id(%Dotx.HTML{html: html}) do
    # an "id" is either HTML, or alphanumeric str or quoted str
    if String.contains?(html, "\n") do
      "<\n#{indent(html, 2)}\n>"
    else
      "<" <> html <> ">"
    end
  end

  def format_id(str) when is_binary(str) do
    case Regex.run(~r"^\w+$"u, str) do
      nil -> "\"#{String.replace(str, "\"", "\\\"")}\""
      _ -> str
    end
  end

  def to_string(graph) do
    prefix = "#{if graph.strict, do: "strict "}#{graph.type}#{if graph.id, do: " " <> format_id(graph.id)}"
    parts = graph_parts(graph)
    parts_flat = Enum.map(parts, fn l when is_list(l) -> Enum.join(l, "\n"); s -> s end)
    "#{prefix} {\n\n#{parts_flat |> Enum.join("\n\n") |> indent(2)}\n\n}"
  end

  def id_width(str) do
    str |> String.split("\n", parts: 2) |> Enum.at(0) |> byte_size()
  end

  def format_attrs(attrs) when map_size(attrs) == 0 do "" end
  def format_attrs(attrs) do
    lines = attrs |> Enum.reduce([], fn {key, val}, acc ->
        key = format_id(key); val = format_id(val)
        case acc do
          [lastline | rest] = acc ->
            if byte_size(lastline) + id_width(key) + id_width(val) > 130 do
              ["#{key}=#{val}" | acc]
            else
              ["#{lastline} #{key}=#{val}" | rest]
            end
          [] ->
            ["#{key}=#{val}"]
        end
      end) |> Enum.reverse()

    if length(lines) == 1 do
      "[#{hd(lines)}]"
    else
      "[\n#{lines |> Enum.join("\n") |> indent(2)}\n]"
    end
  end

  def format_child(%Dotx.Edge{attrs: attrs, from: from, to: to, bidir: bidir}) do
    "#{format_child(from)} #{if bidir do "--" else "->" end} #{format_child(to)}" <>
      "#{if map_size(attrs) > 0 do " " <> format_attrs(attrs) end}"
  end

  def format_child(%Dotx.Node{id: id, attrs: attrs}) do
    id = Enum.map_join(id, ":", &format_id/1)
    "#{id}#{if map_size(attrs) > 0 do " " <> format_attrs(attrs) end}"
  end

  def format_child(%Dotx.SubGraph{} = graph) do
    parts = graph_parts(graph)
    prefix = if graph.id do "subgraph #{format_id(graph.id)} " end
    flat_parts = List.flatten(parts)
    if not Enum.all?(graph.children, &match?(%Dotx.Node{}, &1)) or
         Enum.any?(flat_parts, &String.contains?(&1, "\n")) or
         Enum.sum(Enum.map(flat_parts, &(byte_size(&1) + 1))) > 30 do
      # multiline subgraph (either not containing node only, or subpart is already multiline or too long
      parts_flat = Enum.map(parts, fn l when is_list(l) -> Enum.join(l, "\n"); s -> s end)
      "#{prefix}{\n#{parts_flat |> Enum.join("\n\n") |> indent(2)}\n}"
    else
      "#{prefix}{ #{List.flatten(flat_parts) |> Enum.join(" ")} }"
    end
  end

  def graph_parts(graph) do
    parts = [
      for {k, v} <- graph.attrs do
        "#{format_id(k)}=#{format_id(v)}"
      end,
      [
        if map_size(graph.nodes_attrs) > 0 do
          "node #{format_attrs(graph.nodes_attrs)}"
        end,
        if map_size(graph.edges_attrs) > 0 do
          "edge #{format_attrs(graph.edges_attrs)}"
        end,
        if map_size(graph.graphs_attrs) > 0 do
          "graph #{format_attrs(graph.graphs_attrs)}"
        end
      ] |> Enum.reject(&is_nil/1)
    ] ++ for children <- Enum.chunk_by(graph.children, & &1.__struct__) do
          for child <- children do
            format_child(child)
          end
        end
    Enum.reject(parts, &(length(&1) == 0))
  end
end
