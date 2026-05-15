import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { FormDrawer } from '@/components/FormDrawer';
import {
  NumberField,
  SelectField,
  SwitchField,
  TextAreaField,
  TextField,
} from '@/components/fields';
import type {
  CategoryResponse,
  ProductCreateRequest,
  ProductResponse,
} from '@/types/api';

const schema = z.object({
  categoryId: z.string().uuid('Pick a category'),
  name: z.string().min(1, 'Required').max(200),
  nameLocalized: z.string().max(200).optional().or(z.literal('')),
  altLanguageCode: z.string().max(8).optional().or(z.literal('')),
  description: z.string().max(2000).optional().or(z.literal('')),
  sku: z.string().max(100).optional().or(z.literal('')),
  barcode: z.string().max(100).optional().or(z.literal('')),
  price: z.number({ invalid_type_error: 'Required' }).min(0),
  costPrice: z
    .number({ invalid_type_error: 'Enter a number' })
    .min(0)
    .nullable()
    .optional(),
  imageUrl: z.string().max(1000).optional().or(z.literal('')),
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
  editing: ProductResponse | null;
  categories: CategoryResponse[];
  busy?: boolean;
  onClose: () => void;
  onSubmit: (values: ProductCreateRequest) => void;
}

export function ProductFormDrawer({
  open,
  editing,
  categories,
  busy,
  onClose,
  onSubmit,
}: Props) {
  const { control, handleSubmit, reset } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      categoryId: '',
      name: '',
      nameLocalized: '',
      altLanguageCode: '',
      description: '',
      sku: '',
      barcode: '',
      price: 0,
      costPrice: null,
      imageUrl: '',
      isActive: true,
    },
  });

  useEffect(() => {
    if (open) {
      reset(
        editing
          ? {
              categoryId: editing.categoryId,
              name: editing.name,
              nameLocalized: editing.nameLocalized ?? '',
              altLanguageCode: editing.altLanguageCode ?? '',
              description: editing.description ?? '',
              sku: editing.sku ?? '',
              barcode: editing.barcode ?? '',
              price: editing.price,
              costPrice: editing.costPrice ?? null,
              imageUrl: editing.imageUrl ?? '',
              isActive: editing.isActive,
            }
          : {
              categoryId: categories[0]?.id ?? '',
              name: '',
              nameLocalized: '',
              altLanguageCode: '',
              description: '',
              sku: '',
              barcode: '',
              price: 0,
              costPrice: null,
              imageUrl: '',
              isActive: true,
            }
      );
    }
  }, [open, editing, categories, reset]);

  return (
    <FormDrawer
      open={open}
      title={editing ? 'Edit product' : 'New product'}
      busy={busy}
      onClose={onClose}
      onSubmit={handleSubmit((v) =>
        onSubmit({
          categoryId: v.categoryId,
          name: v.name,
          nameLocalized: v.nameLocalized || null,
          altLanguageCode: v.altLanguageCode || null,
          description: v.description || null,
          sku: v.sku || null,
          barcode: v.barcode || null,
          price: v.price,
          costPrice: v.costPrice ?? null,
          imageUrl: v.imageUrl || null,
          isActive: v.isActive,
        })
      )}
    >
      <SelectField
        control={control}
        name="categoryId"
        label="Category"
        required
        options={categories.map((c) => ({ value: c.id, label: c.name }))}
      />
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
      <TextAreaField control={control} name="description" label="Description" />
      <TextField control={control} name="sku" label="SKU" />
      <TextField control={control} name="barcode" label="Barcode" />
      <NumberField control={control} name="price" label="Price" required min={0} />
      <NumberField control={control} name="costPrice" label="Cost price" min={0} />
      <TextField control={control} name="imageUrl" label="Image URL" />
      <SwitchField control={control} name="isActive" label="Active" />
    </FormDrawer>
  );
}
