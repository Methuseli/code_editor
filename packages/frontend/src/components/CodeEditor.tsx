import React, { useRef, useEffect } from 'react';
import Editor from '@monaco-editor/react';
import { editor } from 'monaco-editor';
import { MonacoBinding } from 'y-monaco';
import * as Y from 'yjs';
import { WebsocketProvider } from 'y-websocket';
import { Awareness } from 'y-protocols/awareness';

interface CodeEditorProps {
  filePath: string;
  ydoc: Y.Doc;
  provider: WebsocketProvider | null;
  awareness: Awareness | null;
}

export const CodeEditor: React.FC<CodeEditorProps> = ({
  filePath,
  ydoc,
  provider,
  awareness
}) => {
  const editorRef = useRef<editor.IStandaloneCodeEditor | null>(null);
  const bindingRef = useRef<MonacoBinding | null>(null);

  const handleEditorDidMount = (editorInstance: editor.IStandaloneCodeEditor) => {
    editorRef.current = editorInstance;
    
    // Configure editor for collaboration
    editorInstance.updateOptions({
      fontSize: 14,
      fontFamily: 'JetBrains Mono, Consolas, Monaco, monospace',
      lineNumbers: 'on',
      minimap: { enabled: true },
      wordWrap: 'on',
      automaticLayout: true,
      scrollBeyondLastLine: false,
      renderWhitespace: 'selection',
    });

    // Set up collaborative editing if Yjs is available
    if (ydoc && awareness) {
      const ytext = ydoc.getText('monaco');
      
      bindingRef.current = new MonacoBinding(
        ytext,
        editorInstance.getModel()!,
        new Set([editorInstance]),
        awareness
      );
    }
  };

  useEffect(() => {
    return () => {
      // Clean up binding when component unmounts or file changes
      if (bindingRef.current) {
        bindingRef.current.destroy();
        bindingRef.current = null;
      }
    };
  }, [filePath]);

  const getLanguageFromFile = (fileName: string): string => {
    const extension = fileName.split('.').pop()?.toLowerCase();
    const languageMap: Record<string, string> = {
      js: 'javascript',
      jsx: 'javascript',
      ts: 'typescript',
      tsx: 'typescript',
      py: 'python',
      rb: 'ruby',
      go: 'go',
      rs: 'rust',
      java: 'java',
      cpp: 'cpp',
      c: 'c',
      cs: 'csharp',
      php: 'php',
      html: 'html',
      css: 'css',
      scss: 'scss',
      sass: 'sass',
      json: 'json',
      xml: 'xml',
      yaml: 'yaml',
      yml: 'yaml',
      md: 'markdown',
      sql: 'sql',
      sh: 'shell',
      bash: 'shell',
      dockerfile: 'dockerfile',
    };
    return languageMap[extension || ''] || 'plaintext';
  };

  return (
    <div className="h-full w-full">
      <Editor
        height="100%"
        language={getLanguageFromFile(filePath)}
        theme="vs-dark"
        onMount={handleEditorDidMount}
        options={{
          selectOnLineNumbers: true,
          matchBrackets: 'near',
          autoClosingBrackets: 'always',
          autoClosingQuotes: 'always',
          autoIndent: 'full',
          formatOnPaste: true,
          formatOnType: true,
          suggestOnTriggerCharacters: true,
          quickSuggestions: true,
          parameterHints: { enabled: true },
          hover: { enabled: true },
        }}
        loading={
          <div className="flex items-center justify-center h-full">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
          </div>
        }
      />
    </div>
  );
};