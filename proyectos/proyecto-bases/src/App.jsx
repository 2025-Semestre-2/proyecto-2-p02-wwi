import { Routes, Route, Navigate } from "react-router-dom";
import Home from "./pages/home/Home";
import Clientes from "./pages/clientes/Clientes"; 
import Inventarios from "./pages/inventarios/Inventarios"; 
import Proveedores from "./pages/proveedores/Proveedores"; 
import Ventas from "./pages/ventas/Ventas";
import Estadisticas from "./pages/estadisticas/Estadisticas";

function App() {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/home" />} />
      <Route path="/home" element={<Home />} />
      
      {/* Módulos del proyecto Wide World Importers */}
      <Route path="/clientes" element={<Clientes />} />
      <Route path="/proveedores" element={<Proveedores />} />
      <Route path="/inventarios" element={<Inventarios />} />
      <Route path="/ventas" element={<Ventas />} />
      <Route path="/estadisticas" element={<Estadisticas />} />
    </Routes>
  );
}

export default App;
