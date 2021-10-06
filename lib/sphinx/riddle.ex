defmodule Sphinx.Riddle do
  @moduledoc ~S"""
  Main module for making riddles
  """

  @typedoc ~S"""
  A custom module of user which implement `Sphinx.Riddle`
  """
  @type user_module() :: %{
                           options: Keyword.t,
                           register: List.t,
                           context: Any.t
                         }

  @doc """
  Returns init args
  """
  @callback init(Keyword.t) :: Keyword.t

  @doc """
  Returns context for riddle. This function will be
  called when you try to create riddle.

  Function passes context data and return context data.
  """
  @callback context(user_module()) :: Any.t

  @doc """
  Returns answer for riddle. Will be called when user
  gonna try to check his answer.
  """
  @callback answer(user_module()) :: Any.t

  @doc """
  Pre-action of making a riddle. As example, it can be email
  or SMS sending.

  Args

    * riddle - user module, `Sphinx.Riddle` implementation

  Returns self

  """
  @callback make(user_module()) :: user_module()

  @doc ~S"""
  Checking answer for current riddle

  Args:

    * riddle - user module, `Sphinx.Riddle` implementation
    * actual_answer - answer, returned by user module or actual in struct
    * answer - the received answer that we have to check

  """
  @callback check(user_module(), Any.t, Any.t) :: Boolean.t

  @doc ~S"""
  Handles result of checking answer to riddle

  Args:

    * riddle - user module, `Sphinx.Riddle` implementation
    * result - result of calling `check/3` function

  Returns:

    * if result is {:proceed, user_module()} - gonna ge started new riddle
    * if result is {:break, _} - clash gonna be stopped
    * if result has another data - this another data will be returned

  """
  @callback verdict(user_module(), Any.t) :: Any.t

  @optional_callbacks init: 1,
                      context: 1

  defmacro __using__(_args) do
    quote do
      @behaviour Sphinx.Riddle

      defstruct options: [],
                register: [],
                context: %{}

      @type t() :: %__MODULE__{
                     options: Keyword.t,
                     register: List.t,
                     context: Any.t
                   }

      @spec create(Any.t, Keyword.t) :: __MODULE__.t
      def create(context \\ %{}, options \\ [])
      def create(context, options) do
        %__MODULE__{register: []}
        |> Sphinx.Riddle.put_options(options)
        |> Sphinx.Riddle.put_context(context)
      end
    end
  end


  @doc ~S"""
  Function for putting custom context data
  """
  @spec put_context(user_module(), Any.t) :: user_module()
  def put_context(user_module, context) do
    context = try do
      apply(user_module.__struct__, :context, [context])
    rescue
      UndefinedFunctionError -> context
    end
    %{user_module | context: context}
  end

  @doc ~S"""
  Function for putting user options
  """
  @spec put_options(user_module(), Map.t) :: user_module()
  def put_options(user_module, options) do
    options = try do
      apply(user_module.__struct__, :init, [options])
    rescue
      UndefinedFunctionError -> options
    end
    %{user_module | options: options}
  end
end
