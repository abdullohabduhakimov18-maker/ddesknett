/*
  # Initial Database Schema for Desknet Platform

  ## Overview
  This migration creates the foundational database structure for the Desknet global engineering network platform, supporting IT talent management, client-engineer matching, and project coordination.

  ## New Tables Created

  ### 1. `users`
  Core user profiles for all platform participants (clients, engineers, admins)
  - `uid` (uuid, primary key) - Unique user identifier
  - `email` (text, unique) - User email address
  - `name` (text) - User's display name
  - `role` (text) - User role: admin, client, or engineer
  - `phone` (text) - Contact phone number
  - `profile_pic` (text) - Profile picture URL
  - `country` (text) - User's country
  - `city` (text) - User's city
  - `skills` (text[]) - Array of technical skills (for engineers)
  - `payment_details` (jsonb) - Payment information (bank details, etc.)
  - `notifications` (jsonb) - Notification preferences
  - `created_at` (timestamptz) - Account creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### 2. `jobs`
  Job postings and opportunities
  - `id` (uuid, primary key)
  - `title` (text) - Job title
  - `company` (text) - Company name
  - `location` (text) - Job location
  - `type` (text) - Job type (full-time, contract, etc.)
  - `salary` (text) - Salary range
  - `description` (text) - Job description
  - `requirements` (text[]) - Array of requirements
  - `status` (text) - Job status (open, closed)
  - `posted_by` (uuid) - User who posted the job
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### 3. `messages`
  Direct messages between users
  - `id` (uuid, primary key)
  - `chat_id` (text) - Chat identifier (sorted user IDs)
  - `sender_id` (uuid) - Message sender
  - `receiver_id` (uuid) - Message receiver
  - `content` (text) - Message content
  - `sender_name` (text) - Sender's name
  - `unread` (boolean) - Read status
  - `file_url` (text) - Attachment URL
  - `file_type` (text) - Attachment type
  - `file_name` (text) - Attachment filename
  - `is_ai` (boolean) - AI-generated message flag
  - `timestamp` (timestamptz)

  ### 4. `notifications`
  User notifications
  - `id` (uuid, primary key)
  - `user_id` (uuid) - Notification recipient
  - `type` (text) - Notification type (message, ticket, system, etc.)
  - `title` (text) - Notification title
  - `message` (text) - Notification message
  - `link` (text) - Associated link
  - `read` (boolean) - Read status
  - `created_at` (timestamptz)

  ### 5. `tickets`
  IT support tickets
  - `id` (uuid, primary key)
  - `client_uid` (uuid) - Client who created ticket
  - `client_name` (text) - Client name
  - `contact_email` (text) - Contact email
  - `subject` (text) - Ticket subject
  - `description` (text) - Ticket description
  - `service_type` (text) - Type of service
  - `priority` (text) - Priority level
  - `status` (text) - Ticket status
  - `country` (text) - Service location country
  - `city` (text) - Service location city
  - `location` (text) - Specific location details
  - `date_time` (timestamptz) - Scheduled date/time
  - `estimated_duration` (text) - Estimated duration
  - `attachments` (jsonb) - Attached files
  - `special_instructions` (text) - Special instructions
  - `quote` (jsonb) - Quote information
  - `engineer_name` (text) - Assigned engineer name
  - `engineer_email` (text) - Assigned engineer email
  - `engineer_phone` (text) - Assigned engineer phone
  - `engineer_location_from` (text) - Engineer travel origin
  - `engineer_attachments` (jsonb) - Engineer-provided attachments
  - `updates` (jsonb) - Ticket updates/activity log
  - `is_on_site` (boolean) - Engineer on-site flag
  - `on_site_at` (timestamptz) - On-site arrival time
  - `completed_at` (timestamptz) - Completion time
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### 6. `quotations`
  Project quotations
  - `id` (uuid, primary key)
  - `client_uid` (uuid) - Client requesting quote
  - `client_name` (text) - Client name
  - `client_email` (text) - Client email
  - `project` (text) - Project name
  - `description` (text) - Project description
  - `amount` (text) - Quote amount
  - `currency` (text) - Currency (USD, EUR)
  - `status` (text) - Quote status (Draft, Sent, Approved, Rejected)
  - `ticket_id` (uuid) - Associated ticket ID
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### 7. `invoices`
  Billing invoices
  - `id` (uuid, primary key)
  - `client_name` (text) - Client name
  - `client_email` (text) - Client email
  - `amount` (text) - Invoice amount
  - `status` (text) - Invoice status (Paid, Pending, Overdue)
  - `due_date` (text) - Payment due date
  - `description` (text) - Invoice description
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### 8. `presence`
  Real-time user presence
  - `id` (uuid, primary key)
  - `online` (boolean) - Online status
  - `display_name` (text) - User display name
  - `last_seen` (timestamptz) - Last activity timestamp

  ### 9. `typing`
  Typing indicators for chat
  - `id` (text, primary key) - Chat identifier
  - `is_typing` (boolean) - Typing status

  ## Security
  All tables have Row Level Security (RLS) enabled with restrictive policies:
  - Users can only access their own data or data they're authorized to see
  - Admin users have broader access
  - Authentication is required for all operations
  - Public access is denied by default

  ## Important Notes
  - All timestamps use UTC timezone
  - UUIDs are auto-generated for primary keys
  - JSONB columns allow flexible schema for complex data
  - Indexes are created on frequently queried columns
*/

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- USERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
  uid uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  email text UNIQUE NOT NULL,
  name text,
  role text NOT NULL DEFAULT 'client' CHECK (role IN ('admin', 'client', 'engineer')),
  phone text,
  profile_pic text,
  country text,
  city text,
  skills text[],
  payment_details jsonb,
  notifications jsonb DEFAULT '{"email": true, "push": true, "sms": false, "marketing": false}'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  TO authenticated
  USING (auth.uid() = uid);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = uid)
  WITH CHECK (auth.uid() = uid);

