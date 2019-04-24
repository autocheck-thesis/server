defmodule Thesis.Extractor do
  def extract(path, opts \\ []) do
    case Path.extname(path) do
      ".zip" -> extract_zip(path, opts)
      _ -> {:error, "Archive format could not be determined"}
    end
  end

  # 1 KB
  def extract_zip(filename, opts \\ []) do
    limit = Keyword.get(opts, :limit, 1024)
    destination = Keyword.get(opts, :destination, "/tmp")

    case get_zip_decompression_size(filename) do
      {:ok, size} when size > limit ->
        {:error, "Decompressed file size to large (#{size} bytes). Limit is #{limit} bytes."}

      {:ok, _} ->
        {output, exit_code} =
          System.cmd("unzip", ["-n", "-v", filename, "-d", destination], stderr_to_stdout: true)

        case exit_code do
          0 ->
            {:ok, output}

          _ ->
            {:error, output}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  def get_zip_decompression_size(filename) do
    {output, exit_code} = System.cmd("unzip", ["-l", filename], stderr_to_stdout: true)

    case exit_code do
      0 ->
        total_size_bytes =
          output
          |> String.split("\n", trim: true)
          |> List.last()
          |> String.split(~r{\s+}, trim: true)
          |> List.first()
          |> String.to_integer()

        {:ok, total_size_bytes}

      _ ->
        {:error, output}
    end
  end
end
