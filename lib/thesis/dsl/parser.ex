defmodule Thesis.DSL.Parser do
  require Logger

  @parse_state %{
    steps: []
  }

  def dsl_code() do
    """
    @environment "elixir",
      version: "1.7"

    step "Basic test" do
      format "test.ex"
      help
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
    case Code.string_to_quoted(dsl, existing_atoms_only: true) do
      {:ok, quouted_form} ->
        parse_top_level(quouted_form)

      {:error, {line, error, token}} ->
        {:error, "Line #{line}: #{error}#{token}"}
    end
  end

  defp parse_top_level({:__block__, [], statements}), do: parse_top_level(statements)

  defp parse_top_level(statements),
    do: Enum.reduce(statements, @parse_state, &parse_statement(&1, &2))

  defp parse_statement(
         {:@, _meta, [{:environment, _meta2, [environment, environment_params]}]},
         state
       ) do
    env = get_environment(environment)

    Map.put(state, :environment, env)
    |> Map.put(:environment_name, environment)
    |> Map.put(:image, apply(env, :image, environment_params))
  end

  defp parse_statement({:@, _meta, [{:required_files, _meta2, file_names}]}, state),
    do: Map.put(state, :required_files, file_names)

  defp parse_statement({:step, _meta, [step_name, [do: {:__block__, [], step_params}]]}, state),
    do: parse_statement(step_name, step_params, state)

  defp parse_statement({:step, _meta, [step_name, [do: step_param]]}, state),
    do: parse_statement(step_name, [step_param], state)

  defp parse_statement(step_name, step_params, state) do
    Map.update!(
      state,
      :steps,
      &(&1 ++
          [
            %{
              name: step_name,
              commands: Enum.map(step_params, fn x -> parse_step_command(x, state) end)
            }
          ])
    )
  end

  defp parse_step_command({:command, _meta, [command | []]}, _state), do: command

  defp parse_step_command({function, [line: line], params}, state) do
    if {function, length(params || [])} in apply(state.environment, :__info__, [:functions]) do
      apply(state.environment, function, params || [])
    else
      raise "Line #{line}: no such function exists: #{function}"
    end
  end

  def get_environment(environment) do
    case environment do
      "elixir" ->
        Thesis.DSL.Elixir

      environment ->
        raise "Environment not supported: #{environment}"
    end
  end
end
