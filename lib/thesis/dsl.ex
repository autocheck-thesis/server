defmodule Thesis.DSL do
  require Logger

  @accepted_keywords [
    :__block__,
    :@,
    :configuration,
    :step,
    :command,
  ]

  def dsl_code() do
    """
    @configuration "elixir",
      version: "1.7",
      gris: 1337

    step "Basic test" do
      command "echo 'peace bruv'"
      command "echo 'eeyyyy'"
    end

    step "Advanced test" do
      command "echo 'yolo dyd'"
    end
    """
  end

  def parse_dsl_raw(dsl) do
    Code.string_to_quoted!(dsl)
  end

  def parse_dsl(dsl) do
    Code.string_to_quoted(dsl, existing_atoms_only: true)
    |> case do
      {:ok, quouted_form} ->
        parse_top_level(quouted_form)
        |> parsed_dsl_to_command()
      {:error, error} ->
        raise error
    end
  end

  defp parsed_dsl_to_command(parsed_dsl) do
    Enum.map(
      parsed_dsl,
      fn step ->
        """
        echo "Executing step: #{step.step_name}"
        #{Enum.join(step.commands, "\n")}
        """
      end
    )
    |> Enum.join("\n")
  end

  defp parse_top_level({:__block__, [], statements}), do: Enum.map(statements, &(parse_statement(&1)))
  defp parse_top_level(test),                         do: [parse_statement(test)]

  # defp parse_statement({:reqf, _line, required_files}), do: required_files

  defp parse_statement({:step, _line, [step_name, [do: {:__block__, [], step_params}]]}), do: %{step_name: step_name, commands: Enum.map(step_params, &(parse_step_command(&1)))}
  defp parse_statement({:step, _line, [step_name, [do: step_param]]}),                    do: %{step_name: step_name, commands: [parse_step_command(step_param)]}

  defp parse_step_command({:command, _line, [command | []]}), do: command
  defp parse_step_command(_whatever),                         do: :todo # TODO: Implement "this keyword on line bla bla is not supported"
end
