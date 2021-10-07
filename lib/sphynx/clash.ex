defmodule Sphynx.Clash do
  use GenServer
  alias Sphynx.Riddle
  alias Sphynx.Error
  import Sphynx, only: [end_game: 2]

  defstruct parent: nil,
            identity: nil,
            current_riddle: nil

  @type t() :: %__MODULE__{
                 parent: Atom.t,
                 identity: Atom.t,
                 current_riddle: Riddle.t
               }

  # ====================
  #  IMPL
  # ====================

  @spec start_link(Keyword.t, Keyword.t) :: pid()
  def start_link(parent_args, own_args) do
    init_struct = %__MODULE__{
      parent: Keyword.get(parent_args, :name),
      identity: Keyword.get(own_args, :name)
    }
    GenServer.start_link(__MODULE__, init_struct, own_args)
  end

  @impl true
  @spec init(Keyword.t) :: {:ok, Keyword.t}
  def init(state), do: {:ok, state}


  # ====================
  #  CLIENT API
  # ====================

  @spec identity(pid()) :: Atom.t
  def identity(pid), do: GenServer.call(pid, {:identity})

  @spec make_riddle(Atom.t, Any.t) :: :ok
  def make_riddle(pname, user_riddle) do
    updated_riddle = apply(user_riddle.__struct__, :make, [user_riddle])
    if is_equal_structs?(user_riddle, updated_riddle) do
      GenServer.cast(pname, {:make_riddle, updated_riddle})
    else
      message = "received value is not a valid riddle, check your #{user_riddle.__struct__}.make/1 function, it have to return `Sphynx.Riddle` implementation (got: #{inspect(updated_riddle)})"
      raise(Error, message: message)
    end
  end

  @spec check_answer(Atom.t, Any.t) :: Any.t
  def check_answer(pname, answer) do
    correct_answer = GenServer.call(pname, {:correct_answer})
    GenServer.call(pname, {:check_answer, correct_answer, answer})
  end

  @spec process(Atom.t, Any.t) :: Any.t
  def process(pname, answer) do
    answer_checking_result = check_answer(pname, answer)
    GenServer.call(pname, {:add_register_item, answer_checking_result})

    case GenServer.call(pname, {:verdict, answer_checking_result}) do
      {:proceed, %_{options: _, register: _, context: _} = next_riddle} ->
        case GenServer.cast(pname, {:make_riddle, next_riddle}) do
          :ok -> next_riddle
          e -> raise(RuntimeError, message: inspect(e))
        end
      {:break, result} -> end_game(pname, result)
      another -> another
    end
  end

  @spec lookup(Atom.t) :: __MODULE__.t
  def lookup(pname) do
    try do
      GenServer.call(pname, {:lookup})
    catch
      :exit, _ -> nil
    end
  end


  # ====================
  #  HANDLES
  # ====================

  @impl true
  def handle_cast({:make_riddle, riddle}, %__MODULE__{} = state) do
    state = %{state | current_riddle: riddle}
    {:noreply, state}
  end

  @impl true
  def handle_call({:identity}, _caller, %__MODULE__{identity: identity} = state), do: {:reply, identity, state}
  def handle_call({:correct_answer}, _caller, %__MODULE__{current_riddle: user_riddle} = state) do
    try do
      result = apply(user_riddle.__struct__, :answer, [user_riddle])
      {:reply, result, state}
    rescue
      e -> {:stop, "error of calling `answer/1`: #{inspect(e)}", state, state}
    end
  end
  def handle_call({:check_answer, correct_answer, answer}, _caller, %__MODULE__{current_riddle: user_riddle} = state) do
    try do
      result = apply(user_riddle.__struct__, :check, [user_riddle, correct_answer, answer])
      {:reply, result, state}
    rescue
      e -> {:stop, "error of calling `check/3`: #{inspect(e)}", state, state}
    end
  end
  def handle_call({:add_register_item, data}, _caller, %__MODULE__{current_riddle: %_{} = riddle} = state) do
    try do
      current_riddle = %{riddle | register: riddle.register ++ [data]}
      state = %{state | current_riddle: current_riddle}
      {:reply, state, state}
    rescue
      e -> {:stop, "error of registering new register item: #{inspect(e)}", state, state}
    end
  end
  def handle_call({:verdict, result_of_checking}, _caller, %__MODULE__{current_riddle: user_riddle} = state) do
    try do
      result = apply(user_riddle.__struct__, :verdict, [user_riddle, result_of_checking])
      {:reply, result, state}
    rescue
      e -> {:stop, "error of calling `verdict/2`: #{inspect(e)}", state, state}
    end
  end
  def handle_call({:lookup}, _caller, %__MODULE__{} = state), do: {:reply, state, state}


  # ====================
  #  HELPERS
  # ====================

  @spec is_equal_structs?(Any.t, Any.t) :: Boolean.t
  defp is_equal_structs?(first, second) when is_map(first) and is_map(second) do
    Map.get(first, :__struct__) === Map.get(second, :__struct__)
  end
  defp is_equal_structs?(_, _), do: false
end
