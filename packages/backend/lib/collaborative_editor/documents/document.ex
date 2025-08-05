defmodule CollaborativeEditor.Documents.Document do
  @moduledoc """
  Schema for collaborative documents.
  """
  
  use Ecto.Schema
  import Ecto.Changeset
  
  @primary_key {:id, :string, autogenerate: false}
  @derive {Phoenix.Param, key: :id}
  
  schema "documents" do
    field :title, :string
    field :content, :string
    field :language, :string, default: "javascript"
    field :yjs_state, :binary
    field :metadata, :map, default: %{}
    
    timestamps()
  end
  
  @doc false
  def changeset(document, attrs) do
    document
    |> cast(attrs, [:id, :title, :content, :language, :yjs_state, :metadata])
    |> validate_required([:id, :title])
    |> validate_length(:title, min: 1, max: 255)
    |> validate_inclusion(:language, [
      "javascript", "typescript", "python", "ruby", "go", "rust",
      "java", "cpp", "c", "csharp", "php", "html", "css", "scss",
      "json", "xml", "yaml", "markdown", "sql", "shell", "dockerfile",
      "plaintext"
    ])
    |> unique_constraint(:id, name: :documents_pkey)
  end
  
  @doc false
  def update_changeset(document, attrs) do
    document
    |> cast(attrs, [:content, :yjs_state, :updated_at])
  end
  
  @doc false
  def metadata_changeset(document, attrs) do
    document
    |> cast(attrs, [:title, :language, :metadata])
    |> validate_required([:title])
    |> validate_length(:title, min: 1, max: 255)
  end
end