defmodule Thesis.DSL.Elixir do
  def image({:version, version}) do
    "elixir:#{version}-alpine"
  end

  def format(file) do
    "mix format #{file}"
  end

  def help() do
    "mix help"
  end
end
