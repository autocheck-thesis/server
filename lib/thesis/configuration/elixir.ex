defmodule Thesis.Configuration.Elixir do
  def image({:version, version}) do
    "elixir:#{version}-alpine"
  end

  def format(file) do
    "mix format #{file}"
  end

  def help() do
    "mix help"
  end

  def create_project(name) do
    """
    mix new #{name}
    rm #{name}/lib/*.ex #{name}/test/*_test.ex
    """
  end

  def test(project) do
    """
    cd #{project}
    mix test
    """
  end
end
