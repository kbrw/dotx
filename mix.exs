defmodule Dotx.MixProject do
  use Mix.Project

  def project do
    [
      app: :dotx,
      version: "0.2.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      name: "Dotx Elixir dot parser",
      package: [
        description: """
          Dotx is a full feature library for DOT file parsing and generation.
          The whole spec [https://www.graphviz.org/doc/info/lang.html](https://www.graphviz.org/doc/info/lang.html) is implemented.
          """,
        links: %{repo: "https://github.com/kbrw/dotx", doc: "https://hexdocs.pm/dotx"},
        licenses: ["MIT"],
      ],
      source_url: "https://github.com/kbrw/dotx",
      docs: [main: "Dotx"],
      deps: [
        {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end
end
