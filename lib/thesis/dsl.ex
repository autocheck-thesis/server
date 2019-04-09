defmodule Thesis.DSL do
  require Logger

  def dsl_code() do
    """
    reqf "hello.py"

    test "Basic test" do
      dir "/tmp/foobar"
      cmd "java $af"
      test_source "blablabla"
      xd(dode)
    end

    test "Advanced test" do
      exptect_exit_code 1, 4, "17"
    end
    """
  end

  def parse_dsl_raw(dsl) do
    Code.string_to_quoted!(dsl)
  end

  def parse_dsl(dsl) do
    Code.string_to_quoted(dsl, existing_atoms_only: false)
    |> case do
      {:ok, quouted_form} ->
        parse_top_level(quouted_form)
        |> List.flatten
        |> List.foldl(%{}, fn x, acc -> if is_tuple(x) do Map.put(acc, :cmd, elem(x, 1)) else acc end end) #TODO: Jesus..
      {:error, error} ->
        Logger.error(error)
    end
  end

  defp parse_top_level({:__block__, [], statements}), do: Enum.map(statements, &(parse_statement(&1)))
  defp parse_top_level(test), do: [parse_statement(test)]

  defp parse_statement({:reqf, _line, required_files}), do: required_files
  defp parse_statement({:test, _line, [_test_name, [do: {:__block__, [], test_params}]]}), do: Enum.map(test_params, &(parse_test_param(&1)))
  defp parse_statement({:test, _line, [_test_name, [do: test_param]]}), do: [parse_test_param(test_param)]

  defp parse_test_param({:cmd, _line, [cmd | []]}), do: {:cmd, cmd}
  defp parse_test_param(_whatever), do: :todo
end
