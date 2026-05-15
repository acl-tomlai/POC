import {
  Button,
  Card,
  CardHeader,
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
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { login as loginApi } from '@/api/auth';
import { useAuthStore } from '@/auth/authStore';
import { extractApiErrorMessage } from '@/api/client';
import { TextField } from '@/components/fields';

const schema = z.object({
  email: z.string().email('Enter a valid email'),
  password: z.string().min(1, 'Password is required'),
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
    width: '380px',
    padding: '24px',
  },
  brand: {
    textAlign: 'center',
    marginBottom: '24px',
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

export function Login() {
  const styles = useStyles();
  const navigate = useNavigate();
  const location = useLocation();
  const signIn = useAuthStore((s) => s.signIn);

  const { control, handleSubmit } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { email: '', password: '' },
  });

  const mutation = useMutation({
    mutationFn: loginApi,
    onSuccess: (response) => {
      signIn(response);
      const from = (location.state as { from?: string } | null)?.from ?? '/';
      navigate(from, { replace: true });
    },
  });

  const errorMessage = mutation.isError ? extractApiErrorMessage(mutation.error) : null;

  return (
    <div className={styles.page}>
      <Card className={styles.card}>
        <div className={styles.brand}>
          <Text size={700} weight="semibold">
            POS Admin
          </Text>
        </div>
        <CardHeader header={<Text weight="semibold">Sign in to your restaurant</Text>} />
        <form
          className={styles.form}
          onSubmit={handleSubmit((values) => mutation.mutate(values))}
        >
          <TextField control={control} name="email" label="Email" required />
          <TextField control={control} name="password" label="Password" type="password" required />
          {errorMessage && (
            <MessageBar intent="error">
              <MessageBarBody>{errorMessage}</MessageBarBody>
            </MessageBar>
          )}
          <Button appearance="primary" type="submit" disabled={mutation.isPending}>
            {mutation.isPending ? 'Signing in…' : 'Sign in'}
          </Button>
        </form>
        <Divider style={{ marginTop: 20 }}>or</Divider>
        <div className={styles.alt}>
          New here? <Link to="/signup">Create a restaurant</Link>
        </div>
      </Card>
    </div>
  );
}
