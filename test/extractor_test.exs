defmodule Thesis.ExtractorTest do
  use ExUnit.Case
  import Thesis.Extractor

  defp existing_zip_archive(), do: File.cwd!() <> "/test/test.zip"
  defp existing_targz_archive(), do: File.cwd!() <> "/test/test.tar.gz"
  defp non_existing_zip_archive(), do: File.cwd!() <> "/test/non-existing.zip"
  defp non_existing_targz_archive(), do: File.cwd!() <> "/test/non-existing.tar.gz"
  defp non_existing_file(), do: "/dev/null"

  defp evil_header_zip_archive(), do: File.cwd!() <> "/test/10GB.zip"
  defp evil_header_targz_archive(), do: File.cwd!() <> "/test/10GB.tar.gz"

  test "fail for non existing archives" do
    assert {:error, _} = peek_size(non_existing_zip_archive())
    assert {:error, _} = peek_size(non_existing_targz_archive())
    assert {:error, _} = peek_size(non_existing_file())
  end

  test "peek size for .zip archive" do
    assert {:ok, 104} = peek_size(existing_zip_archive())
  end

  test "peek size for .tar.gz archive" do
    assert {:ok, 104} = peek_size(existing_targz_archive())
  end

  test "handle evil headers" do
    assert {:error, :bad_eocd} = extract(evil_header_zip_archive())
    assert {:error, _} = extract(evil_header_targz_archive())
  end

  test "handles extraction size limit" do
    assert {:error, _} = extract(existing_zip_archive(), limit: 100)
    assert {:ok, _} = extract(existing_zip_archive(), limit: 200)
  end
end
