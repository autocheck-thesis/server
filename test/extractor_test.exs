defmodule Autocheck.ExtractorTest do
  use ExUnit.Case
  import Autocheck.Extractor

  @existing_zip_archive Path.join(__DIR__, "test.zip")
  @existing_targz_archive Path.join(__DIR__, "test.tar.gz")
  @existing_nested_zip_archive Path.join(__DIR__, "test_nested.zip")
  @existing_nested_targz_archive Path.join(__DIR__, "test_nested.tar.gz")
  @non_existing_zip_archive Path.join(__DIR__, "non-existing.zip")
  @non_existing_targz_archive Path.join(__DIR__, "non-existing.tar.gz")
  @evil_header_zip_archive Path.join(__DIR__, "10GB.zip")
  @evil_header_targz_archive Path.join(__DIR__, "10GB.tar.gz")
  @zip_bomb_archive Path.join(__DIR__, "10GB_2.zip")
  @non_existing_file "/dev/null"

  test "Correct peeked size for every archive type" do
    assert {:ok, :zip, 104} = try_peek_size(@existing_zip_archive)
    assert {:ok, :tar, 104} = try_peek_size(@existing_targz_archive)
  end

  test "Correct archive type when peeking size" do
    assert {:ok, :zip, _size} = try_peek_size(@existing_zip_archive)
    assert {:ok, :tar, _size} = try_peek_size(@existing_targz_archive)
    assert {:error, _} = try_peek_size(@non_existing_zip_archive)
    assert {:error, _} = try_peek_size(@non_existing_targz_archive)
    assert {:error, :unknown_archive_type} = try_peek_size(@non_existing_file)
  end

  test "Evil headers" do
    assert {:error, :bad_eocd} = extract(@evil_header_zip_archive)
    assert {:error, _} = extract(@evil_header_targz_archive)
  end

  test "Max size" do
    assert {:error, _} = extract(@existing_zip_archive, max_size: 100)
    assert {:ok, _} = extract(@existing_zip_archive, max_size: 200)
  end

  test "Correct extraction of files" do
    assert {:ok, [{"HelloWorld.java", data}]} = extract(@existing_zip_archive, max_size: 200)
    assert String.length(data) > 0
    assert {:ok, [{"HelloWorld.java", data}]} = extract(@existing_targz_archive, max_size: 200)
    assert String.length(data) > 0
  end

  test "Correct extraction of nested files" do
    assert {:ok, [{"HelloWorld.java", data}, {"nested/HelloWorld_nested.java", data2}]} =
             extract(@existing_nested_zip_archive, max_size: 300)

    assert String.length(data) > 0
    assert String.length(data2) > 0

    assert {:ok, [{"HelloWorld.java", data}, {"nested/HelloWorld_nested.java", data2}]} =
             extract(@existing_nested_targz_archive, max_size: 300)

    assert String.length(data) > 0
    assert String.length(data2) > 0
  end

  test "Handles zip bomb" do
    assert {:error, :out_of_memory} =
             extract(@zip_bomb_archive, max_size: :infinity, timeout: 10000)

    assert {:error, :timeout} =
             extract(@zip_bomb_archive,
               max_size: :infinity,
               max_heap_size: 20_000_000,
               timeout: 2000
             )
  end

  # NOTE: This works, but I don't want to commit a 550 MB file in git
  # @large_zip_archive Path.join(__DIR__, "random.dat.zip")
  # test "handles large archives" do
  #   assert {:ok, _} = extract(@large_zip_archive)
  # end
end
