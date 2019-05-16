defmodule Thesis.Configuration.Parser do
  defmodule Error do
    @derive Jason.Encoder
    @enforce_keys [:line, :description, :token]
    defstruct [:line, :description, :token]
  end

  alias Thesis.Configuration.Parser

  defstruct image: nil,
            environment: nil,
            required_files: [],
            mime_types: [],
            steps: [],
            errors: []

  def parse_dsl_raw(dsl) do
    Code.string_to_quoted!(dsl)
  end

  def parse(configuration_code) do
    case Code.string_to_quoted(configuration_code, existing_atoms_only: true) do
      {:ok, quouted_form} ->
        {:ok, parse_top_level(quouted_form)}

      {:error, {line, description, token}} ->
        {:error, %Error{line: line, description: description, token: token}}
    end
  end

  def parse!(configuration_code) do
    case parse(configuration_code) do
      {:ok, configuration} ->
        configuration

      {:error, error} ->
        raise error
    end
  end

  defp parse_top_level({:__block__, [], statements}), do: parse_top_level(statements)

  defp parse_top_level(statements),
    do: Enum.reduce(statements, %Parser{}, &parse_statement(&1, &2))

  defp parse_statement(
         {:@, _meta, [{:environment, line, [environment, environment_params]}]},
         %Parser{} = p
       ) do
    case get_environment_module(environment) do
      {:ok, environment_module} ->
        image = apply(environment_module, :image, environment_params)
        %{p | environment: environment_module, image: image}

      :error ->
        error = %Error{line: line, description: "environment does not exist", token: environment}
        %{p | errors: [error | p.errors]}
    end
  end

  defp parse_statement({:@, _meta, [{:required_files, _meta2, file_names}]}, %Parser{} = p),
    do: %{p | required_files: file_names}

  defp parse_statement({:step, _meta, [step_name, [do: {:__block__, [], step_params}]]}, state),
    do: parse_statement(step_name, step_params, state)

  defp parse_statement({:step, _meta, [step_name, [do: step_param]]}, state),
    do: parse_statement(step_name, [step_param], state)

  defp parse_statement(step_name, step_params, %Parser{} = p) do
    commands =
      Enum.map(step_params, fn x -> parse_step_command(x, p) end)
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))

    case commands do
      %{error: errors, ok: commands} ->
        %{
          p
          | steps: [%{name: step_name, commands: commands} | p.steps],
            errors: p.errors ++ errors
        }

      %{ok: commands} ->
        %{p | steps: [%{name: step_name, commands: commands} | p.steps]}

      %{error: errors} ->
        %{p | errors: p.errors ++ commands.error}
    end
  end

  defp parse_step_command({:command, _meta, [command | []]}, _p), do: {:ok, command}

  defp parse_step_command({function, [line: line], params}, %Parser{} = p) do
    if {function, length(params || [])} in apply(p.environment, :__info__, [:functions]) do
      {:ok, apply(p.environment, function, params || [])}
    else
      {:error, %Error{line: line, description: "undefined function", token: function}}
    end
  end

  def get_environment_module(environment) do
    case environment do
      "elixir" ->
        {:ok, Thesis.Configuration.Elixir}

      _ ->
        :error
    end
  end
end
