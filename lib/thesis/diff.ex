defmodule Thesis.Diff do
  require Logger

  def diff_files({name1, contents1}, {name2, contents2}) do
    Temp.track!()
    {:ok, file1_path} = Temp.open(name1, &IO.write(&1, contents1))
    {:ok, file2_path} = Temp.open(name2, &IO.write(&1, contents2))

    res =
      case System.cmd("diff", ["-Nau", file1_path, file2_path]) do
        {res, code} when code in 0..1 ->
          res

        {res, code} ->
          Logger.error("Could not diff. Result '#{res}' with code '#{code}'")
          {:error, code}
      end

    Temp.cleanup()

    res
  end
end
