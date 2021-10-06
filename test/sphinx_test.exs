defmodule SphinxTest do
  use ExUnit.Case
  alias Sphinx
  alias Sphinx.Clash
  alias Sphinx.Moirae
  doctest Sphinx

  defmodule Sms do
    use Sphinx.Riddle

    def answer(%__MODULE__{}) do
      :sms_riddle_answer
    end

    def make(%__MODULE__{} = schema) do
      schema
    end

    def check(%__MODULE__{}, correct_answer, user_answer) do
      if correct_answer === user_answer do
        :valid
      else
        :invalid
      end
    end

    def verdict(%__MODULE__{}, result) do
      {:ok, result}
    end
  end

  defmodule Login do
    use Sphinx.Riddle

    def answer(%__MODULE__{}) do
      :login_riddle_answer
    end

    def make(%__MODULE__{} = schema), do: schema

    def check(%__MODULE__{}, correct_answer, user_answer) do
      if correct_answer === user_answer do
        :valid
      else
        :invalid
      end
    end

    def verdict(%__MODULE__{}, result) do
      if result === :valid do
        sms_riddle = Sms.create(%{old_result: result}, limit: 2, errors: 0)
        {:proceed, sms_riddle}
      else
        {:invalid, "invalid result!"}
      end
    end
  end

  defmodule InvalidModule do
    use Sphinx.Riddle

    def make(%__MODULE__{}), do: :wrong_make

    def answer(%__MODULE__{}), do: :btm_riddle_answer

    def check(%__MODULE__{}, correct_answer, user_answer), do: correct_answer === user_answer

    def verdict(%__MODULE__{}, result) do
      {:break, result}
    end
  end

  defmodule BreakTestModule do
    use Sphinx.Riddle

    def answer(%__MODULE__{}), do: :btm_riddle_answer

    def make(%__MODULE__{} = schema), do: schema

    def check(%__MODULE__{}, correct_answer, user_answer), do: correct_answer === user_answer

    def verdict(%__MODULE__{}, result) do
      {:break, result}
    end
  end

  def fixture(identity, params \\ %{})
  def fixture(:sms_riddle, _params) do
    alias __MODULE__.Sms
    context = %{user: %{username: "Groot", password: "hash!"}}
    options = [fail_limit: 5]
    Sms.create(context, options)
  end
  def fixture(:login_riddle, _params) do
    alias __MODULE__.Login
    context = %{key: "value"}
    options = [fail_limit: 2]
    Login.create(context, options)
  end
  def fixture(:invalid_riddle, _params) do
    alias __MODULE__.InvalidModule
    context = %{key: "value"}
    options = [fail_limit: 2]
    InvalidModule.create(context, options)
  end


  defp login_riddle(params), do: {:ok, login_riddle: fixture(:login_riddle, params)}

  defp sms_riddle(params), do: {:ok, sms_riddle: fixture(:sms_riddle, params)}

  defp invalid_riddle(params), do: {:ok, invalid_riddle: fixture(:invalid_riddle, params)}


  setup [:login_riddle, :sms_riddle, :invalid_riddle]


  test "`generate_atom/1`" do
    value = Sphinx.generate_atom()

    assert is_atom(value)
  end

  test "`create_riddle/2`" do
    alias __MODULE__.Sms
    context = %{key: "value"}
    options = [fail_limit: 2]
    riddle = Sms.create(context, options)

    assert match?(%Sms{}, riddle)
    assert riddle.context === context
    assert riddle.options === options
    assert riddle.register === []
  end

  test "`start_game/1`", %{sms_riddle: sms_riddle} do
    starting_result = Sphinx.start_game(sms_riddle)
    all_clashes = Moirae.get_clashes(:moirae)
    clash = Clash.lookup(starting_result)

    assert is_atom(starting_result)
    assert match?(%Clash{}, clash)
    assert clash in all_clashes
  end

  test "`end_game/1`", %{sms_riddle: sms_riddle} do
    created_clash_identity = Sphinx.start_game(sms_riddle)

    clash = Clash.lookup(created_clash_identity)
    old_clashes_list = Moirae.get_clashes(:moirae)

    assert is_atom(created_clash_identity)
    assert match?(%Clash{}, clash)
    assert clash in old_clashes_list

    ending_result = Sphinx.end_game(created_clash_identity)
    new_clashes_list = Moirae.get_clashes(:moirae)
    new_clash = Clash.lookup(created_clash_identity)

    assert ending_result === :ok
    assert Enum.count(old_clashes_list -- new_clashes_list) === 1
    assert is_nil(new_clash)
  end

  describe "`reply/2` |" do
    test "test invalid module", %{invalid_riddle: invalid_riddle} do
      assert_raise Sphinx.Error, fn ->
        Sphinx.start_game(invalid_riddle)
      end
    end

    test "test one step reply, valid answer", %{sms_riddle: sms_riddle} do
      clash_identity = Sphinx.start_game(sms_riddle)
      answer_result = Sphinx.reply(clash_identity, :sms_riddle_answer)

      assert answer_result === {:ok, :valid}
    end

    test "test one step reply, invalid answer", %{sms_riddle: sms_riddle} do
      clash_identity = Sphinx.start_game(sms_riddle)
      answer_result = Sphinx.reply(clash_identity, :wrong)

      assert answer_result === {:ok, :invalid}
    end

    test "test multi step reply, valid reply", %{login_riddle: login_riddle} do
      clash_identity = Sphinx.start_game(login_riddle)
      login_answer_result = Sphinx.reply(clash_identity, :login_riddle_answer)
      sms_answer_result = Sphinx.reply(clash_identity, :sms_riddle_answer)


      assert match?(%__MODULE__.Login{}, login_riddle)
      assert match?(%__MODULE__.Sms{}, login_answer_result)
      assert sms_answer_result === {:ok, :valid}
    end

    test "test multi step reply, invalid first reply", %{login_riddle: login_riddle} do
      clash_identity = Sphinx.start_game(login_riddle)
      login_answer_result = Sphinx.reply(clash_identity, :wrong)
      actual_riddle = Clash.lookup(clash_identity)

      assert match?(%__MODULE__.Login{}, login_riddle)
      assert match?(%__MODULE__.Login{}, actual_riddle.current_riddle)
      assert login_answer_result === {:invalid, "invalid result!"}
    end

    test "test multi step reply, invalid second reply", %{login_riddle: login_riddle} do
      clash_identity = Sphinx.start_game(login_riddle)
      login_answer_result = Sphinx.reply(clash_identity, :login_riddle_answer)
      sms_answer_result = Sphinx.reply(clash_identity, :wrong)


      assert match?(%__MODULE__.Login{}, login_riddle)
      assert match?(%__MODULE__.Sms{}, login_answer_result)
      assert sms_answer_result === {:ok, :invalid}
    end

    test "test break" do
      riddle = __MODULE__.BreakTestModule.create(%{}, [])
      clash_identity = Sphinx.start_game(riddle)
      reply_result = Sphinx.reply(clash_identity, :invalid_answer)
      clash = Clash.lookup(clash_identity)

      assert match?(%__MODULE__.BreakTestModule{}, riddle)
      assert is_atom(clash_identity)
      assert reply_result === false
      assert clash === nil
    end
  end
end
