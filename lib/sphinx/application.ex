defmodule Sphynx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc ~S"""
  Auth application module
  """

  use Application
  alias Sphynx.Moira

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Sphynx.Router, options: [port: 4000]},
      {Moira, name: :moirae}
    ]

    opts = [strategy: :one_for_one, name: Sphynx.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
