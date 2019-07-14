defmodule Autocheck.MixProject do
  use Mix.Project

  def project do
    [
      app: :autocheck,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    # Specifying applications instead of extra_applications
    # makes Elixir not start application dependencies automatically.
    # The result is that we don't start applications such as 'eventstore'
    # when running tests with `mix test`.
    #
    # If we want to have tests with a database connection we should
    # remove this conditional and specify a proper database configuration
    # in `config/test.exs`
    if Mix.env() == :test do
      [
        mod: {Autocheck.Application, []},
        applications: [:logger, :runtime_tools]
      ]
    else
      [
        mod: {Autocheck.Application, []},
        extra_applications: [:logger, :runtime_tools]
      ]
    end
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:plug_lti, path: "../plug_lti"},
      {:phoenix, "~> 1.4.1"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_html, "~> 2.13"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:phoenix_live_view, github: "phoenixframework/phoenix_live_view"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:gen_stage, "~> 0.14.1"},
      {:eventstore, "~> 0.16.1"},
      {:ex_dockerapi, path: "../DockerAPI.ex"},
      {:autocheck_language, path: "../language"},
      {:temp, "~> 0.4"},
      {:honeydew, "~> 1.4.0"},
      {:plug_cowboy, "~> 2.0"}
    ]
  end
end
