defmodule Autocheck.Configuration.Parser do
  defmodule Error do
    @derive Jason.Encoder
    @enforce_keys [:line, :description, :token]
    defstruct [:line, :description, :token, description_suffix: ""]
  end

  alias Autocheck.Configuration.Parser

  defstruct image: nil,
            environment: nil,
            required_files: [],
            allowed_file_extensions: [],
            steps: [],
            errors: []

  # {name, arity}

  @built_in_functions [:run, :print]
  @built_in_functions_with_arity [
    {:run, 1},
    {:print, 1}
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
    "custom" => Autocheck.Configuration.Custom,
    "elixir" => Autocheck.Configuration.Elixir,
    "java" => Autocheck.Configuration.Java
  }

  def parse_dsl_raw(dsl) do
    Code.string_to_quoted!(dsl)
  end

  def parse(configuration_code) do
    # Opts "existing_atoms_only" would make this function call safe, but also removes
    # the possiblity of descriptive error messages.
    case Code.string_to_quoted(configuration_code) do
      {:ok, quouted_form} ->
        case parse_top_level(quouted_form) do
          %Parser{errors: []} = parser ->
            {:ok, parser}

          %Parser{errors: errors} ->
            {:error, errors}
        end

      {:error, {line, {description_prefix, description_suffix}, token}} ->
        {:error,
         [
           %Error{
             line: line,
             description: description_prefix,
             token: token,
             description_suffix: description_suffix
           }
         ]}

      {:error, {line, description, token}} ->
        {:error, [%Error{line: line, description: description |> String.trim(), token: token}]}
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

  # Multiple top level statements
  defp parse_top_level({:__block__, [], statements}), do: parse_top_level(statements)

  # One top level statement
  defp parse_top_level(statement) when not is_list(statement), do: parse_top_level([statement])

  defp parse_top_level(statements),
    do: Enum.reduce(statements, %Parser{}, &parse_statement(&1, &2))

  # Environment (env) field
  defp parse_statement(
         {:@, _meta, [{:env, [line: line], params}]},
         %Parser{} = p
       ) do
    case params do
      [name, params] when is_list(params) ->
        parse_environment_field(name, params, line, p)

      [name] ->
        parse_environment_field(name, [], line, p)

      [] ->
        add_error(p, line, "missing environment name", "", "")

      _ ->
        add_error(p, line, "syntax error", "", "")
    end
  end

  defp parse_environment_field(environment, environment_params, line, %Parser{} = p) do
    case Map.get(@environments, environment, :undefined) do
      :undefined ->
        suggestion = suggest_similar_environment(environment)
        add_error(p, line, "environment is not defined: ", environment, suggestion)

      environment_module ->
        image_param_counts =
          apply(environment_module, :__info__, [:functions])
          |> Keyword.get_values(:image)

        param_count = length(environment_params)

        if param_count in image_param_counts do
          case apply(environment_module, :image, environment_params) do
            {:ok, image} -> %{p | environment: environment_module, image: image}
            {:error, description, token} -> add_error(p, line, description, token, "")
          end
        else
          add_error(p, line, "incorrect number of parameters for env: ", environment, "")
        end
    end
  end

  # Required files field
  defp parse_statement({:@, _meta, [{:required_files, _meta2, file_names}]}, %Parser{} = p),
    do: %{p | required_files: file_names}

  # Allowed file extensions field
  defp parse_statement(
         {:@, _meta, [{:allowed_file_extensions, [line: line], allowed_file_extensions}]},
         %Parser{} = p
       ) do
    case Enum.reject(allowed_file_extensions, fn ext ->
           is_binary(ext) and String.match?(ext, ~r/^(\.\w+)+$/)
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

  # Invalid field syntax
  defp parse_statement({:@, _meta, [{_, [line: line], params}]}, %Parser{} = p)
       when length(params) > 2,
       do: add_error(p, line, "syntax error", "", "")

  # Unsupported field
  defp parse_statement({:@, _meta, [{unsupported_field, [line: line], _params}]}, %Parser{} = p) do
    suggestion = suggest_similar_field(unsupported_field)
    add_error(p, line, "incorrect field: ", unsupported_field, suggestion)
  end

  # Empty step
  defp parse_statement({:step, _meta, [_step_name, [do: {:__block__, [], []}]]}, state),
    do: state

  # Step with multiple params
  defp parse_statement({:step, _meta, [step_name, [do: {:__block__, [], step_params}]]}, state),
    do: parse_statement(step_name, step_params, state)

  # Step with one param
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

  defp parse_step_command({key, _meta, params}, _p) when key in @built_in_functions,
    do: {:ok, [key, params]}

  defp parse_step_command({function, [line: line], _params}, %Parser{environment: nil}) do
    {:error, create_error(line, "undefined function: ", function, "")}
  end

  defp parse_step_command({function, [line: line], params}, %Parser{} = p) do
    imported_functions = apply(p.environment, :__info__, [:functions])

    cond do
      {function, length(params || [])} in imported_functions ->
        case apply(p.environment, function, params || []) do
          {:ok, _} = result -> result
          {:error, description, token} -> {:error, create_error(line, description, token, "")}
        end

      Keyword.has_key?(imported_functions, function) ->
        {:error,
         create_error(
           line,
           "incorrect amount of paramters for function: ",
           Atom.to_string(function) <> "/#{Keyword.fetch!(imported_functions, function)}",
           ""
         )}

      true ->
        suggestion = suggest_similar_function(function, imported_functions)

        {:error, create_error(line, "undefined function: ", function, suggestion)}
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
    (@built_in_functions_with_arity ++ functions)
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

  defp add_error(parser, %Error{} = error), do: %{parser | errors: parser.errors ++ [error]}

  defp add_error(parser, line, description, token, description_suffix)
       when is_list(token) or is_tuple(token),
       do:
         add_error(
           parser,
           create_error(line, description, "[unsafe, can't render]", description_suffix)
         )

  defp add_error(parser, line, description, token, description_suffix),
    do: add_error(parser, create_error(line, description, token, description_suffix))

  defp create_error(line, description, token, description_suffix),
    do: %Error{
      line: line,
      description: description,
      token: token,
      description_suffix: description_suffix
    }
end
