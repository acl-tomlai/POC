import { Navigate, Route, Routes } from 'react-router-dom';
import { Login } from './pages/Login';
import { Signup } from './pages/Signup';
import { Dashboard } from './pages/Dashboard';
import { Categories } from './pages/categories/Categories';
import { Products } from './pages/products/Products';
import { Stores } from './pages/stores/Stores';
import { Orders } from './pages/orders/Orders';
import { Printers } from './pages/printers/Printers';
import { Users } from './pages/users/Users';
import { TenantSettings } from './pages/settings/TenantSettings';
import { AppShell } from './layout/AppShell';
import { ProtectedRoute } from './auth/ProtectedRoute';

export function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/signup" element={<Signup />} />

      <Route element={<ProtectedRoute />}>
        <Route element={<AppShell />}>
          <Route index element={<Dashboard />} />
          <Route path="products" element={<Products />} />
          <Route path="categories" element={<Categories />} />
          <Route path="stores" element={<Stores />} />
          <Route path="orders" element={<Orders />} />
          <Route path="printers" element={<Printers />} />

          <Route element={<ProtectedRoute roles={['Admin']} />}>
            <Route path="users" element={<Users />} />
            <Route path="settings" element={<TenantSettings />} />
          </Route>
        </Route>
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
