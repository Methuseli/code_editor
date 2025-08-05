import React from 'react';
import { CollaborationUser } from '../hooks/useCollaboration';
import { clsx } from 'clsx';

interface UserPresenceProps {
  users: CollaborationUser[];
  className?: string;
}

export const UserPresence: React.FC<UserPresenceProps> = ({ users, className }) => {
  if (users.length === 0) return null;

  return (
    <div className={clsx('flex items-center gap-2', className)}>
      <span className="text-xs text-gray-400">Online:</span>
      <div className="flex items-center gap-1">
        {users.slice(0, 5).map((user) => (
          <div
            key={user.id}
            className="flex items-center gap-1 px-2 py-1 bg-gray-700 rounded-md text-xs"
            title={user.name}
          >
            <div
              className="w-2 h-2 rounded-full"
              style={{ backgroundColor: user.color }}
            />
            <span className="max-w-20 truncate">{user.name}</span>
          </div>
        ))}
        {users.length > 5 && (
          <div className="px-2 py-1 bg-gray-700 rounded-md text-xs text-gray-400">
            +{users.length - 5} more
          </div>
        )}
      </div>
    </div>
  );
};