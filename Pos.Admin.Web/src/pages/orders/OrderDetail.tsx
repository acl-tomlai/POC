import {
  Button,
  Dialog,
  DialogActions,
  DialogBody,
  DialogContent,
  DialogSurface,
  DialogTitle,
  Divider,
  Dropdown,
  Field,
  Input,
  Option,
  Spinner,
  Text,
  makeStyles,
  tokens,
} from '@fluentui/react-components';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect, useState } from 'react';
import { getOrder, createPayment, updateOrderStatus } from '@/api/orders';
import { extractApiErrorMessage } from '@/api/client';
import { useAppToast } from '@/components/toast';
import type { OrderResponse } from '@/types/api';

const useStyles = makeStyles({
  surface: { maxWidth: '640px' },
  headerRow: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '12px',
  },
  meta: { color: tokens.colorNeutralForeground3, marginBottom: '12px' },
  section: { marginTop: '16px', marginBottom: '8px', fontWeight: tokens.fontWeightSemibold },
  line: {
    display: 'grid',
    gridTemplateColumns: '1fr 80px 100px 100px',
    gap: '8px',
    padding: '4px 0',
    alignItems: 'center',
  },
  total: {
    display: 'flex',
    justifyContent: 'space-between',
    padding: '4px 0',
  },
  totalRow: { fontWeight: tokens.fontWeightSemibold },
  paymentRow: {
    display: 'grid',
    gridTemplateColumns: '1fr 100px 1fr 1fr',
    gap: '8px',
    padding: '4px 0',
    alignItems: 'center',
  },
  paymentForm: {
    marginTop: '12px',
    padding: '12px',
    border: `1px solid ${tokens.colorNeutralStroke2}`,
    borderRadius: tokens.borderRadiusMedium,
    display: 'flex',
    flexDirection: 'column',
    gap: '8px',
  },
  paymentFormRow: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr 1fr auto',
    gap: '8px',
    alignItems: 'end',
  },
});

const STATUSES = ['Open', 'Paid', 'Cancelled', 'Refunded'];
const PAYMENT_METHODS = ['Cash', 'EFTPOS', 'Card', 'Online'];

function money(n: number) {
  return new Intl.NumberFormat(undefined, { style: 'currency', currency: 'USD' }).format(n);
}

interface Props {
  open: boolean;
  orderId: string | null;
  storeName: string;
  onClose: () => void;
}

