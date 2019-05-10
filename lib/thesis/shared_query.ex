defmodule Thesis.SharedQuery do
  import Ecto.Query

  def order_by_insertion_time(queryable, order \\ :desc) do
    queryable
    |> order_by([q], {^order, q.inserted_at})
  end

  def limit(queryable, limit \\ 1) do
    queryable
    |> Ecto.Query.limit(^limit)
  end
end
