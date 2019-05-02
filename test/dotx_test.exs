defmodule DotxTest do
  use ExUnit.Case

  setup_all do
    File.mkdir("test/examples_out")
    :ok
  end

  for dot_path <- Path.wildcard("test/examples/*.dot") do
    test "check parsing/encoding bijection for #{Path.basename(dot_path)}" do
      parsed = Dotx.decode!(File.read!(unquote(dot_path)))
      # same as to_string(parsed) or Dotx.encode(parsed)
      dot = "#{parsed}"
      File.write!("test/examples_out/#{Path.basename(unquote(dot_path))}", dot)
      assert parsed == Dotx.decode!(dot)
    end
  end

  test "test parse errors" do
    # lexer
    assert_raise ArgumentError, ~r/illegal characters/, fn ->
      Dotx.decode!("digraph €")
    end
    # parser
    assert_raise ArgumentError, ~r/syntax error/, fn ->
      Dotx.decode!("digraph { -> }")
    end
  end

  test "test flatten" do
    graph = Dotx.flatten(Dotx.decode!(
      "digraph D { A -> { B C D } -> { F D } }"))
    edges = for %Dotx.Edge{from: %{id: [from]},to: %{id: [to]}}<-graph.children do
      [from,to]
    end
    assert edges == [["A","B"],["A","C"],["A","D"],
                     ["B","F"],["B","D"],["C","F"],
                     ["C","D"],["D","F"],["D","D"]]
  end

  test "test identify" do
    graph = Dotx.identify(Dotx.decode!(
      "digraph { A -> { B C D } -> { F D } }"))
    dot =  "#{graph}"
    assert String.contains?(dot, "digraph x0")
    assert String.contains?(dot, "subgraph x1")
    assert String.contains?(dot, "subgraph x2")
  end

  #test "test attribute spread for ex8.dot" do
  #  graph = Dotx.decode!(File.read!("test/examples/ex8.dot"))
  #  #IO.inspect graph, pretty: true
  #  graph = Dotx.spread_attributes(graph)
  #  IO.puts graph
  #  #IO.inspect Dotx.nodes(graph), pretty: true
  #  #assert parsed == Dotx.decode(dot)
  #end
end
