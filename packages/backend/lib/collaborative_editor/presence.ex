defmodule CollaborativeEditor.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :collaborative_editor,
    pubsub_server: CollaborativeEditor.PubSub

  @doc """
  Provides presence tracking for users in document channels.
  """
  def track_user_presence(pid, topic, user_id, user_meta) do
    track(pid, topic, user_id, user_meta)
  end

  @doc """
  Updates presence metadata for a user.
  """
  def update_user_presence(pid, topic, user_id, update_fn) do
    update(pid, topic, user_id, update_fn)
  end

  @doc """
  Lists all presences for a given topic.
  """
  def list_presences(topic) do
    list(topic)
  end

  @doc """
  Gets presence metadata for a specific user.
  """
  def get_user_presence(topic, user_id) do
    get_by_key(topic, user_id)
  end
end
