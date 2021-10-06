defmodule Sphinx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc ~S"""
  Auth application module
  """

  use Application
  alias Sphinx.Moirae

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Sphinx.Router, options: [port: 4000]},
      {Moirae, name: :moirae}
    ]

    opts = [strategy: :one_for_one, name: Sphinx.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
