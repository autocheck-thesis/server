defmodule Autocheck.ConfigurationTest do
  use ExUnit.Case
  import Autocheck.Configuration
  alias Autocheck.Configuration.{Parser}
  alias Autocheck.Configuration.Parser.Error

  @default_valid_env """
  @env "elixir",
    version: "1.7"
  """

  @default_valid_step """
  step "Test 1" do
    run "this should work"
  end
  """

  test "configuration with one top level statement" do
    assert {:ok, _} = Parser.parse(@default_valid_env)
  end

  test "configuration with multiple top level statements" do
    code = @default_valid_env <> @default_valid_step <> """
    step "Test 2" do
      run "something"
    end
    """

    assert {:ok, _} = Parser.parse(code)
  end

  test "configuration without unique step names" do
    code = @default_valid_env <> @default_valid_step <> @default_valid_step

    assert {:error, [%Error{description: description}]} = Parser.parse(code)
    assert String.contains?(description, "same name")
  end

  test "configuration with undefined env" do
    code = """
      @env "invalid"
    """

    assert {:error, %Error{description: "environment is not defined: ", token: :invalid}} = Parser.parse(code)
  end

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

    assert {:error, errors} = Parser.parse(code)
    assert length(errors) == 1
    assert String.contains?(Enum.at(errors, 0).description, "environment is not defined")
  end
end
