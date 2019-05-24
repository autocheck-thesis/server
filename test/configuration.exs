defmodule Thesis.ConfigurationTest do
  use ExUnit.Case
  import Thesis.Configuration
  alias Thesis.Configuration.{Parser}

  test "configuration with empty step" do
    code = """
    @env "elixir",
      version: "1.7"

    step "empty" do
    end
    """

    assert {:ok, _} = Parser.parse(code)
  end

  test "configuration with invalid environment" do
    code = """
    @env "wutface",
      version: "1.7"

    step "empty" do
      run "actually do things"
    end
    """

    assert {:ok, %Parser{errors: errors}} = Parser.parse(code)
    assert length(errors) == 1
    assert String.contains?(Enum.at(errors, 0).description, "environment is not defined")
  end
end
