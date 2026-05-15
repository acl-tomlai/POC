import {
  Button,
  Card,
  Divider,
  MessageBar,
  MessageBarBody,
  Text,
  makeStyles,
  tokens,
} from '@fluentui/react-components';
import { useMutation } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Link, useNavigate } from 'react-router-dom';
import { signup as signupApi } from '@/api/auth';
import { useAuthStore } from '@/auth/authStore';
import { extractApiErrorMessage } from '@/api/client';
import { TextField } from '@/components/fields';

const schema = z.object({
  restaurantName: z.string().min(1, 'Required').max(200),
  slug: z
    .string()
    .min(1, 'Required')
    .max(40)
    .regex(/^[a-z0-9-]+$/, 'Lowercase letters, numbers, and dashes only'),
  contactEmail: z.string().email().max(256),
  phone: z.string().max(50).optional().or(z.literal('')),
  fullName: z.string().min(1, 'Required').max(200),
  adminEmail: z.string().email().max(256),
  password: z.string().min(8, 'Min 8 characters'),
});
type FormValues = z.infer<typeof schema>;

const useStyles = makeStyles({
  page: {
    minHeight: '100vh',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    padding: '24px',
    backgroundColor: tokens.colorNeutralBackground3,
  },
  card: {
    width: '480px',
    padding: '24px',
  },
  section: {
    fontWeight: tokens.fontWeightSemibold,
    marginTop: '16px',
    marginBottom: '4px',
  },
  form: {
    display: 'flex',
    flexDirection: 'column',
    gap: '12px',
  },
  alt: {
    textAlign: 'center',
    marginTop: '16px',
    color: tokens.colorNeutralForeground3,
  },
});

export function Signup() {
  const styles = useStyles();
  const navigate = useNavigate();
  const signIn = useAuthStore((s) => s.signIn);

  const { control, handleSubmit } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      restaurantName: '',
      slug: '',
      contactEmail: '',
      phone: '',
      fullName: '',
      adminEmail: '',
      password: '',
    },
  });

  const mutation = useMutation({
    mutationFn: (values: FormValues) =>
      signupApi({
        restaurant: {
          name: values.restaurantName,
          slug: values.slug,
          contactEmail: values.contactEmail,
          phone: values.phone || null,
        },
        admin: {
          fullName: values.fullName,
          email: values.adminEmail,
          password: values.password,
        },
      }),
    onSuccess: (response) => {
      signIn(response);
      navigate('/', { replace: true });
    },
  });

  const errorMessage = mutation.isError ? extractApiErrorMessage(mutation.error) : null;

  return (
    <div className={styles.page}>
      <Card className={styles.card}>
        <Text size={700} weight="semibold" style={{ textAlign: 'center', display: 'block' }}>
          Create your restaurant on POS Admin
        </Text>
        <form className={styles.form} onSubmit={handleSubmit((v) => mutation.mutate(v))}>
          <Text className={styles.section}>Restaurant</Text>
          <TextField control={control} name="restaurantName" label="Name" required />
          <TextField
            control={control}
            name="slug"
            label="Slug"
            required
            hint="URL-safe identifier, e.g. sunset-bistro"
          />
          <TextField control={control} name="contactEmail" label="Contact email" required />
          <TextField control={control} name="phone" label="Phone (optional)" />

          <Text className={styles.section}>Admin user</Text>
          <TextField control={control} name="fullName" label="Full name" required />
          <TextField control={control} name="adminEmail" label="Email" required />
          <TextField
            control={control}
            name="password"
            label="Password"
            type="password"
            required
            hint="At least 8 characters"
          />

          {errorMessage && (
            <MessageBar intent="error">
              <MessageBarBody>{errorMessage}</MessageBarBody>
            </MessageBar>
          )}

          <Button appearance="primary" type="submit" disabled={mutation.isPending}>
            {mutation.isPending ? 'Creating…' : 'Create restaurant & sign in'}
          </Button>
        </form>
        <Divider style={{ marginTop: 20 }} />
        <div className={styles.alt}>
          Already have an account? <Link to="/login">Sign in</Link>
        </div>
      </Card>
    </div>
  );
}
