import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { FormDrawer } from '@/components/FormDrawer';
import { SwitchField, TextField } from '@/components/fields';
import type { StoreCreateRequest, StoreResponse } from '@/types/api';

const schema = z.object({
  name: z.string().min(1, 'Required').max(200),
  address: z.string().max(500).optional().or(z.literal('')),
  phone: z.string().max(50).optional().or(z.literal('')),
  isActive: z.boolean(),
});
type FormValues = z.infer<typeof schema>;

interface Props {
  open: boolean;
  editing: StoreResponse | null;
  busy?: boolean;
  onClose: () => void;
  onSubmit: (values: StoreCreateRequest) => void;
}

export function StoreFormDrawer({ open, editing, busy, onClose, onSubmit }: Props) {
  const { control, handleSubmit, reset } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { name: '', address: '', phone: '', isActive: true },
  });

  useEffect(() => {
    if (open) {
      reset(
        editing
          ? {
              name: editing.name,
              address: editing.address ?? '',
              phone: editing.phone ?? '',
              isActive: editing.isActive,
            }
          : { name: '', address: '', phone: '', isActive: true }
      );
    }
  }, [open, editing, reset]);

  return (
    <FormDrawer
      open={open}
      title={editing ? 'Edit store' : 'New store'}
      busy={busy}
      onClose={onClose}
      onSubmit={handleSubmit((v) =>
        onSubmit({
          name: v.name,
          address: v.address || null,
          phone: v.phone || null,
          isActive: v.isActive,
        })
      )}
    >
      <TextField control={control} name="name" label="Name" required />
      <TextField control={control} name="address" label="Address" />
      <TextField control={control} name="phone" label="Phone" />
      <SwitchField control={control} name="isActive" label="Active" />
    </FormDrawer>
  );
}
