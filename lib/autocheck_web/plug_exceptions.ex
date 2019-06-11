defimpl Plug.Exception, for: Autocheck.Extractor.InvalidArchive do
  def status(_exception), do: 400
end
