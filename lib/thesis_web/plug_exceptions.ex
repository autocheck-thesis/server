defimpl Plug.Exception, for: Thesis.Extractor.InvalidArchive do
  def status(_exception), do: 400
end
