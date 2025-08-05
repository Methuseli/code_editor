defmodule CollaborativeEditorWeb.DocumentController do
  use CollaborativeEditorWeb, :controller

  alias CollaborativeEditor.Documents

  def index(conn, _params) do
    documents = Documents.list_documents()
    render(conn, :index, documents: documents)
  end

  def show(conn, %{"id" => id}) do
    case Documents.get_document(id) do
      {:ok, document} ->
        render(conn, :show, document: document)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> render(:error, message: "Document not found")
    end
  end

  def create(conn, %{"document" => document_params}) do
    case Documents.create_document(document_params) do
      {:ok, document} ->
        conn
        |> put_status(:created)
        |> render(:show, document: document)

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "document" => document_params}) do
    case Documents.get_document(id) do
      {:ok, document} ->
        case Documents.update_document(document, document_params) do
          {:ok, updated_document} ->
            render(conn, :show, document: updated_document)

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> render(:error, changeset: changeset)
        end

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> render(:error, message: "Document not found")
    end
  end

  def delete(conn, %{"id" => id}) do
    case Documents.get_document(id) do
      {:ok, document} ->
        Documents.delete_document(document)
        conn
        |> put_status(:no_content)
        |> render(:empty)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> render(:error, message: "Document not found")
    end
  end
end
