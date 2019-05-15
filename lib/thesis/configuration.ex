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

  def validate(configuration_code) do
    case Parser.parse(configuration_code) do
      {:ok, %Parser{errors: errors}} ->
        case errors do
          [] -> :ok
          [error | _] -> {:errors, error} #TODO: Return all errors when supported
        end

      {:error, error} -> {:errors, error} #TODO: Return all errors when supported
    end
  end
end
