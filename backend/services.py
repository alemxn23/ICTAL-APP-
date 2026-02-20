import math
from datetime import datetime

class RiesgoEpilepsiaService:
    def __init__(self, user_profile, health_data, hrv_history):
        """
        :param user_profile: dict or object with last_dose_time, medication_frequency_hours, hrv_avg_30days
        :param health_data: dict with current_hrv, sleep_hours
        :param hrv_history: list of recent HRV measurements or pre-calculated average
        """
        self.profile = user_profile
        self.health = health_data
        self.hrv_media = hrv_history # ej. 45 ms (histórico)
        self.pesos = {"fae": 0.40, "vfc": 0.35, "sueno": 0.25}

    def calcular_riesgo_dinamico(self, now=None):
        if now is None:
            now = datetime.utcnow()
        
        riesgo = 5.00 # Riesgo basal (5.00%)

        # 1. Penalización Farmacocinética (FAE)
        horas_retraso = self.calcular_retraso_dosis(now)
        if horas_retraso > 0:
            # Decaimiento exponencial: El riesgo aumenta más rápido mientras más tiempo pasa
            penalizacion_fae = (1 - math.exp(-0.15 * horas_retraso)) * 100
            riesgo += (penalizacion_fae * self.pesos["fae"])

        # 2. Fluctuación Autonómica (VFC)
        vfc_actual = self.health.get("vfc_actual", 0)
        if self.hrv_media > 0 and vfc_actual < self.hrv_media:
            deficit_vfc = ((self.hrv_media - vfc_actual) / self.hrv_media) * 100
            riesgo += (deficit_vfc * self.pesos["vfc"])

        # 3. Impacto del Sueño
        horas_sueno = self.health.get("horas_sueno", 0)
        if horas_sueno < 7.0:
            deficit_sueno = ((7.0 - horas_sueno) / 7.0) * 100
            riesgo += (deficit_sueno * self.pesos["sueno"])

        # Formateo de alta precisión
        return round(min(riesgo, 99.99), 2)

    def calcular_retraso_dosis(self, now):
        if not self.profile.get("last_dose_time"):
            return 0
        
        last_dose = self.profile["last_dose_time"]
        frecuencia = self.profile.get("medication_frequency_hours", 12)
        
        # Proxima dosis en segundos
        proxima_dosis_timestamp = last_dose.timestamp() + (frecuencia * 3600)
        now_timestamp = now.timestamp()
        
        if now_timestamp > proxima_dosis_timestamp:
            return (now_timestamp - proxima_dosis_timestamp) / 3600
        return 0
