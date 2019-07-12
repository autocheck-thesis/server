defmodule Autocheck.Configuration do
  alias Autocheck.Configuration.Parser

  defstruct image: nil,
            required_files: [],
            allowed_file_extensions: [],
            grade: nil,
            steps: []

  def parse_code(code) do
    parsed = Parser.parse!(code)
    struct(Autocheck.Configuration, Map.from_struct(parsed))
  end

  def validate(configuration_code, timeout \\ 1000) do
    case Task.await(Task.async(Parser, :parse, [configuration_code]), timeout) do
      {:ok, _} -> :ok
      {:error, errors} -> {:errors, errors}
    end
  end
end
