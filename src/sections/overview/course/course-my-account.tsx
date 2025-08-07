import type { CardProps } from '@mui/material/Card';

import Box from '@mui/material/Box';
import Card from '@mui/material/Card';
import Avatar from '@mui/material/Avatar';
import IconButton from '@mui/material/IconButton';
import Typography from '@mui/material/Typography';

import { Iconify } from 'src/components/iconify';
import { AnimateBorder } from 'src/components/animate';

import { useAuthContext } from 'src/auth/hooks';

// ----------------------------------------------------------------------

// Helper function to get initials from display name
function getInitials(name: string): string {
  if (!name) return '';
  
  const parts = name.trim().split(' ');
  if (parts.length === 1) {
    return parts[0].charAt(0).toUpperCase();
  }
  
  return (parts[0].charAt(0) + parts[parts.length - 1].charAt(0)).toUpperCase();
}

export function CourseMyAccount({ sx, ...other }: CardProps) {
  const { user } = useAuthContext();
  const initials = getInitials(user?.displayName || '');

  const renderAvatar = () => (
    <AnimateBorder
      sx={{ mb: 2, p: '6px', width: 96, height: 96, borderRadius: '50%' }}
      slotProps={{
        primaryBorder: { size: 120, sx: { color: 'primary.main' } },
      }}
    >
      <Avatar 
        alt={user?.displayName} 
        sx={{ 
          width: 1, 
          height: 1,
          bgcolor: 'background.paper',
          color: 'text.primary',
          fontSize: '1.5rem',
          fontWeight: 600
        }}
      >
        {initials}
      </Avatar>
    </AnimateBorder>
  );

  return (
    <Card sx={sx} {...other}>
      <Box sx={{ display: 'flex', alignItems: 'center', flexDirection: 'column' }}>
        {renderAvatar()}

        <Typography variant="subtitle1" noWrap sx={{ mb: 0.5 }}>
          {user?.displayName}
        </Typography>

        <Box
          sx={{
            gap: 0.5,
            display: 'flex',
            typography: 'body2',
            alignItems: 'center',
            color: 'text.secondary',
          }}
        >
          ID: 123987
          <IconButton size="small">
            <Iconify width={18} icon="solar:copy-bold" />
          </IconButton>
        </Box>
      </Box>
    </Card>
  );
}
