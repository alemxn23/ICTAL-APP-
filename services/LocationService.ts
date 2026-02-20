/**
 * LocationService
 * Handles high-priority geolocation requests for emergency SOS.
 * Includes a race-condition timeout to ensure we don't block the SOS alert
 * if GPS is slow/unavailable inside buildings.
 */

export interface GeoCoords {
  latitude: number;
  longitude: number;
  accuracy?: number;
}

const TIMEOUT_MS = 10000; // 10 seconds max wait for GPS

export const LocationService = {
  
  getCurrentLocation: async (): Promise<GeoCoords | null> => {
    if (!navigator.geolocation) {
      console.warn('[LOCATION] Geolocation not supported by browser');
      return null;
    }

    const locationPromise = new Promise<GeoCoords>((resolve, reject) => {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          resolve({
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            accuracy: position.coords.accuracy
          });
        },
        (error) => {
          reject(error);
        },
        {
          enableHighAccuracy: true,
          timeout: TIMEOUT_MS - 500, // Slightly less than the race timeout
          maximumAge: 30000 // Accept cache if < 30s old
        }
      );
    });

    const timeoutPromise = new Promise<null>((resolve) => {
      setTimeout(() => {
        console.warn('[LOCATION] Request timed out, proceeding with null location.');
        resolve(null);
      }, TIMEOUT_MS);
    });

    try {
      // Race: Whichever finishes first. We prioritize speed for SOS.
      return await Promise.race([locationPromise, timeoutPromise]);
    } catch (e) {
      console.error('[LOCATION] Error fetching location:', e);
      return null;
    }
  }
};