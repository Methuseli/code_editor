import { useEffect, useState, useRef } from 'react';
import * as Y from 'yjs';
import { WebsocketProvider } from 'y-websocket';
import { Awareness } from 'y-protocols/awareness';
import { Socket } from 'phoenix';

export type SyncStatus = 'syncing' | 'synced' | 'error' | 'offline';

export interface CollaborationUser {
  id: string;
  name: string;
  color: string;
  cursor?: {
    line: number;
    column: number;
  };
}

export interface UseCollaborationReturn {
  ydoc: Y.Doc;
  provider: WebsocketProvider | null;
  awareness: Awareness | null;
  users: CollaborationUser[];
  syncStatus: SyncStatus;
}

export const useCollaboration = (
  socket: Socket | null,
  documentId: string | null
): UseCollaborationReturn => {
  const [ydoc] = useState(() => new Y.Doc());
  const [provider, setProvider] = useState<WebsocketProvider | null>(null);
  const [awareness, setAwareness] = useState<Awareness | null>(null);
  const [users, setUsers] = useState<CollaborationUser[]>([]);
  const [syncStatus, setSyncStatus] = useState<SyncStatus>('offline');
  
  const providerRef = useRef<WebsocketProvider | null>(null);

  // Initialize Yjs provider when document changes
  useEffect(() => {
    if (!documentId) {
      // Clean up existing provider
      if (providerRef.current) {
        providerRef.current.destroy();
        providerRef.current = null;
        setProvider(null);
        setAwareness(null);
        setUsers([]);
        setSyncStatus('offline');
      }
      return;
    }

    // Create new WebSocket provider for Yjs
    const wsProvider = new WebsocketProvider(
      'ws://localhost:4000/yjs',
      documentId,
      ydoc,
      {
        connect: true,
        awareness: new Awareness(ydoc),
        params: {
          token: localStorage.getItem('auth_token') || 'anonymous'
        }
      }
    );

    // Set up awareness (for showing cursors and user presence)
    const awarenessInstance = wsProvider.awareness;
    
    // Set local user info
    awarenessInstance.setLocalStateField('user', {
      id: crypto.randomUUID(),
      name: localStorage.getItem('username') || 'Anonymous User',
      color: `hsl(${Math.random() * 360}, 70%, 60%)`
    });

    // Provider event handlers
    wsProvider.on('status', (event: { status: string }) => {
      console.log('Yjs provider status:', event.status);
      switch (event.status) {
        case 'connecting':
          setSyncStatus('syncing');
          break;
        case 'connected':
          setSyncStatus('synced');
          break;
        case 'disconnected':
          setSyncStatus('offline');
          break;
        default:
          setSyncStatus('error');
      }
    });

    wsProvider.on('sync', (isSynced: boolean) => {
      console.log('Yjs document synced:', isSynced);
      setSyncStatus(isSynced ? 'synced' : 'syncing');
    });

    // Awareness event handlers
    awarenessInstance.on('change', () => {
      const states = awarenessInstance.getStates();
      const collaborators: CollaborationUser[] = [];
      
      states.forEach((state, clientId) => {
        if (clientId !== awarenessInstance.clientID && state.user) {
          collaborators.push({
            id: state.user.id,
            name: state.user.name,
            color: state.user.color,
            cursor: state.cursor
          });
        }
      });
      
      setUsers(collaborators);
    });

    // Store references
    providerRef.current = wsProvider;
    setProvider(wsProvider);
    setAwareness(awarenessInstance);
    setSyncStatus('syncing');

    // Cleanup function
    return () => {
      if (providerRef.current) {
        providerRef.current.destroy();
        providerRef.current = null;
      }
    };
  }, [documentId, ydoc]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (providerRef.current) {
        providerRef.current.destroy();
      }
      ydoc.destroy();
    };
  }, [ydoc]);

  return {
    ydoc,
    provider,
    awareness,
    users,
    syncStatus
  };
};