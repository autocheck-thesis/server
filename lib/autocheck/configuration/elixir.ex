defmodule Autocheck.Configuration.Elixir do
  def image({:version, version}) when is_binary(version) or is_number(version) do
    {:ok, "elixir:#{version}-alpine"}
  end

  def image({:version, version}) do
    {:error, "unsupported image version: ", version}
  end

  def image({badarg, _}) do
    {:error, "incorrect parameter: ", badarg}
  end

  def image(_) do
    {:error, "syntax error", ""}
  end

  def format(file) do
    {:ok, ["run", ["mix format #{file}"]]}
  end

  def help() do
    {:ok, ["run", ["mix help"]]}
  end

  def create_project(name) do
    {:ok,
     [
       "run",
       [
         """
         mix new #{name}
         rm #{name}/lib/*.ex #{name}/test/*_test.ex
         """
       ]
     ]}
  end

  def test(project) do
    {:ok,
     [
       "run",
       [
         """
         cd #{project}
         mix test
         """
       ]
     ]}
  end
end
