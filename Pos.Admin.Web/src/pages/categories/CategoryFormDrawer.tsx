import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { FormDrawer } from '@/components/FormDrawer';
import { NumberField, SelectField, SwitchField, TextField } from '@/components/fields';
import type { CategoryCreateRequest, CategoryResponse } from '@/types/api';

const schema = z.object({
  name: z.string().min(1, 'Required').max(200),
  nameLocalized: z.string().max(200).optional().or(z.literal('')),
  altLanguageCode: z.string().max(8).optional().or(z.literal('')),
  displayOrder: z.number({ invalid_type_error: 'Required' }).int().min(0),
  isActive: z.boolean(),
});
type FormValues = z.infer<typeof schema>;

const altLanguageOptions = [
  { value: '', label: '(none)' },
  { value: 'vi', label: 'Vietnamese (vi)' },
  { value: 'zh', label: 'Chinese (zh)' },
  { value: 'es', label: 'Spanish (es)' },
  { value: 'fr', label: 'French (fr)' },
  { value: 'ja', label: 'Japanese (ja)' },
  { value: 'ko', label: 'Korean (ko)' },
  { value: 'th', label: 'Thai (th)' },
];

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
    defaultValues: {
      name: '',
      nameLocalized: '',
      altLanguageCode: '',
      displayOrder: 0,
      isActive: true,
    },
  });

  useEffect(() => {
    if (open) {
      reset(
        editing
          ? {
              name: editing.name,
              nameLocalized: editing.nameLocalized ?? '',
              altLanguageCode: editing.altLanguageCode ?? '',
              displayOrder: editing.displayOrder,
              isActive: editing.isActive,
            }
          : {
              name: '',
              nameLocalized: '',
              altLanguageCode: '',
              displayOrder: 0,
              isActive: true,
            }
      );
    }
  }, [open, editing, reset]);

  return (
    <FormDrawer
      open={open}
      title={editing ? 'Edit category' : 'New category'}
      busy={busy}
      onClose={onClose}
      onSubmit={handleSubmit((v) =>
        onSubmit({
          name: v.name,
          nameLocalized: v.nameLocalized || null,
          altLanguageCode: v.altLanguageCode || null,
          displayOrder: v.displayOrder,
          isActive: v.isActive,
        })
      )}
    >
      <TextField control={control} name="name" label="Name" required />
      <TextField
        control={control}
        name="nameLocalized"
        label="Alternative name (e.g. Vietnamese)"
      />
      <SelectField
        control={control}
        name="altLanguageCode"
        label="Alternative language"
        options={altLanguageOptions}
      />
      <NumberField control={control} name="displayOrder" label="Display order" min={0} step={1} required />
      <SwitchField control={control} name="isActive" label="Active" />
    </FormDrawer>
  );
}
