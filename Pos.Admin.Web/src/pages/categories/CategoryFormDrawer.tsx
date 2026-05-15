import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { FormDrawer } from '@/components/FormDrawer';
import { NumberField, SwitchField, TextField } from '@/components/fields';
import type { CategoryCreateRequest, CategoryResponse } from '@/types/api';

const schema = z.object({
  name: z.string().min(1, 'Required').max(200),
  displayOrder: z.number({ invalid_type_error: 'Required' }).int().min(0),
  isActive: z.boolean(),
});
type FormValues = z.infer<typeof schema>;

interface Props {
  open: boolean;
  editing: CategoryResponse | null;
  busy?: boolean;
  onClose: () => void;
  onSubmit: (values: CategoryCreateRequest) => void;
}

export function CategoryFormDrawer({ open, editing, busy, onClose, onSubmit }: Props) {
  const { control, handleSubmit, reset } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { name: '', displayOrder: 0, isActive: true },
  });

  useEffect(() => {
    if (open) {
      reset(
        editing
          ? { name: editing.name, displayOrder: editing.displayOrder, isActive: editing.isActive }
          : { name: '', displayOrder: 0, isActive: true }
      );
    }
  }, [open, editing, reset]);

  return (
    <FormDrawer
      open={open}
      title={editing ? 'Edit category' : 'New category'}
      busy={busy}
      onClose={onClose}
      onSubmit={handleSubmit(onSubmit)}
    >
      <TextField control={control} name="name" label="Name" required />
      <NumberField control={control} name="displayOrder" label="Display order" min={0} step={1} required />
      <SwitchField control={control} name="isActive" label="Active" />
    </FormDrawer>
  );
}
