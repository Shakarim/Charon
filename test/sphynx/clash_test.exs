defmodule Sphynx.ClashTest do
  use ExUnit.Case
  alias Sphynx.Clash
  alias Sphynx.Moira
  alias Sphynx.Error

  defmodule Sms do
    use Sphynx.Riddle

    def answer(%__MODULE__{}), do: :sms_riddle_answer

    def make(%__MODULE__{} = schema), do: schema

    def check(%__MODULE__{}, correct_answer, user_answer),
        do: (if correct_answer === user_answer, do: :valid, else: :invalid)

    def verdict(%__MODULE__{}, result), do: {:ok, result}
  end

  defmodule Login do
    use Sphynx.Riddle

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
    use Sphynx.Riddle

    def make(%__MODULE__{}), do: :wrong_make

    def answer(%__MODULE__{}), do: :btm_riddle_answer

    def check(%__MODULE__{}, correct_answer, user_answer), do: correct_answer === user_answer

    def verdict(%__MODULE__{}, result) do
      {:break, result}
    end
  end

  defmodule BreakTestModule do
    use Sphynx.Riddle

    def answer(%__MODULE__{}), do: :btm_riddle_answer

    def make(%__MODULE__{} = schema), do: schema

    def check(%__MODULE__{}, correct_answer, user_answer), do: correct_answer === user_answer

    def verdict(%__MODULE__{}, result) do
      {:break, result}
    end
  end


  describe "`identity/1` |" do
    test "test exist clash" do
      {:ok, pid} = Moira.start_clash(:moirae)

      assert is_atom(Clash.identity(pid))
    end

    test "test not exist clash" do
      result = catch_exit(Clash.identity(:qwerty))

      assert match?({:noproc, _}, result)
    end
  end

  describe "`lookup/1` |" do
    test "test exist clash" do
      {:ok, pid} = Moira.start_clash(:moirae)
      identity = Clash.identity(pid)

      assert Clash.lookup(identity)
    end

    test "test not exist clash" do
      assert Clash.lookup(:qwerty) === nil
    end
  end

  describe "`make_riddle/2` |" do
    test "test valid module" do
      {:ok, pid} = Moira.start_clash(:moirae)
      identity = Clash.identity(pid)
      riddle = __MODULE__.Sms.create(%{}, [])

      assert Clash.make_riddle(identity, riddle) === :ok
    end

    test "test invalid module" do
      {:ok, pid} = Moira.start_clash(:moirae)
      identity = Clash.identity(pid)
      riddle = __MODULE__.InvalidModule.create(%{}, [])

      assert_raise Error, fn ->
        Clash.make_riddle(identity, riddle)
      end
    end

    test "test map" do
      {:ok, pid} = Moira.start_clash(:moirae)
      identity = Clash.identity(pid)

      assert_raise KeyError, fn ->
        Clash.make_riddle(identity, %{})
      end
    end
  end

  describe "`check_answer/2` |" do
    test "test exist clash" do
      {:ok, pid} = Moira.start_clash(:moirae)
      identity = Clash.identity(pid)
      riddle = __MODULE__.Sms.create(%{}, [])
      Clash.make_riddle(identity, riddle)

      assert Clash.check_answer(identity, :sms_riddle_answer) === :valid
      assert Clash.check_answer(identity, :wrong) === :invalid
    end

    test "test not exist clash" do
      {:ok, pid} = Moira.start_clash(:moirae)
      identity = Clash.identity(pid)
      riddle = __MODULE__.Sms.create(%{}, [])
      Clash.make_riddle(identity, riddle)

      assert match?({:noproc, _}, catch_exit(Clash.check_answer(:unexist, :sms_riddle_answer)))
      assert match?({:noproc, _}, catch_exit(Clash.check_answer(:unexist, :wrong)))
    end
  end

  describe "`process/2` |" do
    test "test one step reply, valid answer" do
      {:ok, pid} = Moira.start_clash(:moirae)
      identity = Clash.identity(pid)
      riddle = __MODULE__.Sms.create(%{}, [])
      Clash.make_riddle(identity, riddle)

      assert Clash.process(identity, :sms_riddle_answer) === {:ok, :valid}
    end

    test "test one step reply, invalid answer" do
      {:ok, pid} = Moira.start_clash(:moirae)
      identity = Clash.identity(pid)
      riddle = __MODULE__.Sms.create(%{}, [])
      Clash.make_riddle(identity, riddle)

      assert Clash.process(identity, :wrong) === {:ok, :invalid}
    end

    test "test multi step reply, valid reply" do
      {:ok, pid} = Moira.start_clash(:moirae)
      identity = Clash.identity(pid)
      riddle = __MODULE__.Login.create(%{}, [])
      Clash.make_riddle(identity, riddle)

      first_process_result = Clash.process(identity, :login_riddle_answer)
      second_process_result = Clash.process(identity, :sms_riddle_answer)

      assert match?(%__MODULE__.Login{}, riddle)
      assert match?(%__MODULE__.Sms{}, first_process_result)
      assert second_process_result === {:ok, :valid}
    end

    test "test multi step reply, invalid first reply" do
      {:ok, pid} = Moira.start_clash(:moirae)
      identity = Clash.identity(pid)
      riddle = __MODULE__.Login.create(%{}, [])
      Clash.make_riddle(identity, riddle)

      assert match?(%__MODULE__.Login{}, riddle)
      assert match?(%__MODULE__.Login{}, Clash.lookup(identity).current_riddle)
      assert Clash.process(identity, :wrong) === {:invalid, "invalid result!"}
    end

    test "test multi step reply, invalid second reply" do
      {:ok, pid} = Moira.start_clash(:moirae)
      identity = Clash.identity(pid)
      riddle = __MODULE__.Login.create(%{}, [])
      Clash.make_riddle(identity, riddle)

      login_answer_result = Clash.process(identity, :login_riddle_answer)
      sms_answer_result = Clash.process(identity, :wrong)

      assert match?(%__MODULE__.Login{}, riddle)
      assert match?(%__MODULE__.Sms{}, login_answer_result)
      assert sms_answer_result === {:ok, :invalid}
    end

    test "test break" do
      {:ok, pid} = Moira.start_clash(:moirae)
      identity = Clash.identity(pid)
      riddle = __MODULE__.BreakTestModule.create(%{}, [])
      Clash.make_riddle(identity, riddle)

      assert match?(%__MODULE__.BreakTestModule{}, riddle)
      assert is_atom(identity)
      assert Clash.process(identity, :invalid_answer) === false
      assert Clash.lookup(identity) === nil
    end
  end
end
