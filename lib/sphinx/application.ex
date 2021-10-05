defmodule Charon.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc ~S"""
  Auth application module
  """

  use Application
  alias Charon.Supervisors.SignIn

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: Charon.Router, options: [port: 4040]},
#      {SignIn, name: :sign_in}
    ]

    opts = [strategy: :one_for_one, name: Charon.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
