defmodule DotxTest do
  use ExUnit.Case

  setup_all do
    File.mkdir("test/examples_out")
    :ok
  end

  for dot_path <- Path.wildcard("test/examples/*.dot") do
    test "check parsing/encoding bijection for #{Path.basename(dot_path)}" do
      parsed = Dotx.decode(File.read!(unquote(dot_path)))
      # same as to_string(parsed) or Dotx.encode(parsed)
      dot = "#{parsed}"
      File.write!("test/examples_out/#{Path.basename(unquote(dot_path))}", dot)
      assert parsed == Dotx.decode(dot)
    end
  end

  #  test "test attribute spread for ex8.dot" do
  #    graph = Dotx.decode(File.read!("test/examples/ex8.dot"))
  #    #IO.inspect graph, pretty: true
  #    graph = Dotx.spread_attributes(graph)
  #    IO.inspect graph, pretty: true
  #    #IO.inspect Dotx.nodes(graph), pretty: true
  #    #assert parsed == Dotx.decode(dot)
  #  end
end
