defmodule Thesis.ExtractorTest do
  use ExUnit.Case
  import Thesis.Extractor

  defp existing_zip_archive(), do: File.cwd!() <> "/test/test.zip"
  defp non_existing_zip_archive(), do: File.cwd!() <> "/test/non-existing.zip"
  defp non_existing_file(), do: "/dev/null"

  test "extracts zip archive" do
    assert {:ok, output} = extract(existing_zip_archive())
    IO.inspect(output)
    assert {:error, _} = extract(non_existing_zip_archive())
    assert {:error, _} = extract(non_existing_file())
  end

  test "handles decompressed file limit" do
    assert {:error, _} = extract(existing_zip_archive(), limit: 100)
    assert {:ok, _} = extract(existing_zip_archive(), limit: 200)
  end
end
