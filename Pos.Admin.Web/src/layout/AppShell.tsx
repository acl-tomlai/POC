import { makeStyles, tokens } from '@fluentui/react-components';
import { Outlet } from 'react-router-dom';
import { SideNav } from './SideNav';
import { TopBar } from './TopBar';

const useStyles = makeStyles({
  root: {
    display: 'flex',
    flexDirection: 'column',
    height: '100vh',
    backgroundColor: tokens.colorNeutralBackground3,
  },
  body: {
    display: 'flex',
    flex: 1,
    minHeight: 0,
  },
  content: {
    flex: 1,
    overflowY: 'auto',
    padding: '24px 32px',
  },
});

export function AppShell() {
  const styles = useStyles();
  return (
    <div className={styles.root}>
      <TopBar />
      <div className={styles.body}>
        <SideNav />
        <main className={styles.content}>
          <Outlet />
        </main>
      </div>
    </div>
  );
}
