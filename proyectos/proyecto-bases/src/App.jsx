import { Routes, Route, Navigate } from "react-router-dom";
import { useSucursal } from "./context/SucursalContext";
import Login from "./pages/login/Login";
import Home from "./pages/home/Home";
import Clientes from "./pages/clientes/Clientes"; 
import Inventarios from "./pages/inventarios/Inventarios"; 
import Proveedores from "./pages/proveedores/Proveedores"; 
import Ventas from "./pages/ventas/Ventas";
import Estadisticas from "./pages/estadisticas/Estadisticas";

// Componente para rutas protegidas
function ProtectedRoute({ children }) {
  const { isAuthenticated } = useSucursal();
  return isAuthenticated ? children : <Navigate to="/login" />;
}

function App() {
  return (
    <Routes>
      {/* Ruta de login */}
      <Route path="/login" element={<Login />} />
      
      {/* Redirigir raíz a login */}
      <Route path="/" element={<Navigate to="/login" />} />
      
      {/* Rutas protegidas - requieren sucursal seleccionada */}
      <Route path="/home" element={<ProtectedRoute><Home /></ProtectedRoute>} />
      <Route path="/clientes" element={<ProtectedRoute><Clientes /></ProtectedRoute>} />
      <Route path="/proveedores" element={<ProtectedRoute><Proveedores /></ProtectedRoute>} />
      <Route path="/inventarios" element={<ProtectedRoute><Inventarios /></ProtectedRoute>} />
      <Route path="/ventas" element={<ProtectedRoute><Ventas /></ProtectedRoute>} />
      <Route path="/estadisticas" element={<ProtectedRoute><Estadisticas /></ProtectedRoute>} />
    </Routes>
  );
}

export default App;
