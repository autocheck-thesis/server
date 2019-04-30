defmodule Thesis.EnvironmentDSL do
  @parse_state %{
    name: "",
    image: "",
    functions: %{}
  }

  def dsl_code() do
    """
    @name "elixir"
    @image "elixir:{version}-alpine-{gris}"

    def format_code(file, whatever) do
     command "mix format {file}"
     command "test"
    end 
    """
  end

  def import_environment(environment, environment_params) do
    case Thesis.Repo.get_by(Thesis.Environment, name: environment) do
      environment ->
        parse_dsl(environment.dsl, environment_params)

      nil ->
        {:error, "Invalid environment name"}
    end
  end

  def parse_dsl(dsl, params) do
    case Code.string_to_quoted(dsl) do
      {:ok, quouted_form} ->
        parse_top_level(
          quouted_form,
          @parse_state |> Map.put(:environment_params, params)
        )

      {:error, error} ->
        raise error
    end
  end

  defp parse_top_level({:__block__, [], statements}, state),
    do: Map.reduce(statements, state, &parse_statement(&1, &2))

  defp parse_statement({:@, _line, [{field, _line2, params}]}, state), do: parse_field(field, params, state)
  defp parse_statement({:def, _line, [{function, _line2, params}, [do: {:__block__, [], func_statements}]]}, state) do
    parse_function(params, func_statements)
    Map.update!(state, :functions, &(&1 ))
  end
  defp parse_statement({:def, _line, [{function, _line2, params}, [do: func_statements]]}, state), do: :yolo

  defp parse_field(:name, [name], state), do: %{state | name: name}
  defp parse_field(:image, [image], state), do: %{state | image: image |> interpolate(state.environment_params)}

  defp parse_function(name, params, statements) do
    parsed_params = Enum.map(params, &parse_function_param(&1))
    {
      parsed_params
      Enum.map(statements, &parse_function_statement(&1, parsed_params))
    }
  end

  defp parse_function(name, params, statements) do
    {
      name,
      fn args ->
        #TODO: Zip params and args.
        Enum.map(statements, &Enum.reduce(params, &1, fn x, acc -> interpolate(acc, )))
      end     
    }
  end

  defp parse_function_param({param, _line, _}), do: param 

  defp parse_function_statement({:command, _line, [command]}, params), do: command |> interpolate(params)

  defp interpolate(string, params) do
    Regex.scan(~r/{(\w+)}/, string) 
    |> Enum.map(fn [_, x] -> x end) 
    |> Enum.uniq() 
    |> Enum.filter(&Keyword.has_key?(params, String.to_atom(&1)))
    |> Enum.reduce(string, &String.replace(&2, "{#{&1}}", Keyword.get(params, String.to_atom(&1))))
  end
end
