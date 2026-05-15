import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { FormDrawer } from '@/components/FormDrawer';
import { NumberField, SelectField, SwitchField, TextField } from '@/components/fields';
import { PRINTER_TYPES, type PrinterCreateRequest, type PrinterResponse } from '@/types/api';

const schema = z.object({
  storeId: z.string().uuid('Required'),
  name: z.string().min(1, 'Required').max(200),
  ipAddress: z.string().min(1, 'Required').max(45),
  port: z.number({ invalid_type_error: 'Required' }).int().min(1).max(65535),
  printerType: z.string().min(1, 'Required').max(50),
  isActive: z.boolean(),
});
type FormValues = z.infer<typeof schema>;

interface Props {
  open: boolean;
  editing: PrinterResponse | null;
  storeId?: string;
  busy?: boolean;
  onClose: () => void;
  onSubmit: (values: PrinterCreateRequest) => void;
}

export function PrinterFormDrawer({
  open,
  editing,
  storeId,
  busy,
  onClose,
  onSubmit,
}: Props) {
  const { control, handleSubmit, reset } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      storeId: storeId ?? '',
      name: '',
      ipAddress: '',
      port: 9100,
      printerType: 'Receipt',
      isActive: true,
    },
  });

  useEffect(() => {
    if (open) {
      reset(
        editing
          ? {
              storeId: editing.storeId,
              name: editing.name,
              ipAddress: editing.ipAddress,
              port: editing.port,
              printerType: editing.printerType,
              isActive: editing.isActive,
            }
          : {
              storeId: storeId ?? '',
              name: '',
              ipAddress: '',
              port: 9100,
              printerType: 'Receipt',
              isActive: true,
            }
      );
    }
  }, [open, editing, storeId, reset]);

  return (
    <FormDrawer
      open={open}
      title={editing ? 'Edit printer' : 'New printer'}
      busy={busy}
      onClose={onClose}
      onSubmit={handleSubmit(onSubmit)}
    >
      <TextField control={control} name="name" label="Name" required />
      <TextField control={control} name="ipAddress" label="IP address" required />
      <NumberField control={control} name="port" label="Port" required min={1} step={1} />
      <SelectField
        control={control}
        name="printerType"
        label="Type"
        required
        options={PRINTER_TYPES.map((t) => ({ value: t, label: t }))}
      />
      <SwitchField control={control} name="isActive" label="Active" />
    </FormDrawer>
  );
}
