import {
  Badge,
  Dropdown,
  Option,
  Text,
  makeStyles,
} from '@fluentui/react-components';
import { useQuery } from '@tanstack/react-query';
import { useMemo, useState } from 'react';
import { PageHeader } from '@/components/PageHeader';
import { DataTable } from '@/components/DataTable';
import { listOrders } from '@/api/orders';
import { listStores } from '@/api/stores';
import type { OrderResponse } from '@/types/api';
import { OrderDetailDialog } from './OrderDetail';

const useStyles = makeStyles({
  toolbar: {
    display: 'flex',
    gap: '12px',
    marginBottom: '12px',
    alignItems: 'center',
    flexWrap: 'wrap',
  },
});

function formatMoney(n: number) {
  return new Intl.NumberFormat(undefined, { style: 'currency', currency: 'USD' }).format(n);
}

const STATUS_OPTIONS = ['All', 'Open', 'Paid', 'Cancelled', 'Refunded'];
const DATE_OPTIONS: { key: 'today' | 'week' | 'all'; label: string }[] = [
  { key: 'today', label: 'Today' },
  { key: 'week', label: 'Last 7 days' },
  { key: 'all', label: 'All time' },
];

function statusBadge(status: string) {
  const intent =
    status === 'Paid'
      ? 'success'
      : status === 'Cancelled' || status === 'Refunded'
        ? 'danger'
        : status === 'Open'
          ? 'warning'
          : 'informative';
  return <Badge appearance="tint" color={intent}>{status}</Badge>;
}

export function Orders() {
  const styles = useStyles();
  const [storeFilter, setStoreFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('All');
  const [dateFilter, setDateFilter] = useState<'today' | 'week' | 'all'>('today');
  const [selected, setSelected] = useState<OrderResponse | null>(null);

  const ordersQuery = useQuery({ queryKey: ['orders'], queryFn: listOrders });
  const storesQuery = useQuery({ queryKey: ['stores'], queryFn: listStores });

  const filtered = useMemo(() => {
    let rows = ordersQuery.data ?? [];
    if (storeFilter !== 'all') rows = rows.filter((o) => o.storeId === storeFilter);
    if (statusFilter !== 'All') rows = rows.filter((o) => o.status === statusFilter);
    const now = Date.now();
    if (dateFilter === 'today') {
      const start = new Date();
      start.setHours(0, 0, 0, 0);
      rows = rows.filter((o) => new Date(o.createdAt).getTime() >= start.getTime());
    } else if (dateFilter === 'week') {
      const cutoff = now - 7 * 24 * 60 * 60 * 1000;
      rows = rows.filter((o) => new Date(o.createdAt).getTime() >= cutoff);
    }
    return [...rows].sort(
      (a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
    );
  }, [ordersQuery.data, storeFilter, statusFilter, dateFilter]);

  const storeName = (id: string) =>
    storesQuery.data?.find((s) => s.id === id)?.name ?? '—';

  return (
    <>
      <PageHeader title="Orders" subtitle="Review orders, change status and record payments." />
      <div className={styles.toolbar}>
        <Text size={300}>Store</Text>
        <Dropdown
          value={storeFilter === 'all' ? 'All stores' : storeName(storeFilter)}
          selectedOptions={[storeFilter]}
          onOptionSelect={(_, d) => setStoreFilter(d.optionValue ?? 'all')}
        >
          <Option value="all">All stores</Option>
          {(storesQuery.data ?? []).map((s) => (
            <Option key={s.id} value={s.id}>
              {s.name}
            </Option>
          ))}
        </Dropdown>
        <Text size={300}>Status</Text>
        <Dropdown
          value={statusFilter}
          selectedOptions={[statusFilter]}
          onOptionSelect={(_, d) => setStatusFilter(d.optionValue ?? 'All')}
        >
          {STATUS_OPTIONS.map((s) => (
            <Option key={s} value={s}>
              {s}
            </Option>
          ))}
        </Dropdown>
        <Text size={300}>Date</Text>
        <Dropdown
          value={DATE_OPTIONS.find((d) => d.key === dateFilter)?.label ?? ''}
          selectedOptions={[dateFilter]}
          onOptionSelect={(_, d) =>
            setDateFilter((d.optionValue as 'today' | 'week' | 'all') ?? 'today')
          }
        >
          {DATE_OPTIONS.map((d) => (
            <Option key={d.key} value={d.key}>
              {d.label}
            </Option>
          ))}
        </Dropdown>
      </div>
      <DataTable
        rows={filtered}
        rowKey={(r) => r.id}
        isLoading={ordersQuery.isLoading}
        isError={ordersQuery.isError}
        onRowClick={(row) => setSelected(row)}
        emptyMessage="No orders match these filters."
        columns={[
          { key: 'num', header: '#', width: '120px', render: (r) => r.orderNumber },
          { key: 'store', header: 'Store', render: (r) => storeName(r.storeId) },
          { key: 'status', header: 'Status', width: '120px', render: (r) => statusBadge(r.status) },
          {
            key: 'paystatus',
            header: 'Payment',
            width: '110px',
            render: (r) => statusBadge(r.paymentStatus),
          },
          {
            key: 'total',
            header: 'Total',
            width: '100px',
            render: (r) => formatMoney(r.totalAmount),
          },
          {
            key: 'when',
            header: 'When',
            width: '160px',
            render: (r) => new Date(r.createdAt).toLocaleString(),
          },
        ]}
      />
      <OrderDetailDialog
        open={!!selected}
        orderId={selected?.id ?? null}
        storeName={selected ? storeName(selected.storeId) : ''}
        onClose={() => setSelected(null)}
      />
    </>
  );
}
