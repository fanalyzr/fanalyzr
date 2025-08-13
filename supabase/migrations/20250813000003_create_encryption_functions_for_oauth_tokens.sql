-- MVP-29: Create Encryption Functions for OAuth Tokens
-- This migration creates encryption and decryption functions for secure storage of Yahoo OAuth tokens

-- Create encrypt_token function for secure token storage
CREATE OR REPLACE FUNCTION encrypt_token(token TEXT) 
RETURNS TEXT AS $$
BEGIN
  -- Use the encryption key from database settings
  RETURN encode(encrypt(token::bytea, current_setting('app.encryption_key')::bytea, 'aes'), 'base64');
EXCEPTION
  WHEN OTHERS THEN
    -- If encryption fails, return NULL and log error
    RAISE WARNING 'Encryption failed: %', SQLERRM;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create decrypt_token function for secure token retrieval
CREATE OR REPLACE FUNCTION decrypt_token(encrypted_token TEXT) 
RETURNS TEXT AS $$
BEGIN
  -- Use the encryption key from database settings
  RETURN convert_from(decrypt(decode(encrypted_token, 'base64'), current_setting('app.encryption_key')::bytea, 'aes'), 'utf8');
EXCEPTION
  WHEN OTHERS THEN
    -- If decryption fails, return NULL and log error
    RAISE WARNING 'Decryption failed: %', SQLERRM;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to safely store encrypted tokens
CREATE OR REPLACE FUNCTION store_encrypted_tokens(
  user_id UUID,
  access_token TEXT,
  refresh_token TEXT,
  expires_at TIMESTAMPTZ
) RETURNS BOOLEAN AS $$
BEGIN
  -- Encrypt tokens before storing
  UPDATE public.user_profiles 
  SET 
    yahoo_access_token = encrypt_token(access_token),
    yahoo_refresh_token = encrypt_token(refresh_token),
    token_expires_at = expires_at,
    updated_at = NOW()
  WHERE id = user_id;
  
  RETURN FOUND;
EXCEPTION
  WHEN OTHERS THEN
    RAISE WARNING 'Failed to store encrypted tokens: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to safely retrieve decrypted tokens
CREATE OR REPLACE FUNCTION get_decrypted_tokens(user_id UUID)
RETURNS TABLE(
  access_token TEXT,
  refresh_token TEXT,
  expires_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    decrypt_token(up.yahoo_access_token) as access_token,
    decrypt_token(up.yahoo_refresh_token) as refresh_token,
    up.token_expires_at as expires_at
  FROM public.user_profiles up
  WHERE up.id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comments for documentation
COMMENT ON FUNCTION encrypt_token(TEXT) IS 'Encrypts a token using AES encryption with the database encryption key';
COMMENT ON FUNCTION decrypt_token(TEXT) IS 'Decrypts an encrypted token using AES decryption with the database encryption key';
COMMENT ON FUNCTION store_encrypted_tokens(UUID, TEXT, TEXT, TIMESTAMPTZ) IS 'Safely stores encrypted OAuth tokens for a user';
COMMENT ON FUNCTION get_decrypted_tokens(UUID) IS 'Safely retrieves and decrypts OAuth tokens for a user';

-- Grant permissions to authenticated users
GRANT EXECUTE ON FUNCTION encrypt_token(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION decrypt_token(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION store_encrypted_tokens(UUID, TEXT, TEXT, TIMESTAMPTZ) TO authenticated;
GRANT EXECUTE ON FUNCTION get_decrypted_tokens(UUID) TO authenticated;
