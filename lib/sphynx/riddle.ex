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
  A struct for user module which implement `Sphynx.Riddle`
  """
  @type t() :: %{
                           options: Keyword.t,
                           register: list(),
                           context: any()
                         }

  defmacro __using__(_args) do
    quote do
      defstruct options: [],
                register: [],
                context: %{}

      @type t() :: %__MODULE__{
                     options: Keyword.t,
                     register: list(),
                     context: any()
                   }

      @doc """
      Returns init args
      """
      @spec init(Keyword.t) :: Keyword.t
      def init(options), do: options

      @doc ~S"""
      Returns correctly answer for riddle. Will be called when user gonna try to check his answer.

      Result of this function gonna be second argument of `check/3`

      ## Arguments

        * riddle - custom user riddle module

      """
      @spec answer(__MODULE__.t) :: any()
      def answer(_), do: raise(Sphynx.RiddleDefiningError.new(module: __MODULE__, function: :answer))

      @doc ~S"""
      Checking answer for current riddle.

      Data, which been returned by this function will be a second argument for `verdict/2` callback.

      ## Arguments

        * riddle - user module, `Sphynx.Riddle` implementation

        * actual_answer - answer, returned by user module or actual in struct

        * answer - the received answer that we have to check

      """
      @spec check(__MODULE__.t, any(), any()) :: any()
      def check(%__MODULE__{}, _, _), do: raise(Sphynx.RiddleDefiningError.new(module: __MODULE__, function: :check))

      @doc ~S"""
      Handles result of checking answer to riddle

      ## Arguments

        * riddle - user module, `Sphynx.Riddle` implementation

        * result - result of calling `check/3` function

       ## Possibly Returns

        * if result is {:proceed, current_module} - gonna ge started new riddle

        * if result is {:break, _} - clash gonna be stopped

        * if result has another data - this another data will be returned

      """
      @spec verdict(__MODULE__.t, any()) :: any()
      def verdict(%__MODULE__{}, _), do: raise(Sphynx.RiddleDefiningError.new(module: __MODULE__, function: :verdict))

      @doc """
      Returns context for riddle. This function will be
      called when you try to create riddle.

      Function passes context data and return context data.
      """
      @spec context(map()) :: map()
      def context(%{} = context), do: context

      @doc ~S"""
      Function which calls when new game with current riddle has been started
      """
      @spec make(__MODULE__.t) :: __MODULE__.t
      def make(%__MODULE__{} = module), do: module

      @doc ~S"""
      Function for creating the new riddle from module implementation
      """
      @spec create(any(), Keyword.t) :: __MODULE__.t
      def create(context \\ %{}, options \\ [])
      def create(context, options) do
        %__MODULE__{register: []}
        |> Sphynx.Riddle.put_options(options)
        |> Sphynx.Riddle.put_context(context)
      end

      # overridable functions
      defoverridable init: 1,
                     context: 1,
                     make: 1,
                     answer: 1,
                     check: 3,
                     verdict: 2
    end
  end


  @doc ~S"""
  Function for putting custom context data

  This function calls `context/1` of received riddle and pass exist `context` to it. Result are the data,
  which will been putted into `:context` field of current riddle.

  ## Arguments

    1. User module with implementation of `Sphynx.Riddle`

    2. Data, which will been sent as argument into `context/1` function of `riddle`

  """
  @spec put_context(t(), any()) :: t()
  def put_context(riddle, context) do
    context = apply(riddle.__struct__, :context, [context])
    %{riddle | context: context}
  end

  @doc ~S"""
  Function for putting options of riddle instance

  This function calls `init/1` of received riddle and pass exist `options` to it. Result are the data,
  which will been putted into `:options` field of current riddle.

  ## Arguments

    1. User module with implementation of `Sphynx.Riddle`

    2. Data, which will been sent as argument into `init/1` function of `riddle`

  """
  @spec put_options(t(), map()) :: t()
  def put_options(riddle, options) do
    options = apply(riddle.__struct__, :init, [options])
    %{riddle | options: options}
  end
end
