/*
  # Create documents table

  1. New Tables
    - `documents`
      - `id` (string, primary key) - Document identifier
      - `title` (string) - Document title
      - `content` (text) - Current document content
      - `language` (string) - Programming language for syntax highlighting
      - `yjs_state` (bytea) - Binary Yjs CRDT state
      - `metadata` (jsonb) - Additional document metadata
      - `inserted_at` (timestamp) - Creation timestamp
      - `updated_at` (timestamp) - Last modification timestamp

  2. Security
    - Enable RLS on `documents` table
    - Add policy for authenticated users to read/write documents
    - Add policy for anonymous users to read/write documents (demo purposes)

  3. Indexes
    - Primary key on `id`
    - Index on `updated_at` for sorting
    - GIN index on `metadata` for JSON queries
*/

-- Create documents table
CREATE TABLE IF NOT EXISTS documents (
  id VARCHAR(255) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  content TEXT DEFAULT '',
  language VARCHAR(50) DEFAULT 'javascript',
  yjs_state BYTEA DEFAULT '',
  metadata JSONB DEFAULT '{}',
  inserted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS documents_updated_at_idx ON documents (updated_at DESC);
CREATE INDEX IF NOT EXISTS documents_metadata_idx ON documents USING GIN (metadata);
CREATE INDEX IF NOT EXISTS documents_language_idx ON documents (language);

-- Enable Row Level Security
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow all operations for authenticated users"
  ON documents
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Allow all operations for anonymous users"
  ON documents
  FOR ALL
  TO anon
  USING (true)
  WITH CHECK (true);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_documents_updated_at
  BEFORE UPDATE ON documents
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();