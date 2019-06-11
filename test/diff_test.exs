defmodule Autocheck.DiffTest do
  use ExUnit.Case

  import Autocheck.Diff

  defp rev1_file(), do: File.cwd!() <> "/test/HelloWorld.java"
  defp rev2_file(), do: File.cwd!() <> "/test/HelloWorld2.java"

  test "diff works" do
    rev1 = {Path.basename(rev1_file()), File.read!(rev1_file())}
    rev2 = {Path.basename(rev2_file()), File.read!(rev2_file())}

    diff = diff_files(rev1, rev2)

    IO.puts(diff)
  end
end
