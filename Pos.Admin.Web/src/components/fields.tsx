import {
  Dropdown,
  Field,
  Input,
  Option,
  Switch,
  Textarea,
} from '@fluentui/react-components';
import { Controller, type Control, type FieldValues, type Path } from 'react-hook-form';

interface BaseProps<T extends FieldValues> {
  control: Control<T>;
  name: Path<T>;
  label: string;
  required?: boolean;
  hint?: string;
}

type InputType =
  | 'text'
  | 'email'
  | 'password'
  | 'tel'
  | 'url'
  | 'search'
  | 'number'
  | 'date'
  | 'datetime-local'
  | 'month'
  | 'week'
  | 'time';

export function TextField<T extends FieldValues>({
  control,
  name,
  label,
  required,
  hint,
  type = 'text',
  placeholder,
}: BaseProps<T> & { type?: InputType; placeholder?: string }) {
  return (
    <Controller
      control={control}
      name={name}
      render={({ field, fieldState }) => (
        <Field
          label={label}
          required={required}
          hint={hint}
          validationState={fieldState.error ? 'error' : 'none'}
          validationMessage={fieldState.error?.message}
        >
          <Input
            type={type}
            value={(field.value as string | undefined) ?? ''}
            onChange={(_, data) => field.onChange(data.value)}
            onBlur={field.onBlur}
            placeholder={placeholder}
          />
        </Field>
      )}
    />
  );
}

export function TextAreaField<T extends FieldValues>({
  control,
  name,
  label,
  required,
  hint,
  rows = 3,
}: BaseProps<T> & { rows?: number }) {
  return (
    <Controller
      control={control}
      name={name}
      render={({ field, fieldState }) => (
        <Field
          label={label}
          required={required}
          hint={hint}
          validationState={fieldState.error ? 'error' : 'none'}
          validationMessage={fieldState.error?.message}
        >
          <Textarea
            rows={rows}
            value={(field.value as string | undefined) ?? ''}
            onChange={(_, data) => field.onChange(data.value)}
            onBlur={field.onBlur}
          />
        </Field>
      )}
    />
  );
}

export function NumberField<T extends FieldValues>({
  control,
  name,
  label,
  required,
  hint,
  min,
  step = 0.01,
}: BaseProps<T> & { min?: number; step?: number }) {
  return (
    <Controller
      control={control}
      name={name}
      render={({ field, fieldState }) => (
        <Field
          label={label}
          required={required}
          hint={hint}
          validationState={fieldState.error ? 'error' : 'none'}
          validationMessage={fieldState.error?.message}
        >
          <Input
            type="number"
            min={min}
            step={step}
            value={field.value === undefined || field.value === null ? '' : String(field.value)}
            onChange={(_, data) => {
              const v = data.value;
              field.onChange(v === '' ? null : Number(v));
            }}
            onBlur={field.onBlur}
          />
        </Field>
      )}
    />
  );
}

interface SelectFieldProps<T extends FieldValues> extends BaseProps<T> {
  options: { value: string; label: string }[];
  placeholder?: string;
}

export function SelectField<T extends FieldValues>({
  control,
  name,
  label,
  required,
  hint,
  options,
  placeholder,
}: SelectFieldProps<T>) {
  return (
    <Controller
      control={control}
      name={name}
      render={({ field, fieldState }) => {
        const selectedOption = options.find((o) => o.value === field.value);
        return (
          <Field
            label={label}
            required={required}
            hint={hint}
            validationState={fieldState.error ? 'error' : 'none'}
            validationMessage={fieldState.error?.message}
          >
            <Dropdown
              placeholder={placeholder ?? 'Select…'}
              value={selectedOption?.label ?? ''}
              selectedOptions={field.value ? [field.value as string] : []}
              onOptionSelect={(_, data) => field.onChange(data.optionValue)}
              onBlur={field.onBlur}
            >
              {options.map((opt) => (
                <Option key={opt.value} value={opt.value}>
                  {opt.label}
                </Option>
              ))}
            </Dropdown>
          </Field>
        );
      }}
    />
  );
}

export function SwitchField<T extends FieldValues>({
  control,
  name,
  label,
  hint,
}: BaseProps<T>) {
  return (
    <Controller
      control={control}
      name={name}
      render={({ field }) => (
        <Field label={label} hint={hint}>
          <Switch
            checked={!!field.value}
            onChange={(_, data) => field.onChange(data.checked)}
          />
        </Field>
      )}
    />
  );
}