-- Admin users can view all users
CREATE POLICY "Admins can view all users"
  ON users FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Admin users can update any user
CREATE POLICY "Admins can update any user"
  ON users FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- ============================================================================
-- JOBS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS jobs (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  title text NOT NULL,
  company text NOT NULL,
  location text,
  type text NOT NULL,
  salary text,
  description text NOT NULL,
  requirements text[],
  status text DEFAULT 'open' CHECK (status IN ('open', 'closed')),
  posted_by uuid REFERENCES users(uid) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can view open jobs
CREATE POLICY "Authenticated users can view open jobs"
  ON jobs FOR SELECT
  TO authenticated
  USING (status = 'open');

-- Job posters can view their own jobs
CREATE POLICY "Users can view own jobs"
  ON jobs FOR SELECT
  TO authenticated
  USING (posted_by = auth.uid());

-- Admin and clients can create jobs
CREATE POLICY "Admins and clients can create jobs"
  ON jobs FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = posted_by AND
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role IN ('admin', 'client')
    )
  );

-- Job posters can update their own jobs
CREATE POLICY "Users can update own jobs"
  ON jobs FOR UPDATE
  TO authenticated
  USING (posted_by = auth.uid())
  WITH CHECK (posted_by = auth.uid());

-- Job posters can delete their own jobs
CREATE POLICY "Users can delete own jobs"
  ON jobs FOR DELETE
  TO authenticated
  USING (posted_by = auth.uid());

CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_posted_by ON jobs(posted_by);

-- ============================================================================
-- MESSAGES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS messages (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  chat_id text NOT NULL,
  sender_id uuid NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  receiver_id uuid NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  content text NOT NULL,
  sender_name text,
  unread boolean DEFAULT true,
  file_url text,
  file_type text,
  file_name text,
  is_ai boolean DEFAULT false,
  timestamp timestamptz DEFAULT now()
);

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Users can view messages they sent or received
CREATE POLICY "Users can view own messages"
  ON messages FOR SELECT
  TO authenticated
  USING (sender_id = auth.uid() OR receiver_id = auth.uid());

-- Users can send messages
CREATE POLICY "Users can send messages"
  ON messages FOR INSERT
  TO authenticated
  WITH CHECK (sender_id = auth.uid());

-- Users can update messages they received (mark as read)
CREATE POLICY "Users can update received messages"
  ON messages FOR UPDATE
  TO authenticated
  USING (receiver_id = auth.uid())
  WITH CHECK (receiver_id = auth.uid());

-- Users can delete their own messages
CREATE POLICY "Users can delete own messages"
  ON messages FOR DELETE
  TO authenticated
  USING (sender_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages(timestamp);

-- ============================================================================
-- NOTIFICATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  type text NOT NULL,
  title text NOT NULL,
  message text NOT NULL,
  link text,
  read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users can view their own notifications
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- System can create notifications
CREATE POLICY "Authenticated users can create notifications"
  ON notifications FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Users can update their own notifications
CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(read);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at);

-- ============================================================================
-- TICKETS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS tickets (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_uid uuid NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  client_name text NOT NULL,
  contact_email text NOT NULL,
  subject text NOT NULL,
  description text NOT NULL,
  service_type text NOT NULL,
  priority text NOT NULL,
  status text DEFAULT 'Open',
  country text,
  city text,
  location text,
  date_time timestamptz,
  estimated_duration text,
  attachments jsonb,
  special_instructions text,
  quote jsonb,
  engineer_name text,
  engineer_email text,
  engineer_phone text,
  engineer_location_from text,
  engineer_attachments jsonb,
  updates jsonb DEFAULT '[]'::jsonb,
  is_on_site boolean DEFAULT false,
  on_site_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;

-- Clients can view their own tickets
CREATE POLICY "Clients can view own tickets"
  ON tickets FOR SELECT
  TO authenticated
  USING (client_uid = auth.uid());

-- Admins can view all tickets
CREATE POLICY "Admins can view all tickets"
  ON tickets FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Clients can create tickets
CREATE POLICY "Clients can create tickets"
  ON tickets FOR INSERT
  TO authenticated
  WITH CHECK (client_uid = auth.uid());

-- Clients can update their own tickets
CREATE POLICY "Clients can update own tickets"
  ON tickets FOR UPDATE
  TO authenticated
  USING (client_uid = auth.uid())
  WITH CHECK (client_uid = auth.uid());

-- Admins can update any ticket
CREATE POLICY "Admins can update any ticket"
  ON tickets FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Clients can delete their own tickets
CREATE POLICY "Clients can delete own tickets"
  ON tickets FOR DELETE
  TO authenticated
  USING (client_uid = auth.uid());

CREATE INDEX IF NOT EXISTS idx_tickets_client ON tickets(client_uid);
CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status);
CREATE INDEX IF NOT EXISTS idx_tickets_created ON tickets(created_at);

