import React, { useEffect, useState } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { CodeEditor } from './components/CodeEditor';
import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { useWebSocket } from './hooks/useWebSocket';
import { useCollaboration } from './hooks/useCollaboration';
import { FileExplorer } from './components/FileExplorer';
import { UserPresence } from './components/UserPresence';
import { Toast } from './components/Toast';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 2,
      staleTime: 5 * 60 * 1000, // 5 minutes
    },
  },
});

function AppContent() {
  const [activeFile, setActiveFile] = useState<string | null>(null);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  
  const { 
    socket, 
    connectionStatus, 
    joinRoom, 
    leaveRoom 
  } = useWebSocket('ws://localhost:4000/socket');
  
  const {
    ydoc,
    provider,
    awareness,
    users,
    syncStatus
  } = useCollaboration(socket, activeFile);

  useEffect(() => {
    if (activeFile && socket) {
      joinRoom(`document:${activeFile}`);
      return () => leaveRoom(`document:${activeFile}`);
    }
  }, [activeFile, socket, joinRoom, leaveRoom]);

  const handleFileSelect = (filePath: string) => {
    if (activeFile && activeFile !== filePath) {
      leaveRoom(`document:${activeFile}`);
    }
    setActiveFile(filePath);
  };

  return (
    <div className="min-h-screen w-full flex flex-col bg-gray-900 text-white">
      <Header 
        connectionStatus={connectionStatus}
        syncStatus={syncStatus}
        onToggleSidebar={() => setSidebarOpen(!sidebarOpen)}
      />
      
      <div className="flex flex-1 overflow-hidden">
        {sidebarOpen && (
          <Sidebar className="w-64 border-r border-gray-700">
            <FileExplorer 
              onFileSelect={handleFileSelect}
              activeFile={activeFile}
            />
          </Sidebar>
        )}
        
        <div className="flex-1 flex flex-col">
          <div className="flex-1 relative">
            {activeFile ? (
              <CodeEditor
                filePath={activeFile}
                ydoc={ydoc}
                provider={provider}
                awareness={awareness}
              />
            ) : (
              <div className="flex items-center justify-center h-full text-gray-400">
                <div className="text-center">
                  <h2 className="text-2xl font-semibold mb-2">Welcome to Collaborative Editor</h2>
                  <p>Select a file from the sidebar to start editing</p>
                </div>
              </div>
            )}
          </div>
          
          {users.length > 0 && (
            <UserPresence users={users} className="border-t border-gray-700 p-2" />
          )}
        </div>
      </div>
      
      <Toast />
    </div>
  );
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AppContent />
    </QueryClientProvider>
  );
}

export default App;