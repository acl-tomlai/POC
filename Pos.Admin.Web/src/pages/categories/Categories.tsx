import { Button } from '@fluentui/react-components';
import { AddRegular, DeleteRegular, EditRegular } from '@fluentui/react-icons';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import { PageHeader } from '@/components/PageHeader';
import { DataTable } from '@/components/DataTable';
import { ConfirmDialog } from '@/components/ConfirmDialog';
import { useAppToast } from '@/components/toast';
import {
  createCategory,
  deleteCategory,
  listCategories,
  updateCategory,
} from '@/api/categories';
import { extractApiErrorMessage } from '@/api/client';
import type { CategoryResponse } from '@/types/api';
import { CategoryFormDrawer } from './CategoryFormDrawer';

export function Categories() {
  const qc = useQueryClient();
  const { showSuccess, showError } = useAppToast();
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editing, setEditing] = useState<CategoryResponse | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<CategoryResponse | null>(null);

  const query = useQuery({ queryKey: ['categories'], queryFn: listCategories });

  const invalidate = () => qc.invalidateQueries({ queryKey: ['categories'] });

  const createMutation = useMutation({
    mutationFn: createCategory,
    onSuccess: () => {
      showSuccess('Category created');
      setDrawerOpen(false);
      invalidate();
    },
    onError: (e) => showError('Could not create category', extractApiErrorMessage(e)),
  });

  const updateMutation = useMutation({
    mutationFn: (vars: { id: string; values: Parameters<typeof updateCategory>[1] }) =>
      updateCategory(vars.id, vars.values),
    onSuccess: () => {
      showSuccess('Category updated');
      setDrawerOpen(false);
      setEditing(null);
      invalidate();
    },
    onError: (e) => showError('Could not update category', extractApiErrorMessage(e)),
  });

  const deleteMutation = useMutation({
    mutationFn: deleteCategory,
    onSuccess: () => {
      showSuccess('Category deleted');
      setDeleteTarget(null);
      invalidate();
    },
    onError: (e) => showError('Could not delete category', extractApiErrorMessage(e)),
  });

  const openCreate = () => {
    setEditing(null);
    setDrawerOpen(true);
  };

  const openEdit = (row: CategoryResponse) => {
    setEditing(row);
    setDrawerOpen(true);
  };

  return (
    <>
      <PageHeader
        title="Categories"
        subtitle="Group products and control their display order on the POS."
        actions={
          <Button appearance="primary" icon={<AddRegular />} onClick={openCreate}>
            New category
          </Button>
        }
      />
      <DataTable
        rows={query.data}
        rowKey={(r) => r.id}
        isLoading={query.isLoading}
        isError={query.isError}
        columns={[
          { key: 'order', header: 'Display order', width: '140px', render: (r) => r.displayOrder },
          { key: 'name', header: 'Name', render: (r) => r.name },
          { key: 'active', header: 'Active', width: '100px', render: (r) => (r.isActive ? 'Yes' : 'No') },
          {
            key: 'created',
            header: 'Created',
            width: '160px',
            render: (r) => new Date(r.createdAt).toLocaleDateString(),
          },
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
                    openEdit(r);
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
      <CategoryFormDrawer
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
      <ConfirmDialog
        open={!!deleteTarget}
        title="Delete category?"
        message={`Delete "${deleteTarget?.name}"? This cannot be undone.`}
        confirmLabel="Delete"
        busy={deleteMutation.isPending}
        onConfirm={() => deleteTarget && deleteMutation.mutate(deleteTarget.id)}
        onClose={() => setDeleteTarget(null)}
      />
    </>
  );
}
