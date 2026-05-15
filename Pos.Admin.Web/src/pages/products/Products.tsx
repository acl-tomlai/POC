import { Button, Input, makeStyles } from '@fluentui/react-components';
import { AddRegular, DeleteRegular, EditRegular, SearchRegular } from '@fluentui/react-icons';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useMemo, useState } from 'react';
import { PageHeader } from '@/components/PageHeader';
import { DataTable } from '@/components/DataTable';
import { ConfirmDialog } from '@/components/ConfirmDialog';
import { useAppToast } from '@/components/toast';
import {
  createProduct,
  deleteProduct,
  listProducts,
  updateProduct,
} from '@/api/products';
import { listCategories } from '@/api/categories';
import { extractApiErrorMessage } from '@/api/client';
import type { ProductResponse } from '@/types/api';
import { ProductFormDrawer } from './ProductFormDrawer';

const useStyles = makeStyles({
  toolbar: {
    display: 'flex',
    gap: '12px',
    marginBottom: '12px',
    alignItems: 'center',
  },
  search: { flex: 1, maxWidth: '320px' },
});

function formatMoney(n: number) {
  return new Intl.NumberFormat(undefined, { style: 'currency', currency: 'USD' }).format(n);
}

export function Products() {
  const styles = useStyles();
  const qc = useQueryClient();
  const { showSuccess, showError } = useAppToast();
  const [search, setSearch] = useState('');
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editing, setEditing] = useState<ProductResponse | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<ProductResponse | null>(null);

  const productsQuery = useQuery({ queryKey: ['products'], queryFn: listProducts });
  const categoriesQuery = useQuery({ queryKey: ['categories'], queryFn: listCategories });

  const invalidate = () => qc.invalidateQueries({ queryKey: ['products'] });

  const createMutation = useMutation({
    mutationFn: createProduct,
    onSuccess: () => {
      showSuccess('Product created');
      setDrawerOpen(false);
      invalidate();
    },
    onError: (e) => showError('Could not create product', extractApiErrorMessage(e)),
  });

  const updateMutation = useMutation({
    mutationFn: (vars: { id: string; values: Parameters<typeof updateProduct>[1] }) =>
      updateProduct(vars.id, vars.values),
    onSuccess: () => {
      showSuccess('Product updated');
      setDrawerOpen(false);
      setEditing(null);
      invalidate();
    },
    onError: (e) => showError('Could not update product', extractApiErrorMessage(e)),
  });

  const deleteMutation = useMutation({
    mutationFn: deleteProduct,
    onSuccess: () => {
      showSuccess('Product deleted');
      setDeleteTarget(null);
      invalidate();
    },
    onError: (e) => showError('Could not delete product', extractApiErrorMessage(e)),
  });

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return productsQuery.data;
    return productsQuery.data?.filter(
      (p) =>
        p.name.toLowerCase().includes(q) ||
        (p.sku?.toLowerCase().includes(q) ?? false) ||
        (p.barcode?.toLowerCase().includes(q) ?? false)
    );
  }, [productsQuery.data, search]);

  return (
    <>
      <PageHeader
        title="Products"
        subtitle="Manage the items sold by your restaurant."
        actions={
          <Button
            appearance="primary"
            icon={<AddRegular />}
            onClick={() => {
              setEditing(null);
              setDrawerOpen(true);
            }}
            disabled={(categoriesQuery.data?.length ?? 0) === 0}
          >
            New product
          </Button>
        }
      />
      <div className={styles.toolbar}>
        <Input
          className={styles.search}
          contentBefore={<SearchRegular />}
          placeholder="Search name, SKU, or barcode"
          value={search}
          onChange={(_, d) => setSearch(d.value)}
        />
      </div>
      <DataTable
        rows={filtered}
        rowKey={(r) => r.id}
        isLoading={productsQuery.isLoading}
        isError={productsQuery.isError}
        emptyMessage={
          (categoriesQuery.data?.length ?? 0) === 0
            ? 'Create a category first, then add products.'
            : 'No products yet.'
        }
        columns={[
          { key: 'name', header: 'Name', render: (r) => r.name },
          { key: 'cat', header: 'Category', render: (r) => r.categoryName },
          { key: 'sku', header: 'SKU', width: '120px', render: (r) => r.sku ?? '—' },
          {
            key: 'price',
            header: 'Price',
            width: '100px',
            render: (r) => formatMoney(r.price),
          },
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
      <ProductFormDrawer
        open={drawerOpen}
        editing={editing}
        categories={categoriesQuery.data ?? []}
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
        title="Delete product?"
        message={`Delete "${deleteTarget?.name}"? This cannot be undone.`}
        confirmLabel="Delete"
        busy={deleteMutation.isPending}
        onConfirm={() => deleteTarget && deleteMutation.mutate(deleteTarget.id)}
        onClose={() => setDeleteTarget(null)}
      />
    </>
  );
}
