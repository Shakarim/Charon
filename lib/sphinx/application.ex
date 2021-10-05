defmodule Sphinx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc ~S"""
  Auth application module
  """

  use Application
#  alias Sphinx.Supervisors.SignIn

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Sphinx.Router, options: [port: 4040]},
#      {SignIn, name: :sign_in}
    ]

    opts = [strategy: :one_for_one, name: Sphinx.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
