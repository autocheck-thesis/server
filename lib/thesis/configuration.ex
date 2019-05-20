defmodule Thesis.Configuration do
  alias Thesis.Configuration.Parser

  defstruct image: nil,
            required_files: [],
            mime_types: [],
            steps: []

  def parse_code(code) do
    parsed = Parser.parse!(code)
    struct(Thesis.Configuration, Map.from_struct(parsed))
  end

  def validate(configuration_code, timeout \\ 1000) do
    case Task.await(Task.async(Parser, :parse, [configuration_code]), timeout) do
      {:ok, %Parser{errors: errors}} ->
        case errors do
          [] -> :ok
          errors -> {:errors, errors}
        end

      {:error, error} ->
        {:errors, [error]}
    end
  end
end
