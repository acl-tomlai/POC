import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { FormDrawer } from '@/components/FormDrawer';
import { SelectField, SwitchField, TextField } from '@/components/fields';
import { ROLES, type UserCreateRequest, type UserResponse, type UserUpdateRequest } from '@/types/api';

const createSchema = z.object({
  mode: z.literal('create'),
  fullName: z.string().min(1, 'Required').max(200),
  email: z.string().email().max(256),
  password: z.string().min(8, 'Min 8 characters'),
  role: z.enum(['Admin', 'Manager', 'Cashier']),
  isActive: z.boolean(),
});

const updateSchema = z.object({
  mode: z.literal('update'),
  fullName: z.string().min(1, 'Required').max(200),
  email: z.string(),
  password: z.string().optional(),
  role: z.enum(['Admin', 'Manager', 'Cashier']),
  isActive: z.boolean(),
});

const schema = z.discriminatedUnion('mode', [createSchema, updateSchema]);
type FormValues = z.infer<typeof schema>;

interface Props {
  open: boolean;
  editing: UserResponse | null;
  busy?: boolean;
  onClose: () => void;
  onCreate: (values: UserCreateRequest) => void;
  onUpdate: (values: UserUpdateRequest) => void;
}

export function UserFormDrawer({ open, editing, busy, onClose, onCreate, onUpdate }: Props) {
  const isEdit = !!editing;
  const { control, handleSubmit, reset } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      mode: 'create',
      fullName: '',
      email: '',
      password: '',
      role: 'Cashier',
      isActive: true,
    },
  });

  useEffect(() => {
    if (!open) return;
    if (editing) {
      reset({
        mode: 'update',
        fullName: editing.fullName,
        email: editing.email,
        password: '',
        role: editing.role,
        isActive: editing.isActive,
      });
    } else {
      reset({
        mode: 'create',
        fullName: '',
        email: '',
        password: '',
        role: 'Cashier',
        isActive: true,
      });
    }
  }, [open, editing, reset]);

  return (
    <FormDrawer
      open={open}
      title={isEdit ? 'Edit user' : 'New user'}
      busy={busy}
      onClose={onClose}
      onSubmit={handleSubmit((v) => {
        if (v.mode === 'create') {
          onCreate({
            fullName: v.fullName,
            email: v.email,
            password: v.password,
            role: v.role,
          });
        } else {
          onUpdate({
            fullName: v.fullName,
            role: v.role,
            isActive: v.isActive,
          });
        }
      })}
    >
      <TextField control={control} name="fullName" label="Full name" required />
      <TextField
        control={control}
        name="email"
        label="Email"
        required={!isEdit}
        hint={isEdit ? 'Email cannot be changed after creation.' : undefined}
      />
      {!isEdit && (
        <TextField
          control={control}
          name="password"
          label="Password"
          type="password"
          required
          hint="At least 8 characters"
        />
      )}
      <SelectField
        control={control}
        name="role"
        label="Role"
        required
        options={ROLES.map((r) => ({ value: r, label: r }))}
      />
      {isEdit && <SwitchField control={control} name="isActive" label="Active" />}
    </FormDrawer>
  );
}
