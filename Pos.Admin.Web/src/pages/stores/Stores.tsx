import { Button } from '@fluentui/react-components';
import { AddRegular, EditRegular } from '@fluentui/react-icons';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import { PageHeader } from '@/components/PageHeader';
import { DataTable } from '@/components/DataTable';
import { useAppToast } from '@/components/toast';
import { createStore, listStores, updateStore } from '@/api/stores';
import { extractApiErrorMessage } from '@/api/client';
import type { StoreResponse } from '@/types/api';
import { useHasRole } from '@/auth/RoleGate';
import { StoreFormDrawer } from './StoreFormDrawer';

export function Stores() {
  const qc = useQueryClient();
  const { showSuccess, showError } = useAppToast();
  const canEdit = useHasRole(['Admin']);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editing, setEditing] = useState<StoreResponse | null>(null);

  const query = useQuery({ queryKey: ['stores'], queryFn: listStores });
  const invalidate = () => qc.invalidateQueries({ queryKey: ['stores'] });

  const createMutation = useMutation({
    mutationFn: createStore,
    onSuccess: () => {
      showSuccess('Store created');
      setDrawerOpen(false);
      invalidate();
    },
    onError: (e) => showError('Could not create store', extractApiErrorMessage(e)),
  });

  const updateMutation = useMutation({
    mutationFn: (vars: { id: string; values: Parameters<typeof updateStore>[1] }) =>
      updateStore(vars.id, vars.values),
    onSuccess: () => {
      showSuccess('Store updated');
      setDrawerOpen(false);
      setEditing(null);
      invalidate();
    },
    onError: (e) => showError('Could not update store', extractApiErrorMessage(e)),
  });

  return (
    <>
      <PageHeader
        title="Stores"
        subtitle="Physical locations under your restaurant."
        actions={
          canEdit && (
            <Button
              appearance="primary"
              icon={<AddRegular />}
              onClick={() => {
                setEditing(null);
                setDrawerOpen(true);
              }}
            >
              New store
            </Button>
          )
        }
      />
      <DataTable
        rows={query.data}
        rowKey={(r) => r.id}
        isLoading={query.isLoading}
        isError={query.isError}
        columns={[
          { key: 'name', header: 'Name', render: (r) => r.name },
          { key: 'address', header: 'Address', render: (r) => r.address ?? '—' },
          { key: 'phone', header: 'Phone', width: '140px', render: (r) => r.phone ?? '—' },
          { key: 'active', header: 'Active', width: '90px', render: (r) => (r.isActive ? 'Yes' : 'No') },
          {
            key: 'actions',
            header: '',
            width: '60px',
            render: (r) =>
              canEdit && (
                <Button
                  appearance="subtle"
                  icon={<EditRegular />}
                  aria-label="Edit"
                  onClick={(e) => {
                    e.stopPropagation();
                    setEditing(r);
                    setDrawerOpen(true);
                  }}
                />
              ),
          },
        ]}
      />
      <StoreFormDrawer
        open={drawerOpen}
        editing={editing}
        busy={createMutation.isPending || updateMutation.isPending}
        onClose={() => {
          setDrawerOpen(false);
          setEditing(null);
        }}
        onSubmit={(values) => {
          if (editing) updateMutation.mutate({ id: editing.id, values });
          else createMutation.mutate(values);
        }}
      />
    </>
  );
}
