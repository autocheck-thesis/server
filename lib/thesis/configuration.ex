defmodule Thesis.Configuration do
  alias Thesis.Configuration.Parser

  def get_required_files(configuration_code) do
    Parser.parse!(configuration_code)
    |> Map.get(:required_files, [])
  end

  def validate(configuration_code) do
    case Parser.parse(configuration_code) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end