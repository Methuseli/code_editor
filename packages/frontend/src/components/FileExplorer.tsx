import React, { useState, useEffect } from 'react';
import { Folder, File, FolderOpen, ChevronRight, ChevronDown } from 'lucide-react';
import { clsx } from 'clsx';

interface FileNode {
  name: string;
  path: string;
  type: 'file' | 'folder';
  children?: FileNode[];
}

interface FileItemProps {
  node: FileNode;
  level: number;
  onFileSelect: (path: string) => void;
  activeFile: string | null;
}

const FileItem: React.FC<FileItemProps> = ({ node, level, onFileSelect, activeFile }) => {
  const [isOpen, setIsOpen] = useState(level === 0);

  const handleClick = () => {
    if (node.type === 'folder') {
      setIsOpen(!isOpen);
    } else {
      onFileSelect(node.path);
    }
  };

  const isActive = activeFile === node.path;

  return (
    <div>
      <div
        className={clsx(
          'flex items-center gap-2 py-1 px-2 cursor-pointer hover:bg-gray-700 transition-colors',
          {
            'bg-blue-600 hover:bg-blue-500': isActive
          }
        )}
        style={{ paddingLeft: `${level * 16 + 8}px` }}
        onClick={handleClick}
      >
        {node.type === 'folder' && (
          <div className="w-4 h-4 flex items-center justify-center">
            {isOpen ? (
              <ChevronDown className="w-3 h-3" />
            ) : (
              <ChevronRight className="w-3 h-3" />
            )}
          </div>
        )}
        
        <div className="w-4 h-4 flex items-center justify-center">
          {node.type === 'folder' ? (
            isOpen ? (
              <FolderOpen className="w-4 h-4 text-blue-400" />
            ) : (
              <Folder className="w-4 h-4 text-blue-400" />
            )
          ) : (
            <File className="w-4 h-4 text-gray-400" />
          )}
        </div>
        
        <span className="text-sm truncate">{node.name}</span>
      </div>
      
      {node.type === 'folder' && isOpen && node.children && (
        <div>
          {node.children.map((child) => (
            <FileItem
              key={child.path}
              node={child}
              level={level + 1}
              onFileSelect={onFileSelect}
              activeFile={activeFile}
            />
          ))}
        </div>
      )}
    </div>
  );
};

interface FileExplorerProps {
  onFileSelect: (path: string) => void;
  activeFile: string | null;
}

export const FileExplorer: React.FC<FileExplorerProps> = ({ onFileSelect, activeFile }) => {
  const [fileStructure, setFileStructure] = useState<FileNode[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch file structure from API
  useEffect(() => {
    const fetchFiles = async () => {
      setLoading(true);
      setError(null);
      try {
        const res = await fetch('/api/files');
        if (!res.ok) throw new Error('Failed to load files');
        const data = await res.json();
        setFileStructure(data);
      } catch (err: any) {
        setError(err.message || 'Unknown error');
      } finally {
        setLoading(false);
      }
    };
    fetchFiles();
  }, []);

  // Optionally, add a websocket or polling here for collaboration updates

  return (
    <div className="flex flex-col h-full">
      <div className="p-3 border-b border-gray-700">
        <h3 className="text-sm font-medium text-gray-300">EXPLORER</h3>
      </div>
      <div className="flex-1 overflow-y-auto">
        {loading && <div className="p-3 text-gray-400 text-sm">Loading files...</div>}
        {error && <div className="p-3 text-red-400 text-sm">{error}</div>}
        {!loading && !error && fileStructure.map((node) => (
          <FileItem
            key={node.path}
            node={node}
            level={0}
            onFileSelect={onFileSelect}
            activeFile={activeFile}
          />
        ))}
      </div>
    </div>
  );
};