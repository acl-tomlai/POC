import { Button, Dropdown, Option, makeStyles } from '@fluentui/react-components';
import { AddRegular, DeleteRegular, EditRegular } from '@fluentui/react-icons';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useEffect, useState } from 'react';
import { PageHeader } from '@/components/PageHeader';
import { DataTable } from '@/components/DataTable';
import { ConfirmDialog } from '@/components/ConfirmDialog';
import { useAppToast } from '@/components/toast';
import { listStores } from '@/api/stores';
import {
  createPrinter,
  deletePrinter,
  listPrintersForStore,
  updatePrinter,
} from '@/api/printers';
import { extractApiErrorMessage } from '@/api/client';
import type { PrinterResponse } from '@/types/api';
import { PrinterFormDrawer } from './PrinterFormDrawer';

const useStyles = makeStyles({
  toolbar: { display: 'flex', gap: '12px', marginBottom: '12px', alignItems: 'center' },
  storePicker: { minWidth: '240px' },
});

export function Printers() {
  const styles = useStyles();
  const qc = useQueryClient();
  const { showSuccess, showError } = useAppToast();
  const [selectedStoreId, setSelectedStoreId] = useState<string | undefined>();
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editing, setEditing] = useState<PrinterResponse | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<PrinterResponse | null>(null);

  const storesQuery = useQuery({ queryKey: ['stores'], queryFn: listStores });

  useEffect(() => {
    if (!selectedStoreId && storesQuery.data && storesQuery.data.length > 0) {
      setSelectedStoreId(storesQuery.data[0].id);
    }
  }, [storesQuery.data, selectedStoreId]);

  const printersQuery = useQuery({
    queryKey: ['printers', selectedStoreId],
    queryFn: () => listPrintersForStore(selectedStoreId!),
    enabled: !!selectedStoreId,
  });

  const invalidate = () => qc.invalidateQueries({ queryKey: ['printers', selectedStoreId] });

  const createMutation = useMutation({
    mutationFn: createPrinter,
    onSuccess: () => {
      showSuccess('Printer created');
      setDrawerOpen(false);
      invalidate();
    },
    onError: (e) => showError('Could not create printer', extractApiErrorMessage(e)),
  });

  const updateMutation = useMutation({
    mutationFn: (vars: { id: string; values: Parameters<typeof updatePrinter>[1] }) =>
      updatePrinter(vars.id, vars.values),
    onSuccess: () => {
      showSuccess('Printer updated');
      setDrawerOpen(false);
      setEditing(null);
      invalidate();
    },
    onError: (e) => showError('Could not update printer', extractApiErrorMessage(e)),
  });

  const deleteMutation = useMutation({
    mutationFn: deletePrinter,
    onSuccess: () => {
      showSuccess('Printer deleted');
      setDeleteTarget(null);
      invalidate();
    },
    onError: (e) => showError('Could not delete printer', extractApiErrorMessage(e)),
  });

  const selectedStore = storesQuery.data?.find((s) => s.id === selectedStoreId);

  return (
    <>
      <PageHeader
        title="Printers"
        subtitle="Configure receipt, kitchen and label printers per store."
        actions={
          <Button
            appearance="primary"
            icon={<AddRegular />}
            disabled={!selectedStoreId}
            onClick={() => {
              setEditing(null);
              setDrawerOpen(true);
            }}
          >
            New printer
          </Button>
        }
      />
      <div className={styles.toolbar}>
        <Dropdown
          className={styles.storePicker}
          placeholder="Pick a store"
          value={selectedStore?.name ?? ''}
          selectedOptions={selectedStoreId ? [selectedStoreId] : []}
          onOptionSelect={(_, d) => setSelectedStoreId(d.optionValue)}
        >
          {(storesQuery.data ?? []).map((s) => (
            <Option key={s.id} value={s.id}>
              {s.name}
            </Option>
          ))}
        </Dropdown>
      </div>
      <DataTable
        rows={printersQuery.data}
        rowKey={(r) => r.id}
        isLoading={printersQuery.isLoading}
        isError={printersQuery.isError}
        emptyMessage={
          (storesQuery.data?.length ?? 0) === 0
            ? 'Create a store first.'
            : 'No printers for this store yet.'
        }
        columns={[
          { key: 'name', header: 'Name', render: (r) => r.name },
          { key: 'type', header: 'Type', width: '120px', render: (r) => r.printerType },
          { key: 'ip', header: 'IP', width: '160px', render: (r) => r.ipAddress },
          { key: 'port', header: 'Port', width: '80px', render: (r) => r.port },
          { key: 'active', header: 'Active', width: '90px', render: (r) => (r.isActive ? 'Yes' : 'No') },
          {
            key: 'actions',
            header: '',
            width: '120px',
            render: (r) => (
              <>
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
                <Button
                  appearance="subtle"
                  icon={<DeleteRegular />}
                  aria-label="Delete"
                  onClick={(e) => {
                    e.stopPropagation();
                    setDeleteTarget(r);
                  }}
                />
              </>
            ),
          },
        ]}
      />
      <PrinterFormDrawer
        open={drawerOpen}
        editing={editing}
        storeId={selectedStoreId}
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
      <ConfirmDialog
        open={!!deleteTarget}
        title="Delete printer?"
        message={`Delete printer "${deleteTarget?.name}"?`}
        confirmLabel="Delete"
        busy={deleteMutation.isPending}
        onConfirm={() => deleteTarget && deleteMutation.mutate(deleteTarget.id)}
        onClose={() => setDeleteTarget(null)}
      />
    </>
  );
}
