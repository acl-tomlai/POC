import {
  Card,
  Spinner,
  Text,
  makeStyles,
  tokens,
} from '@fluentui/react-components';
import { useQuery } from '@tanstack/react-query';
import { useMemo } from 'react';
import { Link } from 'react-router-dom';
import { PageHeader } from '@/components/PageHeader';
import { DataTable } from '@/components/DataTable';
import { listOrders } from '@/api/orders';
import { listUsers } from '@/api/users';
import { listStores } from '@/api/stores';
import { useHasRole } from '@/auth/RoleGate';

const useStyles = makeStyles({
  stats: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
    gap: '16px',
    marginBottom: '24px',
  },
  stat: {
    padding: '20px',
    display: 'flex',
    flexDirection: 'column',
    gap: '4px',
  },
  statLabel: {
    color: tokens.colorNeutralForeground3,
    fontSize: tokens.fontSizeBase300,
  },
  statValue: {
    fontSize: tokens.fontSizeHero700,
    fontWeight: tokens.fontWeightSemibold,
  },
  sectionHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '12px',
  },
});

function money(n: number) {
  return new Intl.NumberFormat(undefined, { style: 'currency', currency: 'USD' }).format(n);
}

export function Dashboard() {
  const styles = useStyles();
  const isAdmin = useHasRole(['Admin']);

  const ordersQuery = useQuery({ queryKey: ['orders'], queryFn: listOrders });
  const storesQuery = useQuery({ queryKey: ['stores'], queryFn: listStores });
  const usersQuery = useQuery({ queryKey: ['users'], queryFn: listUsers, enabled: isAdmin });

  const stats = useMemo(() => {
    const orders = ordersQuery.data ?? [];
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    const today = orders.filter((o) => new Date(o.createdAt).getTime() >= start.getTime());
    const revenue = today
      .filter((o) => o.status !== 'Cancelled' && o.status !== 'Refunded')
      .reduce((acc, o) => acc + o.totalAmount, 0);
    return {
      ordersToday: today.length,
      revenueToday: revenue,
      activeStaff: (usersQuery.data ?? []).filter((u) => u.isActive).length,
    };
  }, [ordersQuery.data, usersQuery.data]);

  const recent = useMemo(() => {
    return [...(ordersQuery.data ?? [])]
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
      .slice(0, 8);
  }, [ordersQuery.data]);

  const storeName = (id: string) =>
    storesQuery.data?.find((s) => s.id === id)?.name ?? '—';

  if (ordersQuery.isLoading) {
    return <Spinner label="Loading dashboard…" />;
  }

  return (
    <>
      <PageHeader title="Dashboard" subtitle="A quick look at today's activity." />
      <div className={styles.stats}>
        <Card className={styles.stat}>
          <Text className={styles.statLabel}>Orders today</Text>
          <Text className={styles.statValue}>{stats.ordersToday}</Text>
        </Card>
        <Card className={styles.stat}>
          <Text className={styles.statLabel}>Revenue today</Text>
          <Text className={styles.statValue}>{money(stats.revenueToday)}</Text>
        </Card>
        {isAdmin && (
          <Card className={styles.stat}>
            <Text className={styles.statLabel}>Active staff</Text>
            <Text className={styles.statValue}>{stats.activeStaff}</Text>
          </Card>
        )}
      </div>

      <div className={styles.sectionHeader}>
        <Text size={500} weight="semibold">
          Recent orders
        </Text>
        <Link to="/orders">View all</Link>
      </div>
      <DataTable
        rows={recent}
        rowKey={(r) => r.id}
        emptyMessage="No orders recorded yet."
        columns={[
          { key: 'num', header: '#', width: '120px', render: (r) => r.orderNumber },
          { key: 'store', header: 'Store', render: (r) => storeName(r.storeId) },
          { key: 'status', header: 'Status', width: '120px', render: (r) => r.status },
          {
            key: 'total',
            header: 'Total',
            width: '100px',
            render: (r) => money(r.totalAmount),
          },
          {
            key: 'when',
            header: 'When',
            width: '160px',
            render: (r) => new Date(r.createdAt).toLocaleString(),
          },
        ]}
      />
    </>
  );
}
