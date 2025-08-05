# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     CollaborativeEditor.Repo.insert!(%CollaborativeEditor.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Add some sample documents for testing
alias CollaborativeEditor.Repo
alias CollaborativeEditor.Documents.Document

# Create a sample document (only if it doesn't exist)
case Repo.get(Document, "sample-doc-1") do
  nil ->
    Repo.insert!(%Document{
      id: "sample-doc-1",
      title: "Sample Document",
      content: "# Welcome to Collaborative Editor\n\nThis is a sample document to get you started.",
      language: "markdown",
      metadata: %{
        "created_by" => "system",
        "last_modified_by" => "system"
      }
    })
    IO.puts("Sample document created successfully!")

  _existing ->
    IO.puts("Sample document already exists, skipping creation.")
end
