defmodule Dotx.MixProject do
  use Mix.Project

  def project do
    [
      app: :dotx,
      version: "0.2.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end
end
