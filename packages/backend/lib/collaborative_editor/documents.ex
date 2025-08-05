defmodule CollaborativeEditor.Documents do
  @moduledoc """
  The Documents context for managing collaborative documents.
  """
  
  import Ecto.Query, warn: false
  
  alias CollaborativeEditor.Repo
  alias CollaborativeEditor.Documents.Document
  
  @doc """
  Gets a document by ID.
  """
  def get_document(id) do
    case Repo.get(Document, id) do
      nil -> {:error, :not_found}
      document -> {:ok, document}
    end
  end
  
  @doc """
  Gets a document by ID, creating it if it doesn't exist.
  """
  def get_or_create_document(id) do
    case get_document(id) do
      {:ok, document} ->
        {:ok, document}
        
      {:error, :not_found} ->
        create_document(%{
          id: id,
          title: "Untitled Document",
          content: "",
          yjs_state: <<>>
        })
    end
  end
  
  @doc """
  Creates a new document.
  """
  def create_document(attrs \\ %{}) do
    %Document{}
    |> Document.changeset(attrs)
    |> Repo.insert()
  end
  
  @doc """
  Updates a document's content and Yjs state.
  """
  def update_document_state(id, yjs_state, content) do
    case get_document(id) do
      {:ok, document} ->
        document
        |> Document.update_changeset(%{
          yjs_state: yjs_state,
          content: content,
          updated_at: DateTime.utc_now()
        })
        |> Repo.update()
        
      error ->
        error
    end
  end
  
  @doc """
  Updates a document.
  """
  def update_document(%Document{} = document, attrs) do
    document
    |> Document.changeset(attrs)
    |> Repo.update()
  end
  
  @doc """
  Updates document metadata (title, language, etc.).
  """
  def update_document_metadata(id, attrs) do
    case get_document(id) do
      {:ok, document} ->
        document
        |> Document.metadata_changeset(attrs)
        |> Repo.update()
        
      error ->
        error
    end
  end
  
  @doc """
  Deletes a document.
  """
  def delete_document(%Document{} = document) do
    Repo.delete(document)
  end
  
  @doc """
  Lists all documents with optional filters.
  """
  def list_documents(opts \\ []) do
    query = from(d in Document, order_by: [desc: d.updated_at])
    
    query =
      case Keyword.get(opts, :limit) do
        nil -> query
        limit -> query |> limit(^limit)
      end
    
    Repo.all(query)
  end
  
  @doc """
  Gets document statistics.
  """
  def get_document_stats(id) do
    case get_document(id) do
      {:ok, document} ->
        stats = %{
          id: document.id,
          title: document.title,
          language: document.language,
          created_at: document.created_at,
          updated_at: document.updated_at,
          character_count: String.length(document.content || ""),
          line_count: document.content |> String.split("\n") |> length()
        }
        {:ok, stats}
        
      error ->
        error
    end
  end
  
  @doc """
  Saves document state (called periodically by YjsSync).
  """
  def save_document_state(id) do
    # This is called by the YjsSync process to persist state
    case CollaborativeEditor.YjsSync.get_document_content(id) do
      {:ok, content} ->
        case get_document(id) do
          {:ok, document} ->
            update_document(document, %{
              content: content,
              updated_at: DateTime.utc_now()
            })
            
          error ->
            error
        end
        
      error ->
        error
    end
  end
end