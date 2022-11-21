defmodule EndoTest do
  use ExUnit.Case

  describe "hello/0" do
    test "returns `world`" do
      assert Endo.hello() == :world
    end
  end
end
