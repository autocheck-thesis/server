defmodule Thesis.Job do
  @enforce_keys [:id, :image, :cmd, :filename, :filepath]
  defstruct [:id, :image, :cmd, :filename, :filepath]
end
