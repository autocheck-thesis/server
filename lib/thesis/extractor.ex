defmodule Thesis.Extractor do
  require Record
  Record.defrecord(:file_info, Record.extract(:file_info, from_lib: "kernel/include/file.hrl"))
  Record.defrecord(:zip_file, Record.extract(:zip_file, from_lib: "stdlib/include/zip.hrl"))

  defmodule InvalidArchive do
    defexception [:reason]

    def exception(reason), do: %__MODULE__{reason: reason}
    def message(%__MODULE__{reason: reason}), do: Thesis.Extractor.format_error(reason)
  end

  def format_error(:bad_eocd), do: "Bad central directory in archive"
  def format_error(:timeout), do: "Decompression timed out"
  def format_error(:size_is_zero), do: "Decompressed size is 0 bytes"
  def format_error(:out_of_memory), do: "Ran out of memory when decompressing"
  def format_error(:unknown_archive_type), do: "Unknown archive type"
  def format_error(reason), do: inspect(reason)

  def try_peek_size(path, types \\ [:zip, :tar]) do
    case determine_archive_type(path) do
      :unknown ->
        Enum.reduce_while(types, {:error, :unknown_archive_type}, fn type, acc ->
          case peek_size(path, type) do
            {:error, _} ->
              {:cont, acc}

            {:ok, size} ->
              {:halt, {:ok, type, size}}
          end
        end)

      type ->
        {:ok, type, peek_size(path, type)}
    end
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

  def extract!(path, opts \\ []) do
    case extract(path, opts) do
      {:ok, result} ->
        result

      {:error, reason} ->
        IO.inspect(reason)
        raise __MODULE__.InvalidArchive, reason
    end
  end

  def extract(path, opts \\ []) do
    # 550 MB
    limit = Keyword.get(opts, :limit, 576_716_800)

    case try_peek_size(path) do
      {:ok, _type, size} when size > limit ->
        {:error, {:size_too_big, size, limit}}

      {:ok, _type, size} when size == 0 ->
        {:error, :size_is_zero}

      {:ok, type, _size} ->
        pid = self()

        spawn_monitor(fn ->
          Process.flag(:max_heap_size, %{size: 2_600_000, kill: true, error_logger: false})

          send(pid, extract_archive(path, type))
        end)

        receive do
          {:DOWN, _, _, _, :normal} ->
            receive do
              result -> result
            after
              60000 -> {:error, :timeout}
            end

          {:DOWN, _, _, _, :killed} ->
            {:error, :out_of_memory}

          {:DOWN, _, _, _, reason} ->
            {:error, inspect(reason)}
        after
          60000 -> {:error, :timeout}
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
      _ -> :unknown
    end
  end
end
