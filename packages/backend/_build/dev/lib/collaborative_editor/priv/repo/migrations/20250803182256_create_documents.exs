defmodule CollaborativeEditor.Repo.Migrations.CreateDocuments do
  use Ecto.Migration

  def change do
    create table(:documents, primary_key: false) do
      add :id, :string, primary_key: true
      add :title, :string, null: false
      add :content, :text
      add :language, :string, default: "javascript"
      add :yjs_state, :binary
      add :metadata, :map, default: %{}

      timestamps()
    end

    create unique_index(:documents, [:id])
  end
end