-- ============================================================================
-- QUOTATIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS quotations (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_uid uuid NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  client_name text NOT NULL,
  client_email text,
  project text NOT NULL,
  description text NOT NULL,
  amount text DEFAULT 'TBD',
  currency text DEFAULT 'USD',
  status text DEFAULT 'Draft',
  ticket_id uuid REFERENCES tickets(id) ON DELETE SET NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE quotations ENABLE ROW LEVEL SECURITY;

-- Clients can view their own quotations
CREATE POLICY "Clients can view own quotations"
  ON quotations FOR SELECT
  TO authenticated
  USING (client_uid = auth.uid());

-- Admins can view all quotations
CREATE POLICY "Admins can view all quotations"
  ON quotations FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Clients can create quotations
CREATE POLICY "Clients can create quotations"
  ON quotations FOR INSERT
  TO authenticated
  WITH CHECK (client_uid = auth.uid());

-- Admins can create quotations
CREATE POLICY "Admins can create quotations"
  ON quotations FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Clients can update their own quotations
CREATE POLICY "Clients can update own quotations"
  ON quotations FOR UPDATE
  TO authenticated
  USING (client_uid = auth.uid())
  WITH CHECK (client_uid = auth.uid());

-- Admins can update any quotation
CREATE POLICY "Admins can update any quotation"
  ON quotations FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Admins can delete quotations
CREATE POLICY "Admins can delete quotations"
  ON quotations FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
    )
  );

CREATE INDEX IF NOT EXISTS idx_quotations_client ON quotations(client_uid);
CREATE INDEX IF NOT EXISTS idx_quotations_status ON quotations(status);

-- ============================================================================
-- INVOICES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS invoices (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_name text NOT NULL,
  client_email text NOT NULL,
  amount text NOT NULL,
  status text DEFAULT 'Pending',
  due_date text,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

-- Admins can view all invoices
CREATE POLICY "Admins can view all invoices"
  ON invoices FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Admins can create invoices
CREATE POLICY "Admins can create invoices"
  ON invoices FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Admins can update invoices
CREATE POLICY "Admins can update invoices"
  ON invoices FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
    )
  );

-- Admins can delete invoices
CREATE POLICY "Admins can delete invoices"
  ON invoices FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE users.uid = auth.uid()
      AND users.role = 'admin'
    )
  );

CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);

-- ============================================================================
-- PRESENCE TABLE (Real-time user status)
-- ============================================================================
CREATE TABLE IF NOT EXISTS presence (
  id uuid PRIMARY KEY REFERENCES users(uid) ON DELETE CASCADE,
  online boolean DEFAULT false,
  display_name text,
  last_seen timestamptz DEFAULT now()
);

ALTER TABLE presence ENABLE ROW LEVEL SECURITY;

-- All authenticated users can view presence
CREATE POLICY "Authenticated users can view presence"
  ON presence FOR SELECT
  TO authenticated
  USING (true);

-- Users can update their own presence
CREATE POLICY "Users can update own presence"
  ON presence FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- Users can update their own presence
CREATE POLICY "Users can update own presence status"
  ON presence FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- ============================================================================
-- TYPING TABLE (Chat typing indicators)
-- ============================================================================
CREATE TABLE IF NOT EXISTS typing (
  id text PRIMARY KEY,
  is_typing boolean DEFAULT false
);

ALTER TABLE typing ENABLE ROW LEVEL SECURITY;

-- All authenticated users can view typing status
CREATE POLICY "Authenticated users can view typing"
  ON typing FOR SELECT
  TO authenticated
  USING (true);

-- Users can set typing status
CREATE POLICY "Users can set typing status"
  ON typing FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Users can update typing status
CREATE POLICY "Users can update typing status"
  ON typing FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to relevant tables
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_users_updated_at') THEN
    CREATE TRIGGER update_users_updated_at
      BEFORE UPDATE ON users
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_jobs_updated_at') THEN
    CREATE TRIGGER update_jobs_updated_at
      BEFORE UPDATE ON jobs
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_tickets_updated_at') THEN
    CREATE TRIGGER update_tickets_updated_at
      BEFORE UPDATE ON tickets
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_quotations_updated_at') THEN
    CREATE TRIGGER update_quotations_updated_at
      BEFORE UPDATE ON quotations
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_invoices_updated_at') THEN
    CREATE TRIGGER update_invoices_updated_at
      BEFORE UPDATE ON invoices
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  END IF;
END $$;