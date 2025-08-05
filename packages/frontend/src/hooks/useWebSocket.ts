import { useEffect, useRef, useState, useCallback } from 'react';
import { Socket } from 'phoenix';

export type ConnectionStatus = 'connecting' | 'connected' | 'disconnected' | 'error';

export interface UseWebSocketReturn {
  socket: Socket | null;
  connectionStatus: ConnectionStatus;
  joinRoom: (room: string) => void;
  leaveRoom: (room: string) => void;
  sendMessage: (topic: string, event: string, payload: any) => void;
}

export const useWebSocket = (url: string): UseWebSocketReturn => {
  const [socket, setSocket] = useState<Socket | null>(null);
  const [connectionStatus, setConnectionStatus] = useState<ConnectionStatus>('connecting');
  const channelsRef = useRef<Map<string, any>>(new Map());

  // Initialize socket connection
  useEffect(() => {
    const socketInstance = new Socket(url, {
      params: {
        token: localStorage.getItem('auth_token') || 'anonymous'
      },
      reconnectAfterMs: (tries: number) => {
        return [1000, 2000, 5000, 10000][tries - 1] || 10000;
      },
      logger: (kind: string, msg: string, data: any) => {
        console.log(`Phoenix ${kind}: ${msg}`, data);
      }
    });

    // Connection event handlers
    socketInstance.onOpen(() => {
      console.log('WebSocket connected');
      setConnectionStatus('connected');
    });

    socketInstance.onClose(() => {
      console.log('WebSocket disconnected');
      setConnectionStatus('disconnected');
    });

    socketInstance.onError((error: any) => {
      console.error('WebSocket error:', error);
      setConnectionStatus('error');
    });

    // Connect to socket
    setConnectionStatus('connecting');
    socketInstance.connect();
    setSocket(socketInstance);

    // Cleanup on unmount
    return () => {
      // Leave all channels
      channelsRef.current.forEach((channel) => {
        channel.leave();
      });
      channelsRef.current.clear();
      
      // Disconnect socket
      socketInstance.disconnect();
      setSocket(null);
    };
  }, [url]);

  const joinRoom = useCallback((room: string) => {
    if (!socket) return;

    // Leave existing channel if already joined
    if (channelsRef.current.has(room)) {
      channelsRef.current.get(room).leave();
    }

    const channel = socket.channel(room, {});
    
    channel.join()
      .receive('ok', (resp: any) => {
        console.log(`Joined ${room} successfully`, resp);
      })
      .receive('error', (resp: any) => {
        console.error(`Unable to join ${room}`, resp);
      });

    // Handle document synchronization events
    channel.on('document_update', (payload: any) => {
      console.log('Document update received:', payload);
    });

    channel.on('user_joined', (payload: any) => {
      console.log('User joined:', payload);
    });

    channel.on('user_left', (payload: any) => {
      console.log('User left:', payload);
    });

    channel.on('cursor_update', (payload: any) => {
      console.log('Cursor update:', payload);
    });

    channelsRef.current.set(room, channel);
  }, [socket]);

  const leaveRoom = useCallback((room: string) => {
    const channel = channelsRef.current.get(room);
    if (channel) {
      channel.leave();
      channelsRef.current.delete(room);
      console.log(`Left room: ${room}`);
    }
  }, []);

  const sendMessage = useCallback((topic: string, event: string, payload: any) => {
    const channel = channelsRef.current.get(topic);
    if (channel) {
      channel.push(event, payload)
        .receive('ok', (resp: any) => {
          console.log('Message sent successfully:', resp);
        })
        .receive('error', (resp: any) => {
          console.error('Failed to send message:', resp);
        });
    }
  }, []);

  return {
    socket,
    connectionStatus,
    joinRoom,
    leaveRoom,
    sendMessage
  };
};