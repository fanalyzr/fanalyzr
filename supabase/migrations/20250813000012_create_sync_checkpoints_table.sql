-- MVP-38: Create Sync Checkpoints Table
-- This migration creates the sync_checkpoints table for error recovery and sync progress tracking

-- Create sync_checkpoints table
CREATE TABLE IF NOT EXISTS public.sync_checkpoints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    league_id UUID NOT NULL REFERENCES public.leagues(id) ON DELETE CASCADE,
    sync_type TEXT NOT NULL,
    completed_steps TEXT[] DEFAULT '{}',
    current_step TEXT,
    error_message TEXT,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create unique constraint on league_id, sync_type combination
CREATE UNIQUE INDEX IF NOT EXISTS idx_sync_checkpoints_unique_combination 
ON public.sync_checkpoints(league_id, sync_type);

-- Create performance indexes
CREATE INDEX IF NOT EXISTS idx_sync_checkpoints_league_id ON public.sync_checkpoints(league_id);
CREATE INDEX IF NOT EXISTS idx_sync_checkpoints_sync_type ON public.sync_checkpoints(sync_type);
CREATE INDEX IF NOT EXISTS idx_sync_checkpoints_completed_at ON public.sync_checkpoints(completed_at);
CREATE INDEX IF NOT EXISTS idx_sync_checkpoints_started_at ON public.sync_checkpoints(started_at);
CREATE INDEX IF NOT EXISTS idx_sync_checkpoints_created_at ON public.sync_checkpoints(created_at);

-- Create GIN index for completed_steps array
CREATE INDEX IF NOT EXISTS idx_sync_checkpoints_completed_steps_gin ON public.sync_checkpoints USING GIN(completed_steps);

-- Add comments for documentation
COMMENT ON TABLE public.sync_checkpoints IS 'Tracks sync progress and error recovery for Yahoo Fantasy Sports data';
COMMENT ON COLUMN public.sync_checkpoints.id IS 'Primary key UUID';
COMMENT ON COLUMN public.sync_checkpoints.league_id IS 'Reference to league being synced';
COMMENT ON COLUMN public.sync_checkpoints.sync_type IS 'Type of sync operation (full, incremental, etc.)';
COMMENT ON COLUMN public.sync_checkpoints.completed_steps IS 'Array of completed sync steps';
COMMENT ON COLUMN public.sync_checkpoints.current_step IS 'Current step being processed';
COMMENT ON COLUMN public.sync_checkpoints.error_message IS 'Error message if sync failed';
COMMENT ON COLUMN public.sync_checkpoints.started_at IS 'When the sync operation started';
COMMENT ON COLUMN public.sync_checkpoints.completed_at IS 'When the sync operation completed';
COMMENT ON COLUMN public.sync_checkpoints.created_at IS 'Record creation timestamp';
COMMENT ON COLUMN public.sync_checkpoints.updated_at IS 'Record last update timestamp';

-- Enable Row Level Security
ALTER TABLE public.sync_checkpoints ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (users can access sync checkpoints for their own leagues)
CREATE POLICY "Users can view sync checkpoints in own leagues" ON public.sync_checkpoints
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = sync_checkpoints.league_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update sync checkpoints in own leagues" ON public.sync_checkpoints
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = sync_checkpoints.league_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert sync checkpoints in own leagues" ON public.sync_checkpoints
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = sync_checkpoints.league_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete sync checkpoints in own leagues" ON public.sync_checkpoints
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = sync_checkpoints.league_id 
      AND l.user_id = auth.uid()
    )
  );

-- Grant permissions
GRANT ALL ON TABLE public.sync_checkpoints TO authenticated;

-- Create trigger for updated_at
CREATE TRIGGER handle_sync_checkpoints_updated_at
  BEFORE UPDATE ON public.sync_checkpoints
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Create function to update sync checkpoint
CREATE OR REPLACE FUNCTION update_sync_checkpoint(
  p_league_id UUID,
  p_sync_type TEXT,
  p_current_step TEXT DEFAULT NULL,
  p_completed_step TEXT DEFAULT NULL,
  p_error_message TEXT DEFAULT NULL,
  p_is_complete BOOLEAN DEFAULT FALSE
) RETURNS BOOLEAN AS $$
BEGIN
  INSERT INTO public.sync_checkpoints (
    league_id, 
    sync_type, 
    current_step, 
    completed_steps, 
    error_message, 
    completed_at
  ) VALUES (
    p_league_id,
    p_sync_type,
    p_current_step,
    CASE WHEN p_completed_step IS NOT NULL THEN ARRAY[p_completed_step] ELSE '{}' END,
    p_error_message,
    CASE WHEN p_is_complete THEN NOW() ELSE NULL END
  )
  ON CONFLICT (league_id, sync_type) DO UPDATE SET
    current_step = COALESCE(p_current_step, sync_checkpoints.current_step),
    completed_steps = CASE 
      WHEN p_completed_step IS NOT NULL THEN sync_checkpoints.completed_steps || p_completed_step
      ELSE sync_checkpoints.completed_steps
    END,
    error_message = COALESCE(p_error_message, sync_checkpoints.error_message),
    completed_at = CASE WHEN p_is_complete THEN NOW() ELSE sync_checkpoints.completed_at END,
    updated_at = NOW();
  
  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Failed to update sync checkpoint: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comment for the function
COMMENT ON FUNCTION update_sync_checkpoint(UUID, TEXT, TEXT, TEXT, TEXT, BOOLEAN) IS 'Updates sync checkpoint for a league with current step, completed steps, and error information';

-- Grant execute permission
GRANT EXECUTE ON FUNCTION update_sync_checkpoint(UUID, TEXT, TEXT, TEXT, TEXT, BOOLEAN) TO authenticated;
