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

  test "test to_nodes data conversion" do
    g = """
      digraph { 
        ga = 1
        graph [gb = 2]
        node [z=z] 
        edge [ea = 1]
        A [a=1]
        { 
          {
            node [b=2] 
            { gc = 3 B [d=3] } 
            B -> A -> D [eb = 2]
          } 
        } 
        C 
      }
    """
    {nodes,graphs} = Dotx.to_nodes(Dotx.decode!(g))
    assert %{attrs: %{"graph"=>"x2","a"=>"1","b"=>"2","z"=>"z", "edges_from"=> [
          %{to: %{id: ["D"]},attrs: %{"graph"=> "x2", "ea"=>"1", "eb"=>"2"}}
        ]}} = nodes[["A"]]
    assert %{attrs: %{"graph"=>"x3","b"=>"2","d"=>"3","z"=>"z", "edges_from"=> [
          %{to: %{id: ["A"]},attrs: %{"graph"=> "x2", "ea"=>"1", "eb"=>"2"}}
        ]}} = nodes[["B"]]
    assert %{attrs: %{"graph"=>"x0","z"=>"z"}} =
              nodes[["C"]]
    assert %{attrs: %{"gc"=>"3", "gb"=>"2","parent"=>"x2"}} = graphs["x3"]
  end

  test "test to_edges data conversion" do
    g = """
      digraph { 
        ga = 1
        graph [gb = 2]
        node [z=z] 
        edge [ea = 1]
        A [a=1]
        {
          {
            node [b=2] 
            { gc = 3 B [d=3] }
            B -> A -> D [eb = 2]
          }
        }
        C 
      }
    """
    {edges,_graphs} = Dotx.to_edges(Dotx.decode!(g))
    edges = Enum.sort_by(edges,& {&1.from.id,&1.to.id})
    assert [
        %{from: %{ attrs: %{"b"=> "2","graph"=>"x2"}, id: ["A"]}, to: %{ id: ["D"]}},
        %{from: %{ attrs: %{"d"=> "3","graph"=>"x3"}, id: ["B"]}, to: %{ id: ["A"]}, attrs: %{"graph"=>"x2"}}
      ] = edges
  end

  test "test digraph" do
    g = """
      digraph { 
        a e f
        a->b
        a->b->{c d}->{e f}->g
        { c->a f->b }
      }
    """
    g = Dotx.to_digraph(Dotx.decode!(g))
    assert ["a", "b", "c", "d", "e", "f", "g"] ==
              Enum.sort(for [x]<-:digraph.vertices(g) do x end)
    assert Enum.sort(for e<-:digraph.edges(g) do {_,[f],[t],_} = :digraph.edge(g,e); {f,t} end) == 
      [{"a","b"},{"a","b"},
       {"b","c"},{"b","d"},
       {"c","a"},{"c","e"},{"c","f"},
       {"d","e"},{"d","f"},
       {"e","g"},
       {"f","b"},{"f","g"}]
  end
end
