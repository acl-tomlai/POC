import {
  Avatar,
  Button,
  Menu,
  MenuItem,
  MenuList,
  MenuPopover,
  MenuTrigger,
  Text,
  makeStyles,
  tokens,
} from '@fluentui/react-components';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/auth/authStore';

const useStyles = makeStyles({
  bar: {
    height: '52px',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: '0 24px',
    backgroundColor: tokens.colorNeutralBackground1,
    borderBottom: `1px solid ${tokens.colorNeutralStroke2}`,
    flexShrink: 0,
  },
  brand: {
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    fontWeight: tokens.fontWeightSemibold,
  },
  divider: {
    color: tokens.colorNeutralForeground3,
  },
  user: {
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
  },
});

export function TopBar() {
  const styles = useStyles();
  const navigate = useNavigate();
  const { user, signOut } = useAuthStore();

  const handleSignOut = () => {
    signOut();
    navigate('/login', { replace: true });
  };

  if (!user) return null;

  return (
    <header className={styles.bar}>
      <div className={styles.brand}>
        <Text size={500} weight="semibold">
          POS Admin
        </Text>
        <Text size={400} className={styles.divider}>
          ·
        </Text>
        <Text size={400}>{user.restaurantName}</Text>
      </div>
      <Menu>
        <MenuTrigger disableButtonEnhancement>
          <Button appearance="subtle" className={styles.user}>
            <Avatar name={user.fullName} size={28} />
            <span>
              {user.fullName} ({user.role})
            </span>
          </Button>
        </MenuTrigger>
        <MenuPopover>
          <MenuList>
            <MenuItem disabled>{user.email}</MenuItem>
            <MenuItem onClick={handleSignOut}>Sign out</MenuItem>
          </MenuList>
        </MenuPopover>
      </Menu>
    </header>
  );
}
