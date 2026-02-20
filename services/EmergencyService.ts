import { EmergencyContact, PatientProfile } from '../types';
import { LocationService } from './LocationService';

/**
 * EmergencyService
 * Orchestrates the "Safety Circle" logic.
 * 1. Fetches Location
 * 2. Formats Message
 * 3. Dispatches to Backend (Simulated)
 */

export const EmergencyService = {

  triggerSOS: async (patient: PatientProfile, onProgress: (status: string) => void) => {
    console.log('[SOS] Initiating Emergency Protocol...');
    onProgress('Obteniendo ubicación precisa...');

    // 1. Get Location (with timeout)
    const location = await LocationService.getCurrentLocation();
    
    let mapLink = 'Ubicación desconocida';
    if (location) {
      mapLink = `https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}`;
    }

    // 2. Prepare Message
    const messageBody = `ALERTA EPILEPSYCARE: ${patient.name.given[0]} ha entrado en ESTADO EPILÉPTICO (>5min). Requiere asistencia médica urgente. Ubicación: ${mapLink}`;

    // 3. Dispatch to Contacts
    if (patient.contacts.length === 0) {
      console.warn('[SOS] No contacts configured!');
      onProgress('Error: Sin contactos configurados.');
      return;
    }

    for (const contact of patient.contacts) {
      onProgress(`Notificando a ${contact.name}...`);
      await simulateSMSDispatch(contact, messageBody);
    }

    onProgress('Todos los contactos notificados.');
    console.log('[SOS] Protocol Completed.');
  }
};

// Simulation of a backend SMS service (Twilio/Firebase)
const simulateSMSDispatch = async (contact: EmergencyContact, body: string): Promise<void> => {
  return new Promise(resolve => {
    setTimeout(() => {
      console.log(`%c[SMS SENT] To: ${contact.phone} (${contact.relation})`, 'color: #39FF14; font-weight: bold;');
      console.log(`%c   Body: "${body}"`, 'color: #39FF14;');
      resolve();
    }, 1500); // Artificial delay to simulate network request
  });
};