defmodule Sphynx.Riddle do
  @moduledoc ~S"""
  Module Riddle

      defmodule NumberOfExploitsOfHercules do
        use Sphynx.Riddle
      end

  All functions, which implemented in our example (`NumberOfExploitsOfHercules`) is a part of game lifecycle.

  Roadmap of riddle looks like:
    1. Creating the riddle. Calling `create/2` function with `context` (map) and `options` (keyword).
    The `context` and `options` params passing through `context/1` and `init/1` functions (can be overriden).

    2. Send riddle to game. When riddle were sent to game, riddle are makes. In this case, a call `make/1` occurs.

    3. Processing the answer of user. In this point system calls `answer/1` and sends result of this call into
    the `check/3`.

    4. Result of `check/3` redirects to `verdict/2`. If result have specific pattern - next riddle will be maken,
    otherwise - result will be returned to guessing man.

  Generally: Need to define your riddle module (lets name it `NumberOfExploitsOfHercules`). Riddle module have to
  use `Sphynx.Riddle` and implement his required functions.

      defmodule NumberOfExploitsOfHercules do
        use Sphynx.Riddle
      end

  What is inside:
  Your module have to implement collbacks from `Sphynx.Riddle`. Some of collbacks are required, some - not. The some
  function overridable and have default definition. There functions gonna be called by `Sphynx.Clash` in game progress.

  Requireds:

    * `answer/1` - function for returning correct answer to your question. And it's not static value necessarily.
    This function receives the current riddle implementation as argument and you can use it for making a different
    answers depending on situation.

    * `check/3` - Function for checking and returnning result. It receives arguments:
      1. Current module implementation.
      2. Correct answer. This value - result of calling `answer/1`.
      3. Answer for checking. It's data with user answer, accepts any type.

    * `verdict/2` - Function for delivery of a verdict. Receives 2 argument:
      1. Current module implementation.
      2. Result of checking. That is data, which been returned by `check/3`

  Optional:
  """

  @typedoc ~S"""
  A custom module of user which implement `Sphynx.Riddle`
  """
  @type user_module() :: %{
                           options: Keyword.t,
                           register: List.t,
                           context: any()
                         }

  @doc """
  Returns answer for riddle. Will be called when user
  gonna try to check his answer.
  """
  @callback answer(user_module()) :: any()

  @doc ~S"""
  Checking answer for current riddle

  Args:

    * riddle - user module, `Sphynx.Riddle` implementation
    * actual_answer - answer, returned by user module or actual in struct
    * answer - the received answer that we have to check

  """
  @callback check(user_module(), any(), any()) :: any()

  @doc ~S"""
  Handles result of checking answer to riddle

  Args:

    * riddle - user module, `Sphynx.Riddle` implementation
    * result - result of calling `check/3` function

  Returns:

    * if result is {:proceed, user_module()} - gonna ge started new riddle
    * if result is {:break, _} - clash gonna be stopped
    * if result has another data - this another data will be returned

  """
  @callback verdict(user_module(), any()) :: any()

  defmacro __using__(_args) do
    quote do
      @behaviour Sphynx.Riddle

      defstruct options: [],
                register: [],
                context: %{}

      @type t() :: %__MODULE__{
                     options: Keyword.t,
                     register: List.t,
                     context: any()
                   }

      @doc """
      Returns init args
      """
      @spec init(Keyword.t) :: Keyword.t
      def init(options), do: options

      @doc """
      Returns context for riddle. This function will be
      called when you try to create riddle.

      Function passes context data and return context data.
      """
      @spec context(map()) :: map()
      def context(%{} = context), do: context

      @spec make(__MODULE__.t) :: __MODULE__.t
      def make(%__MODULE__{} = module), do: module

      @spec create(any(), Keyword.t) :: __MODULE__.t
      def create(context \\ %{}, options \\ [])
      def create(context, options) do
        %__MODULE__{register: []}
        |> Sphynx.Riddle.put_options(options)
        |> Sphynx.Riddle.put_context(context)
      end

      defoverridable init: 1,
                     context: 1,
                     make: 1
    end
  end


  @doc ~S"""
  Function for putting custom context data
  """
  @spec put_context(user_module(), any()) :: user_module()
  def put_context(user_module, context) do
    context = apply(user_module.__struct__, :context, [context])
    %{user_module | context: context}
  end

  @doc ~S"""
  Function for putting user options
  """
  @spec put_options(user_module(), Map.t) :: user_module()
  def put_options(user_module, options) do
    options = apply(user_module.__struct__, :init, [options])
    %{user_module | options: options}
  end
end
