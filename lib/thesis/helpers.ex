defmodule Thesis.Helpers do
  def job_topic(job) when is_map(job), do: "job:#{job.id}"
  def job_topic(job_id), do: "job:#{job_id}"
end
