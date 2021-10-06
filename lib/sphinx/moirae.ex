defmodule Sphinx.Moirae do
  @moduledoc ~S"""
  Main module, creates the clashes with sphinx.
  """
  use DynamicSupervisor
  alias Sphinx.Clash
  import Sphinx, only: [generate_atom: 0]

  # ====================
  #  DEFAULT FUN
  # ====================

  @impl true
  @spec init(Keyword.t) :: Keyword.t
  def init(args), do: DynamicSupervisor.init(strategy: :one_for_one, extra_arguments: [args])

  @spec start_link(Keyword.t) :: pid()
  def start_link(args) do
    name = Keyword.get(args, :name) || __MODULE__
    DynamicSupervisor.start_link(__MODULE__, args, name: name)
  end

  # ====================
  #  CLIENT API
  # ====================

  @doc ~S"""
  Starts new clash
  """
  @spec start_clash(Atom.t, Keyword.t) :: pid()
  def start_clash(moirae_pname, args \\ []) do
    args = args ++ [
      name: find_clean_clash_identity(moirae_pname)
    ]
    DynamicSupervisor.start_child(moirae_pname, {Clash, args})
  end

  @doc ~S"""
  Ends clash by his name
  """
  @spec end_clash(Atom.t, Atom.t, Any.t) :: Any.t
  def end_clash(moirae_pname, clash_pname, return \\ :terminate_result) do
    find_pid_by_name(moirae_pname, clash_pname)
    |> case do
         pid when is_pid(pid) ->
           terminate = DynamicSupervisor.terminate_child(:moirae, pid)
           if return === :terminate_result, do: terminate, else: return
         nil -> :not_found
       end
  end

  @doc ~S"""
  Returns list of clashes in this supervisor
  """
  @spec get_clashes(Atom.t) :: List.t(Clash.t)
  def get_clashes(moirae_pname) do
    moirae_pname
    |> DynamicSupervisor.which_children()
    |> Enum.map(fn {_, clash_pid, _, _} -> Clash.lookup(Clash.identity(clash_pid)) end)
  end


  # ===========================
  #  PRIVATE HELPER FUNCTIONS
  # ===========================

  @spec find_pid_by_name(Atom.t, Atom.t) :: pid() | nil
  defp find_pid_by_name(moirae_pname, clash_pname) do
    moirae_pname
    |> DynamicSupervisor.which_children()
    |> Enum.find(fn {_, clash_pid, _, _} -> Clash.identity(clash_pid) === clash_pname end)
    |> case do
         {_, clash_pid, _, _} -> clash_pid
         _ -> nil
       end
  end

  @spec find_clean_clash_identity(Atom.t) :: Atom.t
  defp find_clean_clash_identity(moirae_pname) do
    childrens = DynamicSupervisor.which_children(moirae_pname)
    identity = generate_atom()
    if is_free_clash_identity?(identity, childrens), do: identity, else: find_clean_clash_identity(moirae_pname)
  end

  @spec is_free_clash_identity?(Atom.t, List.t) :: Boolean.t
  defp is_free_clash_identity?(identity, childrens) do
    childrens
    |> Enum.find(fn {_, clash_pid, _, _} -> Clash.identity(clash_pid) === identity end)
    |> Kernel.is_nil()
  end
end
