import { Button } from '@fluentui/react-components';
import { AddRegular, DeleteRegular, EditRegular } from '@fluentui/react-icons';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import { PageHeader } from '@/components/PageHeader';
import { DataTable } from '@/components/DataTable';
import { ConfirmDialog } from '@/components/ConfirmDialog';
import { useAppToast } from '@/components/toast';
import {
  createUser,
  deleteUser,
  listUsers,
  updateUser,
} from '@/api/users';
import { extractApiErrorMessage } from '@/api/client';
import { useAuthStore } from '@/auth/authStore';
import type { UserResponse } from '@/types/api';
import { UserFormDrawer } from './UserFormDrawer';

export function Users() {
  const qc = useQueryClient();
  const { showSuccess, showError } = useAppToast();
  const currentUserId = useAuthStore((s) => s.user?.userId);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editing, setEditing] = useState<UserResponse | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<UserResponse | null>(null);

  const query = useQuery({ queryKey: ['users'], queryFn: listUsers });
  const invalidate = () => qc.invalidateQueries({ queryKey: ['users'] });

  const createMutation = useMutation({
    mutationFn: createUser,
    onSuccess: () => {
      showSuccess('User created');
      setDrawerOpen(false);
      invalidate();
    },
    onError: (e) => showError('Could not create user', extractApiErrorMessage(e)),
  });

  const updateMutation = useMutation({
    mutationFn: (vars: { id: string; values: Parameters<typeof updateUser>[1] }) =>
      updateUser(vars.id, vars.values),
    onSuccess: () => {
      showSuccess('User updated');
      setDrawerOpen(false);
      setEditing(null);
      invalidate();
    },
    onError: (e) => showError('Could not update user', extractApiErrorMessage(e)),
  });

  const deleteMutation = useMutation({
    mutationFn: deleteUser,
    onSuccess: () => {
      showSuccess('User deleted');
      setDeleteTarget(null);
      invalidate();
    },
    onError: (e) => showError('Could not delete user', extractApiErrorMessage(e)),
  });

  return (
    <>
      <PageHeader
        title="Users"
        subtitle="Staff who can sign into POS Admin or the till."
        actions={
          <Button
            appearance="primary"
            icon={<AddRegular />}
            onClick={() => {
              setEditing(null);
              setDrawerOpen(true);
            }}
          >
            New user
          </Button>
        }
      />
      <DataTable
        rows={query.data}
        rowKey={(r) => r.id}
        isLoading={query.isLoading}
        isError={query.isError}
        columns={[
          { key: 'name', header: 'Full name', render: (r) => r.fullName },
          { key: 'email', header: 'Email', render: (r) => r.email },
          { key: 'role', header: 'Role', width: '120px', render: (r) => r.role },
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
                  disabled={r.id === currentUserId}
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
      <UserFormDrawer
        open={drawerOpen}
        editing={editing}
        busy={createMutation.isPending || updateMutation.isPending}
        onClose={() => {
          setDrawerOpen(false);
          setEditing(null);
        }}
        onCreate={(v) => createMutation.mutate(v)}
        onUpdate={(v) => editing && updateMutation.mutate({ id: editing.id, values: v })}
      />
      <ConfirmDialog
        open={!!deleteTarget}
        title="Delete user?"
        message={`Delete "${deleteTarget?.fullName}"? They will lose access immediately.`}
        confirmLabel="Delete"
        busy={deleteMutation.isPending}
        onConfirm={() => deleteTarget && deleteMutation.mutate(deleteTarget.id)}
        onClose={() => setDeleteTarget(null)}
      />
    </>
  );
}
