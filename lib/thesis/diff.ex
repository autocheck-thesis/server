defmodule Thesis.Diff do
  require Logger

  def diff_text(nil, new_text) do
    {:ok, new_path} = Temp.open(nil, &IO.write(&1, new_text))

    diff = do_diff("/dev/null", new_path)

    File.rm_rf(new_path)

    diff
  end

  def diff_text(old_text, new_text) do
    {:ok, old_path} = Temp.open(nil, &IO.write(&1, old_text))
    {:ok, new_path} = Temp.open(nil, &IO.write(&1, new_text))

    diff = do_diff(old_path, new_path)
    # diff =
    #   case do_diff(old_path, new_path) do
    #     {:ok, {:diff, diff}} ->
    #       diff

    #     {:ok, :nodiff} ->
    #       old_text
    #       |> String.split("\n")
    #       |> Enum.map(fn line ->
    #         {determine_operation(line), line}
    #       end)
    #   end

    File.rm_rf(old_path)
    File.rm_rf(new_path)

    diff
  end

  defp do_diff(old_path, new_path) do
    case System.cmd("diff", ["-Nau", old_path, new_path]) do
      {_, 0} ->
        {:ok, :nodiff}

      {output, 1} ->
        # Remove the diff header:
        # --- /dev/null	2019-05-03 11:30:21.000000000 +0200
        # +++ /var/folders/rd/tfsy532d63gg3smztx49gjbm0000gn/T/f-1556875832-1614-7dyxne	2019-05-03 11:30:32.000000000 +0200
        # @@ -0,0 +1,6 @@

        diff =
          output
          |> String.trim_trailing("\\ No newline at end of file\n")
          |> String.split("\n")
          |> Enum.drop(3)
          |> Enum.map(fn line ->
            {determine_operation(line), line}
          end)

        {:ok, {:diff, diff}}

      {output, code} ->
        IO.inspect(output)
        Logger.error("Could not diff. Result '#{output}' with code '#{code}'")
        {:error, code}
    end
  end

  defp determine_operation(line) do
    case(String.at(line, 0)) do
      "+" -> :add
      "-" -> :del
      _ -> :eq
    end
  end
end
