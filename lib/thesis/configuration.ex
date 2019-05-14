defmodule Thesis.Configuration do
  alias Thesis.Configuration.Parser

  def get_required_files(configuration_code) do
    Parser.parse!(configuration_code)
    |> Map.get(:required_files, [])
  end

  def get_testing_fields(configuration_code) do
    relevant_fields = [:image, :steps]

    Parser.parse!(configuration_code)
    |> Enum.filter(fn {k, _v} -> k in relevant_fields end)
    |> Enum.into(%{})
  end

  def validate(configuration_code) do
    case Parser.parse(configuration_code) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
