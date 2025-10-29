import React from 'react';
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import { MapPin } from 'lucide-react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import styles from './MapComponent.module.css';

// Configurar íconos de Leaflet (fix para webpack)
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
});

/**
 * Componente de Mapa con Leaflet
 * Muestra un mapa interactivo con la ubicación del cliente
 */
const MapComponent = ({ 
  latitud, 
  longitud, 
  ciudad, 
  direccion,
  height = '300px'
}) => {
  // Validar coordenadas
  const isValidLocation = latitud && longitud && 
                         !isNaN(parseFloat(latitud)) && 
                         !isNaN(parseFloat(longitud)) &&
                         parseFloat(latitud) !== 0 &&
                         parseFloat(longitud) !== 0;

  if (!isValidLocation) {
    return (
      <div className={styles.mapPlaceholder} style={{ height }}>
        <MapPin size={48} className={styles.mapIcon} />
        <div className={styles.mapContent}>
          <h4>📍 Ubicación no disponible</h4>
          <p>No hay coordenadas geográficas para esta ubicación</p>
          {ciudad && <p><strong>Ciudad:</strong> {ciudad}</p>}
          {direccion && <p><strong>Dirección:</strong> {direccion}</p>}
          <small>Para mostrar el mapa real, se requiere integración con Google Maps o Leaflet</small>
        </div>
      </div>
    );
  }

  const lat = parseFloat(latitud);
  const lng = parseFloat(longitud);

  // URL para abrir en Google Maps
  const googleMapsUrl = `https://www.google.com/maps?q=${lat},${lng}`;

  return (
    <div className={styles.mapContainer} style={{ height }}>
      <MapContainer 
        center={[lat, lng]} 
        zoom={13} 
        style={{ height: '100%', width: '100%' }}
        scrollWheelZoom={false}
      >
        <TileLayer
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        />
        <Marker position={[lat, lng]}>
          <Popup>
            <div className={styles.popupContent}>
              <h4>📍 {ciudad}</h4>
              {direccion && <p><strong>Dirección:</strong> {direccion}</p>}
              <p><strong>Coordenadas:</strong></p>
              <p>Lat: {lat.toFixed(6)}, Lng: {lng.toFixed(6)}</p>
              <a 
                href={googleMapsUrl} 
                target="_blank" 
                rel="noopener noreferrer"
                className={styles.googleMapsLink}
              >
                🗺️ Ver en Google Maps
              </a>
            </div>
          </Popup>
        </Marker>
      </MapContainer>
      
      {/* Información adicional debajo del mapa */}
      <div className={styles.mapInfo}>
        <div className={styles.coordinatesInfo}>
          <MapPin size={16} />
          <span>{ciudad} - Lat: {lat.toFixed(6)}, Lng: {lng.toFixed(6)}</span>
        </div>
        <a 
          href={googleMapsUrl} 
          target="_blank" 
          rel="noopener noreferrer"
          className={styles.externalLink}
        >
          Abrir en Google Maps ↗
        </a>
      </div>
    </div>
  );
};

export default MapComponent;
