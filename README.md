# Dotx

Dotx is a full feature library for DOT file parsing and generation.
The whole spec [https://www.graphviz.org/doc/info/lang.html](https://www.graphviz.org/doc/info/lang.html) is implemented.

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/dotx](https://hexdocs.pm/dotx).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `khost_topo` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dotx, "~> 0.2.0"}
  ]
end
```

## Usage

```elixir
graph = Dotx.decode(dot_string)
# now you can use graph : see `Dotx.graph()` typespec in doc for usage

dot_string = Dotx.encode(graph)
dot_string = "#{graph}"
# pretty print of graph in the dot format
# to_string() encode the graph thanks to String.Chars protocol

# You can flatten all edge shorthands of DOT : {a b}-> c -> d became
# {a b} a->c b->c b->d
flatgraph = Dotx.flatten(graph)

# You can add a unique ID for every graph and subgraph without one to allow
# easy graph property association of nodes and edges
idgraph = Dotx.identify(graph)

# You can Spread default attributes (`node [...]`, `graph [...]`, `edge [...]`
# to all edges/graphs/nodes descendants of attribute definitions
graph = Dotx.spread_attributes(graph)
```
