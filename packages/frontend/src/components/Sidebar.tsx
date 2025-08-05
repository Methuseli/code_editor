import React from 'react';
import { clsx } from 'clsx';

interface SidebarProps {
  children: React.ReactNode;
  className?: string;
}

export const Sidebar: React.FC<SidebarProps> = ({ children, className }) => {
  return (
    <aside className={clsx(
      'bg-gray-800 flex flex-col overflow-hidden',
      className
    )}>
      {children}
    </aside>
  );
};