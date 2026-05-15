import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { FluentProvider, Toaster, webLightTheme } from '@fluentui/react-components';
import { App } from './App';
import { TOASTER_ID } from './components/toast';
import './index.css';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
      staleTime: 30_000,
    },
  },
});

const container = document.getElementById('root');
if (!container) throw new Error('Missing #root element in index.html');

createRoot(container).render(
  <StrictMode>
    <FluentProvider theme={webLightTheme} style={{ minHeight: '100vh' }}>
      <QueryClientProvider client={queryClient}>
        <BrowserRouter>
          <App />
        </BrowserRouter>
        <Toaster toasterId={TOASTER_ID} position="top-end" />
      </QueryClientProvider>
    </FluentProvider>
  </StrictMode>
);