export function OrderDetailDialog({ open, orderId, storeName, onClose }: Props) {
  const styles = useStyles();
  const qc = useQueryClient();
  const { showSuccess, showError } = useAppToast();
  const [status, setStatus] = useState<string>('');
  const [paymentMethod, setPaymentMethod] = useState<string>('Cash');
  const [paymentAmount, setPaymentAmount] = useState<string>('');
  const [paymentReference, setPaymentReference] = useState<string>('');

  const query = useQuery<OrderResponse>({
    queryKey: ['orders', orderId],
    queryFn: () => getOrder(orderId!),
    enabled: open && !!orderId,
  });

  useEffect(() => {
    if (query.data) {
      setStatus(query.data.status);
      const remaining =
        query.data.totalAmount - query.data.payments.reduce((acc, p) => acc + p.amount, 0);
      setPaymentAmount(remaining > 0 ? remaining.toFixed(2) : '');
      setPaymentMethod('Cash');
      setPaymentReference('');
    }
  }, [query.data]);

  const invalidate = () => {
    qc.invalidateQueries({ queryKey: ['orders'] });
    qc.invalidateQueries({ queryKey: ['orders', orderId] });
  };

  const statusMutation = useMutation({
    mutationFn: (newStatus: string) =>
      updateOrderStatus(orderId!, { status: newStatus }),
    onSuccess: () => {
      showSuccess('Order status updated');
      invalidate();
    },
    onError: (e) => showError('Could not update status', extractApiErrorMessage(e)),
  });

  const paymentMutation = useMutation({
    mutationFn: () =>
      createPayment(orderId!, {
        paymentMethod,
        amount: Number(paymentAmount),
        reference: paymentReference || null,
      }),
    onSuccess: () => {
      showSuccess('Payment recorded');
      invalidate();
    },
    onError: (e) => showError('Could not record payment', extractApiErrorMessage(e)),
  });

  const order = query.data;

  return (
    <Dialog open={open} onOpenChange={(_, d) => !d.open && onClose()}>
      <DialogSurface className={styles.surface}>
        <DialogBody>
          <DialogTitle>{order ? `Order ${order.orderNumber}` : 'Order details'}</DialogTitle>
          <DialogContent>
            {query.isLoading || !order ? (
              <Spinner label="Loading order…" />
            ) : (
              <>
                <div className={styles.headerRow}>
                  <Text>
                    Store: {storeName}
                    <br />
                    Created: {new Date(order.createdAt).toLocaleString()}
                  </Text>
                  <Field label="Status">
                    <Dropdown
                      value={status}
                      selectedOptions={[status]}
                      onOptionSelect={(_, d) => {
                        const v = d.optionValue ?? status;
                        setStatus(v);
                        if (v !== order.status) statusMutation.mutate(v);
                      }}
                      disabled={statusMutation.isPending}
                    >
                      {STATUSES.map((s) => (
                        <Option key={s} value={s}>
                          {s}
                        </Option>
                      ))}
                    </Dropdown>
                  </Field>
                </div>

                <Text className={styles.section}>Lines</Text>
                <div>
                  {order.lines.map((l) => (
                    <div key={l.id} className={styles.line}>
                      <Text>{l.productName}</Text>
                      <Text>× {l.quantity}</Text>
                      <Text>{money(l.unitPrice)}</Text>
                      <Text style={{ textAlign: 'right' }}>{money(l.lineTotal)}</Text>
                    </div>
                  ))}
                </div>
                <Divider style={{ marginTop: 8, marginBottom: 8 }} />
                <div className={styles.total}>
                  <Text>Subtotal</Text>
                  <Text>{money(order.subtotal)}</Text>
                </div>
                <div className={styles.total}>
                  <Text>Discount</Text>
                  <Text>-{money(order.discountAmount)}</Text>
                </div>
                <div className={styles.total}>
                  <Text>Tax</Text>
                  <Text>{money(order.taxAmount)}</Text>
                </div>
                <div className={`${styles.total} ${styles.totalRow}`}>
                  <Text>Total</Text>
                  <Text>{money(order.totalAmount)}</Text>
                </div>

                <Text className={styles.section}>Payments</Text>
                {order.payments.length === 0 && (
                  <Text style={{ color: tokens.colorNeutralForeground3 }}>None recorded.</Text>
                )}
                {order.payments.map((p) => (
                  <div key={p.id} className={styles.paymentRow}>
                    <Text>{p.paymentMethod}</Text>
                    <Text>{money(p.amount)}</Text>
                    <Text>{p.reference ?? '—'}</Text>
                    <Text style={{ textAlign: 'right' }}>
                      {new Date(p.paidAt).toLocaleTimeString()}
                    </Text>
                  </div>
                ))}

                <div className={styles.paymentForm}>
                  <Text weight="semibold">Record payment</Text>
                  <div className={styles.paymentFormRow}>
                    <Field label="Method">
                      <Dropdown
                        value={paymentMethod}
                        selectedOptions={[paymentMethod]}
                        onOptionSelect={(_, d) => setPaymentMethod(d.optionValue ?? 'Cash')}
                      >
                        {PAYMENT_METHODS.map((m) => (
                          <Option key={m} value={m}>
                            {m}
                          </Option>
                        ))}
                      </Dropdown>
                    </Field>
                    <Field label="Amount">
                      <Input
                        type="number"
                        step="0.01"
                        min={0}
                        value={paymentAmount}
                        onChange={(_, d) => setPaymentAmount(d.value)}
                      />
                    </Field>
                    <Field label="Reference">
                      <Input
                        value={paymentReference}
                        onChange={(_, d) => setPaymentReference(d.value)}
                      />
                    </Field>
                    <Button
                      appearance="primary"
                      disabled={
                        paymentMutation.isPending ||
                        !paymentAmount ||
                        Number(paymentAmount) <= 0
                      }
                      onClick={() => paymentMutation.mutate()}
                    >
                      {paymentMutation.isPending ? 'Saving…' : 'Record'}
                    </Button>
                  </div>
                </div>
              </>
            )}
          </DialogContent>
          <DialogActions>
            <Button appearance="secondary" onClick={onClose}>
              Close
            </Button>
          </DialogActions>
        </DialogBody>
      </DialogSurface>
    </Dialog>
  );
}
