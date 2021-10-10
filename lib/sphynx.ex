defmodule Sphynx do
  @moduledoc ~S"""
  `Sphynx` is a small and simple library which grants GenServer based question-answer service.

  For simpilicity logic of this service, I was cover modules and mechanisms into clear concepts and analogies.

  ## Sphynx

  As you know, sphynx - is a mythical creature, which make a riddles for adventurers (and killed them if they
  were give incorrect answer). My shpynx makes riddles too, but he will not hurt you (if you will declare and
  implement modules and functions correctly :D).

  This module is a sphynx (obviously), and it implements all required API for gaming cycle. It have no struct,
  macro and etc. just functions and nothing more.

  ## Game

  Game is a contact between `adventurer` (it can be you, developer, but most likely it will be user of system
  which you make) and `sphynx`. The module `Sphynx.Clash` is responsible for games. Every game in system is a one
  `Sphynx.Clash`.

  ## Clash

  As I writed in `Game` section, the module `Sphynx.Clash` is responsible for games. `Sphynx.Clash` is a GenServer
  so it works asynchroniously, therefore a lot of games can be in process at the same time.

  Below I will describe several cases where this can come in handy.

  Every cycle of game consist of a `Sphynx.Riddle`.

  ## Riddle

  The Riddle is a module which implements (use) `Sphynx.Riddle` and realize basic functions for making riddle,
  checking result, delivery of a verdict and etc.

  ## Moira

  Every game should have referee. In `Sphynx` it is a `Sphynx.Moira`.

  Moira - goddess of fate in ancient Greek religion and mythology. I have thought that Moira could be a reason why
  Oedipus became part of terrible prophecy and was forced to play death game with sphynx. So I've decided make she
  a game master in this place :)

  `Sphynx.Moira` is a `DynamicSupervisor` and responsible for things like starting clashes, ending clashes, getting
  clashes and etc. If you wanna know who plays and what kind of riddle in process now - just call her :P

  ## How does it work

  1. Defining. You must correctly define your riddle module. Your riddle module have to use `Sphynx.Riddle` and
  implement all required functions.

  2. Starting the game. For game starting you have to call `Sphynx.start_game/1` like as:
  `Sphynx.start_game(MyRiddle.create())`. Result of this move have to be a unique id of your game (it
  is atom). Let's imagine that you've received `:bestgameever` value.
  Fine. From now on, your game registered in system and waits for your answer.

  3. The playing. To move on, you have to send answer and system will decide what it would do next. For doing
  that you have to call `Sphynx.reply/2`, as example: `Sphynx.reply(:bestgameever, "my_answer")`. If verdict
  by your riddle gonna have a specific pattern - game can be continued with new riddle, or completed with
  returning of result to guessing man. If you wanna stop exist game, you can just call `Sphynx.end_game/1`
  or `Sphynx.end_game/2`. And game will be stopped.

  ## Cases

  How this library can be useful for you.

  ### Authentication systems.
  Actually, idea for making this library has come when I've been writing the regular authentication code (I'm sure,
  you know how boring process is it, they all have the same logic, small details different only).

  Solution for Login-Pass would looks like:

  You have to implement `answer/1` of your riddle module with returning the password hash of your
  user (will assume, that your user data or schema located in `:context` of your riddle):

      defmodule MyRiddle do
        use Sphynx.Riddle
        ...
        # result of this function will be redirected to `check/3` as second argument
        def answer(%MyRiddle{context: %{user: %Users{password_hash: password_hash}}}), do: password_hash
        ...
      end

  Setting the context of your riddle can be executed before game start. Like an:

      query = Ecto.Query.from(user in Users, where: user.id == ^user_id)
      user = Repo.get(query)
      riddle = MyRiddle.create(%{user: user})
      Sphynx.start_game(riddle)

  by the way, you can change current riddle context after game start (when `make/1` gonna called) via:

      defmodule MyRiddle do
        use Sphynx.Riddle
        ...
        def make(%MyRiddle{context: context} = my_riddle) do
          %{my_riddle | context: %{my_new_context_key: "my_new_context_value"}}
        end
        ...
      end

  Your `check/3` have to be implemented like:

      defmodule MyRiddle do
        use Sphynx.Riddle
        ...
        # result of this function will be redirected to `verdict/2` as second argument
        def check(%MyRiddle{}, result_of_answer_fun, user_assumption) do
          # we got `result_of_answer_fun` from `answer/1`
          if result_of_answer_fun === MyAuthModule.hash_password(user_assumption),
            do: :valid,
            else: :invalid
        end
        ...
      end

  And `verdict/2` have to looks like this:

      defmodule MyRiddle do
        use Sphynx.Riddle
        ...
        # `result` is a value, which been returned by `check/3`
        def verdict(%MyRiddle{context: %{user: user}}, result) when result === :valid do
          {:ok, generate_user_access_token!(user)}
        end
        def verdict(%MyRiddle{}, result) when result === :invalid do
          # this is one of "specific" patterns, it means that game will be stopped
          result = {:error, "invalid password"}
          {:break, result}
        end
        ...
      end

  So how will it work. When user gonna enter his login into your system (and this username found in database)
  you have to get found user and start new game with him.

      query = Ecto.Query.from(user in Users, where: user.id == ^user_id)
      user = Repo.get(query)
      riddle = MyRiddle.create(%{user: user})
      Sphynx.start_game(riddle)

  then you can return the id of game to his owner (will be returned by `Sphynx.start_game/1`). When user will
  pass his password, you have to call `Sphynx.reply/2` like `Sphynx.reply(:user_game_id, received_password)`.

  Result of this call will be a {:ok, "my_auth_token"} or  {:error, "invalid password"}

  ### More difficult cases

  More diffictult cases can require an understanding the game roadmap. It is very simple thing, and by integrating
  into it, you can implement business logic of any complicity.

  The lifcycle of riddle looks that: `create -> make -> answer -> check -> verdict`

  As example, if I wanna implement authentication by SMS code - I will add code generation and SMS sending into
  `make/1` and save generated code into context of current riddle. `answer/1`, `check/3` and `verdict/2` in this
  case gonna be regular.

  Sphynx doesn't set limits for `answer/1`, `check/3` and `verdict/2`. This functions can return any result (and
  this result will be one of arguments in next callback in lifecycle).
  It means, that you can try to send any structs of data to `Sphynx.reply/2`, not the strings or integers only. And
  it gives opportunity to use library for biometric auth, auth by QR code, making a simple games, education tests
  and etc.

  The result of `verdict/2` can be in 3 state:
  1. Next question (when `verdict/2` returns `{:proceed, MySecondRiddle}`}
  2. Shutdown (when `verdict/2` result matches `{:break, any()}` pattern}
  3. Complete (when 1 and 2 steps arent matched)

  It means that you can implement unlimited number of "-factor" authentications.

  More information about inner logic you can find in `Sphynx.Riddle`, `Sphynx.Moira` and `Sphynx.Clash`
  """
  alias Sphynx.Error
  alias Sphynx.Moira
  alias Sphynx.Clash

  defmodule RiddleDefiningError do
    @moduledoc ~S"""
    Error for errors of riddle definition
    """

    @message "you have got error in your riddle `%{module}`"
    @module :undefined_riddle
    @function :undefined_function

    defexception message: @message

    @spec new(Keyword.t) :: String.t
    def new(keyword) do
      module = Keyword.get(keyword, :module, @module)
               |> Atom.to_string()
               |> String.replace("Elixir.", "")
      function = Keyword.get(keyword, :function, @function)
               |> Atom.to_string()
               |> String.replace("Elixir.", "")

      "you have got error in `%{function}` of your riddle `%{module}`, make sure that it was imeplemented correctly"
      |> String.replace("%{module}", module)
      |> String.replace("%{function}", function)
    end

    @typedoc ~S"""
    Struct of error, which raises when riddle are defined incorrect
    """
    @type t :: %__MODULE__{message: String.t()}
  end

  @doc ~S"""
  Starting the game. This functions register new `Sphynx.Clash` with received `Sphynx.Riddle` implementation
  under `Sphynx.Moira` supervising.

  Returns atom with unique id of game, which can be used in game process
  """
  @spec start_game(any()) :: atom()
  def start_game(riddle_module) do
    case Moira.start_clash(:moirae) do
      {:ok, pid} ->
        :ok = Clash.make_riddle(pid, riddle_module)
        Clash.identity(pid)
      e -> raise(Error, message: "game starting error: #{inspect(e)}")
    end
  end

  @doc ~S"""
  Ends game by his identity atom.

  ## Arguments

    1. Atom identity of game.

    2. Return value for success complete. By default will be returned result of termination, otherwise (if
    termination has been completed correctly) gonna be return this argument.

  """
  @spec end_game(atom(), any()) :: any()
  def end_game(identity, return \\ :terminate_result), do: Moira.end_clash(:moirae, identity, return)

  @doc ~S"""
  Function for processing the game.

  Receives game identity and answer for checking

  ## Arguments

    1. Game identity atom. Atom, which been got, when you had called `Sphynx.start_game/1`

    2. Supposed answer to question. Can be any type.

  """
  @spec reply(atom(), any()) :: any()
  def reply(identity, answer), do: Clash.process(identity, answer)

  @doc ~S"""
  Atom generator. By default generates atom with 16 digits, but size is a parameter, so can be changed.

  ## Arguments

    1. Atom size. By default equal 16, receives integers only

  """
  @spec generate_atom(integer()) :: atom()
  @generate_atom_p 'abcdefghijklmnopqrstuvwxyz'
  def generate_atom(size \\ 16) when is_integer(size),
      do: String.to_atom(for _ <- 1..size, into: "", do: <<Enum.random(@generate_atom_p)>>)
end
