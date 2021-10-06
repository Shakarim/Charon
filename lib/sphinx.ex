defmodule Sphinx do
  @moduledoc """
  Documentation for `Sphinx`.
  """
  alias Sphinx.Error
  alias Sphinx.Moirae
  alias Sphinx.Clash

  @spec start_game(Any.t) :: Atom.t
  def start_game(riddle_module) do
    case Moirae.start_clash(:moirae) do
      {:ok, pid} ->
        :ok = Clash.make_riddle(pid, riddle_module)
        Clash.identity(pid)
      e -> raise(Error, message: "game starting error: #{inspect(e)}")
    end
  end

  @spec end_game(Atom.t, Any.t) :: Any.t
  def end_game(identity, default \\ :terminate_result), do: Moirae.end_clash(:moirae, identity, default)

  @spec reply(Atom.t, Any.t) :: Any.t
  def reply(identity, answer), do: Clash.process(identity, answer)

  @doc ~S"""
  Atom generator
  """
  @spec generate_atom(Integer.t) :: Atom.t
  def generate_atom(size \\ 16),
       do: String.to_atom(for _ <- 1..size, into: "", do: <<Enum.random('abcdefghijklmnopqrstuvwxyz')>>)
end
