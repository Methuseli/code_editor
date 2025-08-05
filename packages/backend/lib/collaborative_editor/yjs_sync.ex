defmodule CollaborativeEditor.YjsSync do
  @moduledoc """
  Handles Yjs document synchronization and state management.
  
  This module provides functionality for:
  - Managing Yjs document state vectors
  - Applying and storing document updates
  - Synchronizing state between clients
  - Persisting document state to database
  """
  
  use GenServer
  
  alias CollaborativeEditor.Documents
  
  require Logger
  
  @registry_name :yjs_document_registry
  @save_debounce_ms 2000
  
  # Client API
  
  def start_link(document_id) do
    GenServer.start_link(__MODULE__, document_id, name: via_tuple(document_id))
  end
  
  def get_state_vector(document_id) do
    case get_or_start_process(document_id) do
      {:ok, pid} -> GenServer.call(pid, :get_state_vector)
      error -> error
    end
  end
  
  def get_update_since_state_vector(document_id, state_vector) do
    case get_or_start_process(document_id) do
      {:ok, pid} -> GenServer.call(pid, {:get_update_since, state_vector})
      error -> error
    end
  end
  
  def apply_update(document_id, update) do
    case get_or_start_process(document_id) do
      {:ok, pid} -> GenServer.call(pid, {:apply_update, update})
      error -> error
    end
  end
  
  def schedule_save(document_id) do
    case get_or_start_process(document_id) do
      {:ok, pid} -> GenServer.cast(pid, :schedule_save)
      error -> error
    end
  end
  
  def get_document_content(document_id) do
    case get_or_start_process(document_id) do
      {:ok, pid} -> GenServer.call(pid, :get_content)
      error -> error
    end
  end
  
  # Server Implementation
  
  @impl true
  def init(document_id) do
    Logger.info("Starting Yjs sync process for document: #{document_id}")
    
    # Load existing document state
    state = case Documents.get_document(document_id) do
      {:ok, document} when not is_nil(document.yjs_state) ->
        %{
          document_id: document_id,
          yjs_state: document.yjs_state,
          updates: [],
          save_timer: nil,
          last_saved: DateTime.utc_now()
        }
        
      _ ->
        # Initialize new document
        %{
          document_id: document_id,
          yjs_state: <<>>, # Empty Yjs state
          updates: [],
          save_timer: nil,
          last_saved: DateTime.utc_now()
        }
    end
    
    {:ok, state}
  end
  
  @impl true
  def handle_call(:get_state_vector, _from, state) do
    # For simplicity, we'll use a basic state vector
    # In a production system, you'd implement proper Yjs state vector logic
    state_vector = :crypto.hash(:sha256, state.yjs_state)
    {:reply, {:ok, state_vector}, state}
  end
  
  def handle_call({:get_update_since, _state_vector}, _from, state) do
    # Return the current state as an update
    # In a real implementation, you'd compare state vectors and return diff
    {:reply, {:ok, state.yjs_state}, state}
  end
  
  def handle_call({:apply_update, update}, _from, state) do
    try do
      # Merge the update with current state
      # This is a simplified merge - real Yjs has complex CRDT logic
      new_state = merge_yjs_updates(state.yjs_state, update)
      
      updated_state = %{state |
        yjs_state: new_state,
        updates: [update | state.updates]
      }
      
      {:reply, {:ok, :applied}, updated_state}
    rescue
      error ->
        Logger.error("Failed to apply Yjs update: #{inspect(error)}")
        {:reply, {:error, :invalid_update}, state}
    end
  end
  
  def handle_call(:get_content, _from, state) do
    # Extract text content from Yjs state
    content = extract_text_from_yjs_state(state.yjs_state)
    {:reply, {:ok, content}, state}
  end
  
  @impl true
  def handle_cast(:schedule_save, state) do
    # Cancel existing timer
    if state.save_timer do
      Process.cancel_timer(state.save_timer)
    end
    
    # Schedule new save
    timer = Process.send_after(self(), :save_document, @save_debounce_ms)
    
    {:noreply, %{state | save_timer: timer}}
  end
  
  @impl true
  def handle_info(:save_document, state) do
    Logger.debug("Saving document state for: #{state.document_id}")
    
    content = extract_text_from_yjs_state(state.yjs_state)
    
    case Documents.update_document_state(state.document_id, state.yjs_state, content) do
      {:ok, _document} ->
        Logger.debug("Document state saved successfully")
        
      {:error, reason} ->
        Logger.error("Failed to save document state: #{inspect(reason)}")
    end
    
    {:noreply, %{state | save_timer: nil, last_saved: DateTime.utc_now()}}
  end
  
  # Private functions
  
  defp via_tuple(document_id) do
    {:via, Registry, {@registry_name, document_id}}
  end
  
  defp get_or_start_process(document_id) do
    case Registry.lookup(@registry_name, document_id) do
      [{pid, _}] when is_pid(pid) ->
        {:ok, pid}
        
      [] ->
        # Start new process
        case DynamicSupervisor.start_child(
          CollaborativeEditor.YjsSyncSupervisor,
          {__MODULE__, document_id}
        ) do
          {:ok, pid} -> {:ok, pid}
          {:error, {:already_started, pid}} -> {:ok, pid}
          error -> error
        end
    end
  end
  
  defp merge_yjs_updates(current_state, new_update) do
    # Simplified merge logic - in reality, Yjs has complex CRDT merging
    # This would involve proper conflict resolution, operation transformation, etc.
    
    cond do
      byte_size(current_state) == 0 ->
        new_update
        
      byte_size(new_update) == 0 ->
        current_state
        
      true ->
        # Simple concatenation for demo - real Yjs merging is much more complex
        current_state <> new_update
    end
  end
  
  defp extract_text_from_yjs_state(yjs_state) when byte_size(yjs_state) == 0 do
    ""
  end
  
  defp extract_text_from_yjs_state(yjs_state) do
    # Simplified text extraction from Yjs state
    # In a real implementation, you'd parse the Yjs binary format
    try do
      case String.valid?(yjs_state) do
        true -> yjs_state
        false -> Base.encode64(yjs_state)
      end
    rescue
      _ -> ""
    end
  end
end