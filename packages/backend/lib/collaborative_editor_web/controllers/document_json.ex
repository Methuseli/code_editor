defmodule CollaborativeEditorWeb.DocumentJSON do
  @doc """
  Renders a list of documents.
  """
  def index(%{documents: documents}) do
    %{data: for(document <- documents, do: data(document))}
  end

  @doc """
  Renders a single document.
  """
  def show(%{document: document}) do
    %{data: data(document)}
  end

  def error(%{message: message}) do
    %{error: message}
  end

  def error(%{changeset: changeset}) do
    %{errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)}
  end

  def empty(_) do
    %{}
  end

  defp data(%CollaborativeEditor.Documents.Document{} = document) do
    %{
      id: document.id,
      title: document.title,
      content: document.content,
      language: document.language,
      metadata: document.metadata,
      inserted_at: document.inserted_at,
      updated_at: document.updated_at
    }
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end
end
