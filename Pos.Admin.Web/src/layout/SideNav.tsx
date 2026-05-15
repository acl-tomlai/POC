import {
  Board24Regular,
  BoxMultiple24Regular,
  Building24Regular,
  DataPie24Regular,
  People24Regular,
  Print24Regular,
  Receipt24Regular,
  Settings24Regular,
} from '@fluentui/react-icons';
import { makeStyles, mergeClasses, tokens } from '@fluentui/react-components';
import { NavLink } from 'react-router-dom';
import type { ReactNode } from 'react';
import { useHasRole } from '@/auth/RoleGate';

const useStyles = makeStyles({
  nav: {
    width: '240px',
    flexShrink: 0,
    backgroundColor: tokens.colorNeutralBackground2,
    borderRight: `1px solid ${tokens.colorNeutralStroke2}`,
    overflowY: 'auto',
    paddingTop: '12px',
    paddingBottom: '12px',
  },
  sectionHeader: {
    padding: '12px 20px 4px 20px',
    color: tokens.colorNeutralForeground3,
    fontSize: tokens.fontSizeBase200,
    fontWeight: tokens.fontWeightSemibold,
    textTransform: 'uppercase',
    letterSpacing: '0.05em',
  },
  link: {
    display: 'flex',
    alignItems: 'center',
    gap: '12px',
    padding: '8px 20px',
    color: tokens.colorNeutralForeground1,
    textDecoration: 'none',
    fontSize: tokens.fontSizeBase300,
    ':hover': {
      backgroundColor: tokens.colorNeutralBackground2Hover,
    },
  },
  linkActive: {
    backgroundColor: tokens.colorBrandBackground2,
    color: tokens.colorBrandForeground1,
    fontWeight: tokens.fontWeightSemibold,
    borderLeft: `3px solid ${tokens.colorBrandStroke1}`,
    paddingLeft: '17px',
  },
});

interface NavLinkItemProps {
  to: string;
  icon: ReactNode;
  children: ReactNode;
  end?: boolean;
}

function NavLinkItem({ to, icon, children, end }: NavLinkItemProps) {
  const styles = useStyles();
  return (
    <NavLink
      to={to}
      end={end}
      className={({ isActive }) =>
        mergeClasses(styles.link, isActive ? styles.linkActive : undefined)
      }
    >
      {icon}
      <span>{children}</span>
    </NavLink>
  );
}

export function SideNav() {
  const styles = useStyles();
  const isAdmin = useHasRole(['Admin']);

  return (
    <nav className={styles.nav}>
      <NavLinkItem to="/" icon={<DataPie24Regular />} end>
        Dashboard
      </NavLinkItem>

      <div className={styles.sectionHeader}>
        Catalog
      </div>
      <NavLinkItem to="/products" icon={<BoxMultiple24Regular />}>
        Products
      </NavLinkItem>
      <NavLinkItem to="/categories" icon={<Board24Regular />}>
        Categories
      </NavLinkItem>

      <div className={styles.sectionHeader}>
        Operations
      </div>
      <NavLinkItem to="/stores" icon={<Building24Regular />}>
        Stores
      </NavLinkItem>
      <NavLinkItem to="/orders" icon={<Receipt24Regular />}>
        Orders
      </NavLinkItem>
      <NavLinkItem to="/printers" icon={<Print24Regular />}>
        Printers
      </NavLinkItem>

      {isAdmin && (
        <>
          <div className={styles.sectionHeader}>
            Administration
          </div>
          <NavLinkItem to="/users" icon={<People24Regular />}>
            Users
          </NavLinkItem>
          <NavLinkItem to="/settings" icon={<Settings24Regular />}>
            Tenant settings
          </NavLinkItem>
        </>
      )}
    </nav>
  );
}
