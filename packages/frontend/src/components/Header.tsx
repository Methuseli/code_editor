import React from 'react';
import { ConnectionStatus, SyncStatus } from '../hooks/useWebSocket';
import { Menu, Wifi, WifiOff, Cloud, CloudOff, AlertCircle } from 'lucide-react';
import { clsx } from 'clsx';

interface HeaderProps {
  connectionStatus: ConnectionStatus;
  syncStatus: SyncStatus;
  onToggleSidebar: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  connectionStatus,
  syncStatus,
  onToggleSidebar
}) => {
  const getConnectionIcon = () => {
    switch (connectionStatus) {
      case 'connected':
        return <Wifi className="w-4 h-4 text-green-500" />;
      case 'connecting':
        return <Wifi className="w-4 h-4 text-yellow-500 animate-pulse" />;
      case 'error':
        return <AlertCircle className="w-4 h-4 text-red-500" />;
      default:
        return <WifiOff className="w-4 h-4 text-gray-500" />;
    }
  };

  const getSyncIcon = () => {
    switch (syncStatus) {
      case 'synced':
        return <Cloud className="w-4 h-4 text-green-500" />;
      case 'syncing':
        return <Cloud className="w-4 h-4 text-blue-500 animate-pulse" />;
      case 'error':
        return <AlertCircle className="w-4 h-4 text-red-500" />;
      default:
        return <CloudOff className="w-4 h-4 text-gray-500" />;
    }
  };

  return (
    <header className="h-12 bg-gray-800 border-b border-gray-700 flex items-center justify-between px-4">
      <div className="flex items-center gap-4">
        <button
          onClick={onToggleSidebar}
          className="p-1 hover:bg-gray-700 rounded transition-colors"
          aria-label="Toggle sidebar"
        >
          <Menu className="w-5 h-5" />
        </button>
        
        <h1 className="text-lg font-semibold">Collaborative Editor</h1>
      </div>

      <div className="flex items-center gap-4">
        <div className="flex items-center gap-2">
          {getConnectionIcon()}
          <span className={clsx(
            'text-sm',
            {
              'text-green-500': connectionStatus === 'connected',
              'text-yellow-500': connectionStatus === 'connecting',
              'text-red-500': connectionStatus === 'error',
              'text-gray-500': connectionStatus === 'disconnected'
            }
          )}>
            {connectionStatus}
          </span>
        </div>

        <div className="flex items-center gap-2">
          {getSyncIcon()}
          <span className={clsx(
            'text-sm',
            {
              'text-green-500': syncStatus === 'synced',
              'text-blue-500': syncStatus === 'syncing',
              'text-red-500': syncStatus === 'error',
              'text-gray-500': syncStatus === 'offline'
            }
          )}>
            {syncStatus}
          </span>
        </div>
      </div>
    </header>
  );
};