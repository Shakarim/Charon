defmodule Sphynx.MoiraTest do
  use ExUnit.Case
  alias Sphynx.Moira
  alias Sphynx.Clash

  describe "`start_clash/2` |" do
    test "test valid data" do
      {status, pid} = Moira.start_clash(:moirae)
      clash_identity = Clash.identity(pid)

      assert status === :ok
      assert is_pid(pid)
      assert is_atom(clash_identity)
    end

    test "test invalid data" do
      result = catch_exit(Moira.start_clash(:qwe))

      assert match?({:noproc, _}, result)
    end
  end

  describe "`end_clash/2` |" do
    test "test valid data" do
      {:ok, pid} = Moira.start_clash(:moirae)
      clash_identity = Clash.identity(pid)

      assert Moira.end_clash(:moirae, clash_identity) === :ok
    end

    test "test invalid data" do
      {:ok, pid} = Moira.start_clash(:moirae)
      clash_identity = Clash.identity(pid)
      result = catch_exit(Moira.end_clash(:qwerty, clash_identity))

      assert match?({:noproc, _}, result)
    end
  end

  describe "`end_clash/3` |" do
    test "test valid data" do
      {:ok, pid} = Moira.start_clash(:moirae)
      clash_identity = Clash.identity(pid)

      assert Moira.end_clash(:moirae, clash_identity, "custom result") === "custom result"
    end

    test "test invalid data" do
      {:ok, pid} = Moira.start_clash(:moirae)
      clash_identity = Clash.identity(pid)
      result = catch_exit(Moira.end_clash(:qwerty, clash_identity, "custom result"))

      assert match?({:noproc, _}, result)
    end
  end

  describe "`get_clashes/1` |" do
    test "test valid data" do
      assert is_list(Moira.get_clashes(:moirae))
    end

    test "test invalid data" do
      result = catch_exit(Moira.get_clashes(:qwerty))

      assert match?({:noproc, _}, result)
    end
  end
end
