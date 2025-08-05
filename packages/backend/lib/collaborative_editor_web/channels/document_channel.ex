defmodule CollaborativeEditorWeb.DocumentChannel do
  @moduledoc """
  Channel for handling real-time document collaboration.

  This channel manages document sessions, user presence, and synchronization
  of document changes across all connected clients using CRDT operations.
  """

  use CollaborativeEditorWeb, :channel

  alias CollaborativeEditor.Documents
  alias CollaborativeEditor.Presence
  alias CollaborativeEditor.YjsSync

  require Logger

  intercept ["presence_diff"]

  @impl true
  def join("document:" <> document_id, %{"token" => token} = _payload, socket) do
    Logger.info("User attempting to join document: #{document_id}")

    case authenticate_user(token) do
      {:ok, user} ->
        # Ensure document exists
        case Documents.get_or_create_document(document_id) do
          {:ok, document} ->
            socket = socket
            |> assign(:document_id, document_id)
            |> assign(:document, document)
            |> assign(:user, user)

            # Track user presence
            send(self(), :after_join)

            {:ok, %{
              document_id: document_id,
              user_id: user.id,
              initial_state: document.content || ""
            }, socket}

          {:error, reason} ->
            Logger.error("Failed to get/create document #{document_id}: #{inspect(reason)}")
            {:error, %{reason: "Failed to access document"}}
        end

      {:error, reason} ->
        Logger.warning("Authentication failed for document #{document_id}: #{reason}")
        {:error, %{reason: "Authentication failed"}}
    end
  end

  def join("document:" <> _document_id, _payload, _socket) do
    {:error, %{reason: "Missing authentication token"}}
  end

  @impl true
  def handle_info(:after_join, socket) do
    document_id = socket.assigns.document_id
    user = socket.assigns.user

    # Track user presence
    {:ok, _} = Presence.track(socket, user.id, %{
      id: user.id,
      name: user.name,
      email: user.email,
      joined_at: DateTime.utc_now(),
      cursor: nil
    })

    # Send presence state to newly joined user
    push(socket, "presence_state", Presence.list(socket))

    # Initialize Yjs document state
    case YjsSync.get_state_vector(document_id) do
      {:ok, state_vector} ->
        push(socket, "yjs_sync", %{
          type: "sync_step_1",
          state_vector: state_vector
        })

      {:error, _reason} ->
        Logger.warning("Failed to get state vector for document #{document_id}")
    end

    Logger.info("User #{user.id} joined document #{document_id}")
    {:noreply, socket}
  end

  @impl true
  def handle_in("yjs_sync", %{"type" => "sync_step_1", "state_vector" => state_vector}, socket) do
    document_id = socket.assigns.document_id

    case YjsSync.get_update_since_state_vector(document_id, state_vector) do
      {:ok, update} when byte_size(update) > 0 ->
        push(socket, "yjs_sync", %{
          type: "sync_step_2",
          update: Base.encode64(update)
        })

      {:ok, _empty_update} ->
        # No updates needed
        :ok

      {:error, reason} ->
        Logger.error("Failed to get update for document #{document_id}: #{inspect(reason)}")
    end

    {:noreply, socket}
  end

  def handle_in("yjs_sync", %{"type" => "sync_step_2", "update" => encoded_update}, socket) do
    document_id = socket.assigns.document_id

    with {:ok, update} <- Base.decode64(encoded_update),
         {:ok, _} <- YjsSync.apply_update(document_id, update) do

      # Broadcast update to all other clients
      broadcast_from(socket, "yjs_sync", %{
        type: "update",
        update: encoded_update
      })

      # Save document state periodically
      spawn(fn -> Documents.save_document_state(document_id) end)

    else
      {:error, reason} ->
        Logger.error("Failed to apply Yjs update: #{inspect(reason)}")
    end

    {:noreply, socket}
  end

  def handle_in("yjs_update", %{"update" => encoded_update}, socket) do
    document_id = socket.assigns.document_id

    with {:ok, update} <- Base.decode64(encoded_update),
         {:ok, _} <- YjsSync.apply_update(document_id, update) do

      # Broadcast update to all other clients
      broadcast_from(socket, "yjs_update", %{
        update: encoded_update
      })

      # Save document state (debounced)
      YjsSync.schedule_save(document_id)

    else
      {:error, reason} ->
        Logger.error("Failed to apply Yjs update: #{inspect(reason)}")
    end

    {:noreply, socket}
  end

  def handle_in("cursor_update", %{"position" => position}, socket) do
    user = socket.assigns.user

    # Update user presence with cursor position
    {:ok, _} = Presence.update(socket, user.id, fn meta ->
      Map.put(meta, :cursor, position)
    end)

    {:noreply, socket}
  end

  def handle_in("awareness_update", %{"states" => states}, socket) do
    # Broadcast awareness update to other clients
    broadcast_from(socket, "awareness_update", %{states: states})
    {:noreply, socket}
  end

  @impl true
  def handle_out("presence_diff", diff, socket) do
    push(socket, "presence_diff", diff)
    {:noreply, socket}
  end

  @impl true
  def terminate(reason, socket) do
    document_id = socket.assigns[:document_id]
    user = socket.assigns[:user]
    user_id = if is_map(user), do: user.id, else: nil

    Logger.info("User #{user_id} left document #{document_id}, reason: #{inspect(reason)}")
    :ok
  end

  # Private functions

  defp authenticate_user("anonymous") do
    # Allow anonymous users for demo purposes
    {:ok, %{
      id: "anonymous_" <> UUID.uuid4(),
      name: "Anonymous User",
      email: nil
    }}
  end

  defp authenticate_user(token) when is_binary(token) do
    case JWT.decode(token, get_jwt_secret()) do
      {:ok, %{"user_id" => user_id, "name" => name, "email" => email}} ->
        {:ok, %{id: user_id, name: name, email: email}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp authenticate_user(_), do: {:error, "Invalid token format"}

  defp get_jwt_secret do
    Application.get_env(:collaborative_editor, :jwt_secret, "dev_secret_key")
  end
end
