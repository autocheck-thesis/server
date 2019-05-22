defmodule Thesis.Configuration.Parser do
  defmodule Error do
    @derive Jason.Encoder
    @enforce_keys [:line, :description, :token]
    defstruct [:line, :description, :token, description_suffix: ""]
  end

  alias Thesis.Configuration.Parser

  defstruct image: nil,
            environment: nil,
            required_files: [],
            allowed_file_extensions: [],
            steps: [],
            errors: []

  # {name, arity}
  @built_in_functions [
    {:command, 1}
  ]

  @keywords [
    :@,
    :step
  ]

  @fields [
    :env,
    :required_files,
    :allowed_file_extensions
  ]

  @environments %{
    "elixir" => Thesis.Configuration.Elixir
  }

  def parse_dsl_raw(dsl) do
    Code.string_to_quoted!(dsl)
  end

  def parse(configuration_code) do
    # Opts "existing_atoms_only" would make this function call safe, but also removes
    # the possiblity of descriptive error messages.
    case Code.string_to_quoted(configuration_code) do
      {:ok, quouted_form} ->
        {:ok, parse_top_level(quouted_form)}

      {:error, {line, {description_prefix, description_suffix}, token}} ->
        {:error,
         %Error{
           line: line,
           description: description_prefix,
           token: token,
           description_suffix: description_suffix
         }}

      {:error, {line, description, token}} ->
        {:error, %Error{line: line, description: description |> String.trim(), token: token}}
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

  defp parse_top_level(statement) when not is_list(statement), do: parse_top_level([statement])

  defp parse_top_level(statements),
    do: Enum.reduce(statements, %Parser{}, &parse_statement(&1, &2))

  defp parse_statement(
         {:@, _meta, [{:env, [line: line], [environment, environment_params]}]},
         %Parser{} = p
       ) do
    case Map.get(@environments, environment, :undefined) do
      :undefined ->
        suggestion = suggest_similar_environment(environment)
        add_error(p, line, "environment is not defined: ", environment, suggestion)

      environment_module ->
        image = apply(environment_module, :image, environment_params)
        %{p | environment: environment_module, image: image}
    end
  end

  defp parse_statement({:@, _meta, [{:required_files, _meta2, file_names}]}, %Parser{} = p),
    do: %{p | required_files: file_names}

  defp parse_statement(
         {:@, _meta, [{:allowed_file_extensions, [line: line], allowed_file_extensions}]},
         %Parser{} = p
       ) do
    case Enum.reject(allowed_file_extensions, fn ext ->
           is_binary(ext) and String.match?(ext, ~r/^\.(\w|\d)+$/)
         end) do
      [] ->
        %{p | allowed_file_extensions: allowed_file_extensions}

      badargs ->
        Enum.reduce(
          badargs,
          p,
          &add_error(
            &2,
            line,
            "Invalid file extension: ",
            &1,
            "A file extension must start with a dot and not contain any special characters."
          )
        )
    end
  end

  defp parse_statement({:@, _meta, [{unsupported_field, [line: line], _params}]}, %Parser{} = p) do
    suggestion = suggest_similar_field(unsupported_field)
    add_error(p, line, "incorrect field: ", unsupported_field, suggestion)
  end

  defp parse_statement({:step, _meta, [step_name, [do: {:__block__, [], step_params}]]}, state),
    do: parse_statement(step_name, step_params, state)

  defp parse_statement({:step, _meta, [step_name, [do: step_param]]}, state),
    do: parse_statement(step_name, [step_param], state)

  defp parse_statement({keyword, [line: line], _params}, %Parser{} = p) do
    suggestion = suggest_similar_keyword(keyword)
    add_error(p, line, "incorrect keyword: ", keyword, suggestion)
  end

  defp parse_statement(step_name, step_params, %Parser{} = p) do
    commands =
      Enum.map(step_params, fn x -> parse_step_command(x, p) end)
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))

    case commands do
      %{error: errors, ok: commands} ->
        %{
          p
          | steps: p.steps ++ [%{name: step_name, commands: commands}],
            errors: p.errors ++ errors
        }

      %{ok: commands} ->
        %{p | steps: p.steps ++ [%{name: step_name, commands: commands}]}

      %{error: errors} ->
        %{p | errors: p.errors ++ errors}
    end
  end

  defp parse_step_command({:command, _meta, [command | []]}, _p), do: {:ok, command}

  defp parse_step_command({function, [line: line], _params}, %Parser{environment: nil}) do
    {:error, %Error{line: line, description: "undefined function: ", token: function}}
  end

  defp parse_step_command({function, [line: line], params}, %Parser{} = p) do
    imported_functions = apply(p.environment, :__info__, [:functions])

    cond do
      {function, length(params || [])} in imported_functions ->
        {:ok, apply(p.environment, function, params || [])}

      Keyword.has_key?(imported_functions, function) ->
        {:error,
         %Error{
           line: line,
           description: "incorrect amount of parameters for function: ",
           token: Atom.to_string(function) <> "/#{Keyword.fetch!(imported_functions, function)}",
           description_suffix: ""
         }}

      true ->
        suggestion = suggest_similar_function(function, imported_functions)

        {:error,
         %Error{
           line: line,
           description: "undefined function: ",
           token: function,
           description_suffix: suggestion
         }}
    end
  end

  defp suggest_similar_environment(environment) do
    Map.keys(@environments)
    |> find_suggestion(environment)
  end

  defp suggest_similar_keyword(keyword) do
    @keywords
    |> Enum.map(fn k -> to_string(k) end)
    |> find_suggestion(to_string(keyword))
  end

  defp suggest_similar_field(field) do
    @fields
    |> Enum.map(fn f -> to_string(f) end)
    |> find_suggestion(to_string(field))
  end

  defp suggest_similar_function(function, functions) do
    (@built_in_functions ++ functions)
    |> Enum.map(fn {fun, _arity} -> to_string(fun) end)
    |> find_suggestion(to_string(function))
  end

  defp find_suggestion(strs, str) do
    strs
    |> Enum.map(fn s -> {s, String.jaro_distance(s, str)} end)
    |> Enum.filter(fn {_s, distance} -> distance > 0.8 end)
    |> Enum.max_by(fn {_s, distance} -> distance end, fn -> :no_similar end)
    |> case do
      :no_similar -> ""
      {s, _distance} -> "Did you mean #{s}?"
    end
  end

  defp add_error(parser, line, description, token, description_suffix)
       when is_list(token) or is_tuple(token),
       do: %{
         parser
         | errors:
             parser.errors ++
               [
                 %Error{
                   line: line,
                   description: description,
                   token: "[unsafe, can't render]",
                   description_suffix: description_suffix
                 }
               ]
       }

  defp add_error(parser, line, description, token, description_suffix),
    do: %{
      parser
      | errors:
          parser.errors ++
            [
              %Error{
                line: line,
                description: description,
                token: token,
                description_suffix: description_suffix
              }
            ]
    }
end
