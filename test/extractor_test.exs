defmodule Thesis.ExtractorTest do
  use ExUnit.Case
  import Thesis.Extractor

  defp existing_zip_archive(), do: File.cwd!() <> "/test/test.zip"
  defp existing_targz_archive(), do: File.cwd!() <> "/test/test.tar.gz"
  defp existing_nested_zip_archive(), do: File.cwd!() <> "/test/test_nested.zip"
  defp existing_nested_targz_archive(), do: File.cwd!() <> "/test/test_nested.tar.gz"
  defp non_existing_zip_archive(), do: File.cwd!() <> "/test/non-existing.zip"
  defp non_existing_targz_archive(), do: File.cwd!() <> "/test/non-existing.tar.gz"
  defp non_existing_file(), do: "/dev/null"

  defp evil_header_zip_archive(), do: File.cwd!() <> "/test/10GB.zip"
  defp evil_header_targz_archive(), do: File.cwd!() <> "/test/10GB.tar.gz"

  defp zip_bomb_archive(), do: File.cwd!() <> "/test/10GB_2.zip"

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

  test "correct extraction of files" do
    assert {:ok, [{"HelloWorld.java", data}]} = extract(existing_zip_archive(), limit: 200)
    assert String.length(data) > 0
    assert {:ok, [{"HelloWorld.java", data}]} = extract(existing_targz_archive(), limit: 200)
    assert String.length(data) > 0
  end

  test "correct extraction of nested files" do
    assert {:ok, [{"HelloWorld.java", data}, {"nested/HelloWorld_nested.java", data2}]} =
             extract(existing_nested_zip_archive(), limit: 300)

    assert String.length(data) > 0
    assert String.length(data2) > 0

    assert {:ok, [{"HelloWorld.java", data}, {"nested/HelloWorld_nested.java", data2}]} =
             extract(existing_nested_targz_archive(), limit: 300)

    assert String.length(data) > 0
    assert String.length(data2) > 0
  end

  test "handles zip bomb" do
    assert {:error, _} = extract(zip_bomb_archive(), limit: 1_895_825_409)
  end

  # NOTE: This works, but I don't want to commit a 550 MB file in git
  # defp large_zip_archive(), do: File.cwd!() <> "/test/random.dat.zip"
  # test "handles large archives" do
  #   assert {:ok, _} = extract(large_zip_archive())
  # end
end
