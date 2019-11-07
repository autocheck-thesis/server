defmodule Autocheck.Configuration do
  require Protocol

  Protocol.derive(Jason.Encoder, AutocheckLanguage.Error,
    only: [:line, :description, :token, :description_suffix]
  )

  def parse_code(code) do
    parsed = AutocheckLanguage.parse!(code)
    struct(AutocheckLanguage.Configuration, Map.from_struct(parsed))
  end

  def validate(configuration_code, timeout \\ 1000) do
    case Task.await(Task.async(AutocheckLanguage, :parse, [configuration_code]), timeout) do
      {:ok, _} -> :ok
      {:error, errors} -> {:errors, errors}
    end
  end
end
