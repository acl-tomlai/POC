import { Button, Card, Spinner, Text, makeStyles, tokens } from '@fluentui/react-components';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { PageHeader } from '@/components/PageHeader';
import { TextField } from '@/components/fields';
import { useAppToast } from '@/components/toast';
import { getCurrentTenant, updateCurrentTenant } from '@/api/tenants';
import { extractApiErrorMessage } from '@/api/client';

const schema = z.object({
  name: z.string().min(1, 'Required').max(200),
  contactEmail: z.string().email().max(256),
  phone: z.string().max(50).optional().or(z.literal('')),
});
type FormValues = z.infer<typeof schema>;

const useStyles = makeStyles({
  card: { padding: '24px', maxWidth: '640px' },
  form: { display: 'flex', flexDirection: 'column', gap: '12px' },
  readOnly: {
    marginTop: '24px',
    padding: '16px',
    backgroundColor: tokens.colorNeutralBackground2,
    borderRadius: tokens.borderRadiusMedium,
  },
  readOnlyRow: {
    display: 'flex',
    justifyContent: 'space-between',
    padding: '4px 0',
  },
  actions: {
    display: 'flex',
    justifyContent: 'flex-end',
    marginTop: '16px',
  },
});

export function TenantSettings() {
  const styles = useStyles();
  const qc = useQueryClient();
  const { showSuccess, showError } = useAppToast();

  const query = useQuery({ queryKey: ['tenant', 'me'], queryFn: getCurrentTenant });

  const { control, handleSubmit, reset } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { name: '', contactEmail: '', phone: '' },
  });

  useEffect(() => {
    if (query.data) {
      reset({
        name: query.data.name,
        contactEmail: query.data.contactEmail,
        phone: query.data.phone ?? '',
      });
    }
  }, [query.data, reset]);

  const mutation = useMutation({
    mutationFn: (v: FormValues) =>
      updateCurrentTenant({
        name: v.name,
        contactEmail: v.contactEmail,
        phone: v.phone || null,
      }),
    onSuccess: () => {
      showSuccess('Settings updated');
      qc.invalidateQueries({ queryKey: ['tenant', 'me'] });
    },
    onError: (e) => showError('Could not save', extractApiErrorMessage(e)),
  });

  return (
    <>
      <PageHeader title="Tenant settings" subtitle="Restaurant-wide details for your account." />
      <Card className={styles.card}>
        {query.isLoading ? (
          <Spinner label="Loading…" />
        ) : (
          <form className={styles.form} onSubmit={handleSubmit((v) => mutation.mutate(v))}>
            <TextField control={control} name="name" label="Restaurant name" required />
            <TextField control={control} name="contactEmail" label="Contact email" required />
            <TextField control={control} name="phone" label="Phone" />
            <div className={styles.actions}>
              <Button appearance="primary" type="submit" disabled={mutation.isPending}>
                {mutation.isPending ? 'Saving…' : 'Save'}
              </Button>
            </div>

            {query.data && (
              <div className={styles.readOnly}>
                <Text size={200} weight="semibold">
                  Read-only
                </Text>
                <div className={styles.readOnlyRow}>
                  <Text>Slug</Text>
                  <Text>{query.data.slug}</Text>
                </div>
                <div className={styles.readOnlyRow}>
                  <Text>Status</Text>
                  <Text>{query.data.isActive ? 'Active' : 'Inactive'}</Text>
                </div>
                <div className={styles.readOnlyRow}>
                  <Text>Created</Text>
                  <Text>{new Date(query.data.createdAt).toLocaleString()}</Text>
                </div>
              </div>
            )}
          </form>
        )}
      </Card>
    </>
  );
}
