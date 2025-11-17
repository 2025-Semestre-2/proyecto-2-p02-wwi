import React from 'react'
import ReactDOM from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { SucursalProvider } from './context/SucursalContext'
import App from './App'
import './index.css'
import './App.css' 

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <BrowserRouter>
      <SucursalProvider>
        <App />
      </SucursalProvider>
    </BrowserRouter>
  </React.StrictMode>
)
