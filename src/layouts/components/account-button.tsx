import type { IconButtonProps } from '@mui/material/IconButton';

import { m } from 'framer-motion';

import Avatar from '@mui/material/Avatar';
import IconButton from '@mui/material/IconButton';

import { varTap, varHover, AnimateBorder, transitionTap } from 'src/components/animate';

// ----------------------------------------------------------------------

export type AccountButtonProps = IconButtonProps & {
  photoURL: string;
  displayName: string;
};

// Helper function to get initials from display name
function getInitials(name: string): string {
  if (!name) return '';
  
  const parts = name.trim().split(' ');
  if (parts.length === 1) {
    return parts[0].charAt(0).toUpperCase();
  }
  
  return (parts[0].charAt(0) + parts[parts.length - 1].charAt(0)).toUpperCase();
}

export function AccountButton({ photoURL, displayName, sx, ...other }: AccountButtonProps) {
  const initials = getInitials(displayName);

  return (
    <IconButton
      component={m.button}
      whileTap={varTap(0.96)}
      whileHover={varHover(1.04)}
      transition={transitionTap()}
      aria-label="Account button"
      sx={[{ p: 0 }, ...(Array.isArray(sx) ? sx : [sx])]}
      {...other}
    >
      <AnimateBorder
        sx={{ p: '3px', borderRadius: '50%', width: 40, height: 40 }}
        slotProps={{
          primaryBorder: { size: 60, width: '1px', sx: { color: 'primary.main' } },
          secondaryBorder: { sx: { color: 'warning.main' } },
        }}
      >
        <Avatar 
          alt={displayName}
          sx={{ 
            width: 1, 
            height: 1,
            bgcolor: 'background.paper',
            color: 'text.primary',
            fontSize: '0.875rem',
            fontWeight: 600
          }}
        >
          {initials}
        </Avatar>
      </AnimateBorder>
    </IconButton>
  );
}
