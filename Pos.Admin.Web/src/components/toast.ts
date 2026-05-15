import { useToastController, Toast, ToastTitle, ToastBody } from '@fluentui/react-components';
import { createElement, useCallback } from 'react';

export const TOASTER_ID = 'pos-admin-toaster';

export function useAppToast() {
  const { dispatchToast } = useToastController(TOASTER_ID);

  const showSuccess = useCallback(
    (title: string, body?: string) =>
      dispatchToast(
        createElement(
          Toast,
          null,
          createElement(ToastTitle, null, title),
          body ? createElement(ToastBody, null, body) : null
        ),
        { intent: 'success' }
      ),
    [dispatchToast]
  );

  const showError = useCallback(
    (title: string, body?: string) =>
      dispatchToast(
        createElement(
          Toast,
          null,
          createElement(ToastTitle, null, title),
          body ? createElement(ToastBody, null, body) : null
        ),
        { intent: 'error' }
      ),
    [dispatchToast]
  );

  return { showSuccess, showError };
}
