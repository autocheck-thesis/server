defmodule Thesis.Extractor do
  require Record
  Record.defrecord(:file_info, Record.extract(:file_info, from_lib: "kernel/include/file.hrl"))
  Record.defrecord(:zip_file, Record.extract(:zip_file, from_lib: "stdlib/include/zip.hrl"))

  def peek_size(path) do
    archive_type = determine_archive_type(path)
    peek_size(path, archive_type)
  end

  def peek_size(path, :zip) do
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

  def peek_size(path, :tar) do
    case :erl_tar.table(to_charlist(path), [:verbose, :compressed]) do
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
    # 550 MB
    limit = Keyword.get(opts, :limit, 576_716_800)

    archive_type = determine_archive_type(path)

    case peek_size(path, archive_type) do
      {:ok, size} when size > limit ->
        {:error, "Decompressed size #{size} bytes is larger than the limit #{limit} bytes."}

      {:ok, size} when size == 0 ->
        {:error, "Decompressed size is 0 bytes."}

      {:ok, _} ->
        pid = self()

        spawn_monitor(fn ->
          Process.flag(:max_heap_size, %{size: 2600, kill: true, error_logger: false})

          send(pid, extract_archive(path, archive_type))
        end)

        receive do
          {:DOWN, _, _, _, :normal} ->
            receive do
              result -> result
            after
              60000 -> {:error, "Timeout"}
            end

          {:DOWN, _, _, _, :killed} ->
            {:error, "Out of memory"}

          {:DOWN, _, _, _, reason} ->
            {:error, inspect(reason)}
        after
          60000 -> {:error, "Timeout"}
        end

      {:error, _} = error ->
        error
    end
  end

  def extract_archive(path, :zip) do
    case :zip.extract(to_charlist(path), [:memory]) do
      {:ok, files} ->
        {:ok, Enum.map(files, &filename_to_string/1)}

      {:error, _} = error ->
        error
    end
  end

  def extract_archive(path, :tar) do
    case :erl_tar.extract(String.to_charlist(path), [:compressed, :memory]) do
      {:ok, files} ->
        {:ok, Enum.map(files, &filename_to_string/1)}

      {:error, _} = error ->
        error
    end
  end

  defp filename_to_string({filename, data}), do: {to_string(filename), data}

  defp determine_archive_type(path) do
    case Path.extname(path) do
      ".zip" -> :zip
      ".tar" -> :tar
      ".gz" -> :tar
      _ -> :zip
    end
  end
end
