defmodule Thesis.Extractor do
  require Record
  Record.defrecord(:file_info, Record.extract(:file_info, from_lib: "kernel/include/file.hrl"))
  Record.defrecord(:zip_file, Record.extract(:zip_file, from_lib: "stdlib/include/zip.hrl"))

  def peek_size(path) do
    module = determine_module(path)

    case module do
      :zip -> peek_size_zip(path)
      :erl_tar -> peek_size_tar(path)
    end
  end

  def peek_size_zip(path) do
    case :zip.table(String.to_charlist(path)) do
      {:ok, table} ->
        {:ok,
         table
         |> Enum.filter(fn row -> match?(zip_file(), row) end)
         |> Enum.map(fn zip_file(info: file_info(size: size)) -> size end)
         |> Enum.sum()}

      {:error, _} = error ->
        error
    end
  end

  def peek_size_tar(path) do
    case :erl_tar.table(String.to_charlist(path), [:verbose, :compressed]) do
      {:ok, table} ->
        {:ok,
         table
         # {name, type, size, mtime, mode, uid, gid}
         |> Enum.map(fn {_, _, size, _, _, _, _} -> size end)
         |> Enum.sum()}

      {:error, _} = error ->
        error
    end
  end

  def extract(path, opts \\ []) do
    limit = Keyword.get(opts, :limit, 1024)

    case peek_size(path) do
      {:ok, size} when size > limit ->
        {:error, "Decompressed size #{size} bytes is larger than the limit #{limit} bytes."}

      {:ok, _} ->
        {:ok, "Awesome"}

      {:error, _} = error ->
        error
    end
  end

  defp determine_module(path) do
    case Path.extname(path) do
      ".zip" -> :zip
      ".tar" -> :erl_tar
      ".gz" -> :erl_tar
      _ -> :zip
    end
  end
end
