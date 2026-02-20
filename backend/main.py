import os
import json
import math
import datetime
from typing import Optional, List

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr
from sqlalchemy.orm import Session
import google.generativeai as genai
from dotenv import load_dotenv

from database import get_db, User, HRVHistory

# --- Config ---
load_dotenv()
API_KEY = os.getenv("GEMINI_API_KEY")
if API_KEY:
    genai.configure(api_key=API_KEY)

app = FastAPI(
    title="EpilepsiaCare AI Backend",
    description="Backend para monitoreo dinámico de riesgo de crisis epiléptica.",
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─────────────────────────────────────────────────────────────────────────────
# Pydantic Models (API Contracts)
# ─────────────────────────────────────────────────────────────────────────────

class TermsAcceptance(BaseModel):
    """
    Payload de onboarding. El usuario DEBE aceptar los T&C médicos
    antes de que el sistema empiece a recolectar biometría.
    """
    email: str
    full_name: str
    age: int
    weight: float
    medication_frequency_hours: int = 12
    terms_accepted: bool

class DatosHealthKit(BaseModel):
    """
    Payload que la app envía cada 15 minutos desde HealthKit / Apple Watch.
    """
    user_id: int
    vfc_actual: float           # VFC actual en ms (ej. 38.0)
    horas_sueno_efectivo: float # Horas de sueño efectivo (ej. 6.5)
    ultima_dosis_timestamp: Optional[float] = None  # Unix timestamp de la última dosis

class RiesgoResponse(BaseModel):
    riesgo_porcentaje: float   # ej. 18.45
    estado: str                # VERDE, PRECAUCIÓN, ALERTA
    alerta_critica: bool       # True si > 40% — dispara push al frontend
    mensaje_clinico: str
    desglose: dict             # Detalle de cada componente del riesgo

# ─────────────────────────────────────────────────────────────────────────────
# Core Risk Calculation Logic (Python port of RiesgoEpilepsiaService)
# ─────────────────────────────────────────────────────────────────────────────

PESOS = {"fae": 0.40, "vfc": 0.35, "sueno": 0.25}

def calcular_retraso_dosis(
    now_ts: float,
    ultima_dosis_ts: Optional[float],
    frecuencia_horas: int,
) -> float:
    """Retorna las horas de retraso desde que debió tomarse la siguiente dosis."""
    if ultima_dosis_ts is None:
        return 0.0
    proxima_dosis_ts = ultima_dosis_ts + (frecuencia_horas * 3600)
    if now_ts > proxima_dosis_ts:
        return (now_ts - proxima_dosis_ts) / 3600
    return 0.0

def calcular_riesgo(
    vfc_media_historica: float,
    datos: DatosHealthKit,
    ultima_dosis_ts: Optional[float],
    frecuencia_horas: int,
) -> dict:
    """
    Reproduce exactamente la lógica de RiesgoEpilepsiaService.js:
      - Riesgo basal:     5.00%
      - Penalización FAE: peso 0.40 (decaimiento exponencial)
      - Fluctuación VFC:  peso 0.35 (% de caída respecto a media histórica)
      - Impacto Sueño:    peso 0.25 (déficit respecto a 7hs óptimas)
    """
    now_ts = datetime.datetime.utcnow().timestamp()
    riesgo = 5.00

    # 1. FAE — Farmacocinética
    horas_retraso = calcular_retraso_dosis(now_ts, ultima_dosis_ts, frecuencia_horas)
    penalizacion_fae = 0.0
    if horas_retraso > 0:
        penalizacion_fae = (1 - math.exp(-0.15 * horas_retraso)) * 100
        riesgo += penalizacion_fae * PESOS["fae"]

    # 2. VFC — Fluctuación Autonómica
    penalizacion_vfc = 0.0
    if vfc_media_historica > 0 and datos.vfc_actual < vfc_media_historica:
        deficit_vfc = ((vfc_media_historica - datos.vfc_actual) / vfc_media_historica) * 100
        penalizacion_vfc = deficit_vfc
        riesgo += deficit_vfc * PESOS["vfc"]

    # 3. Sueño
    penalizacion_sueno = 0.0
    if datos.horas_sueno_efectivo < 7.0:
        deficit_sueno = ((7.0 - datos.horas_sueno_efectivo) / 7.0) * 100
        penalizacion_sueno = deficit_sueno
        riesgo += deficit_sueno * PESOS["sueno"]

    riesgo_final = round(min(riesgo, 99.99), 2)

    return {
        "riesgo_porcentaje": riesgo_final,
        "desglose": {
            "basal": 5.00,
            "fae_horas_retraso": round(horas_retraso, 2),
            "fae_penalizacion": round(penalizacion_fae * PESOS["fae"], 2),
            "vfc_media_historica_ms": round(vfc_media_historica, 2),
            "vfc_actual_ms": datos.vfc_actual,
            "vfc_penalizacion": round(penalizacion_vfc * PESOS["vfc"], 2),
            "sueno_horas": datos.horas_sueno_efectivo,
            "sueno_penalizacion": round(penalizacion_sueno * PESOS["sueno"], 2),
        },
    }

def estado_desde_riesgo(riesgo: float) -> tuple[str, str]:
    """Retorna (estado, mensaje_clinico) según la escala de riesgo."""
    if riesgo < 20:
        return "VERDE", "Tus variables están estables. Sigue con tu rutina normal."
    elif riesgo < 40:
        return "PRECAUCIÓN", "Tus marcadores muestran algo de estrés. Descansa y recuerda tu medicación."
    else:
        return "ALERTA", "Riesgo elevado detectado. Considera activar el Protocolo SOS o descansar ahora."

# ─────────────────────────────────────────────────────────────────────────────
# Endpoints
# ─────────────────────────────────────────────────────────────────────────────

TERMINOS_Y_CONDICIONES = """
TÉRMINOS Y CONDICIONES MÉDICOS — EpilepsiaCare AI

1. PROPÓSITO: Esta aplicación es una herramienta de apoyo para el monitoreo de pacientes con epilepsia.
   NO sustituye el diagnóstico ni el tratamiento médico profesional.

2. DATOS BIOMÉTRICOS: Usted autoriza explícitamente la recolección, almacenamiento y análisis de:
   - Variabilidad de Frecuencia Cardíaca (VFC/HRV)
   - Horas y calidad de sueño
   - Historial de medicación antiepileptica (FAE)

3. FINALIDAD: Los datos se usarán exclusivamente para calcular su índice de riesgo de crisis
   en tiempo real y proveer alertas preventivas personalizadas.

4. PRIVACIDAD: Sus datos no serán vendidos ni compartidos con terceros sin su consentimiento.
   Se almacenan con cifrado de grado médico.

5. LIMITACIÓN DE RESPONSABILIDAD: El valor de riesgo provisto es una estimación estadística.
   Ante cualquier síntoma de crisis, acuda inmediatamente a urgencias.

6. REVOCACIÓN: Puede solicitar la eliminación de sus datos en cualquier momento desde el perfil.
"""

@app.get("/terms", summary="Obtener Términos y Condiciones")
def get_terms():
    """Retorna el texto completo de los T&C médicos para mostrarse en el onboarding."""
    return {"terms": TERMINOS_Y_CONDICIONES.strip()}


@app.post("/onboarding", summary="Registrar Usuario + Aceptación de T&C")
def onboarding(payload: TermsAcceptance, db: Session = Depends(get_db)):
    """
    Endpoint de onboarding. Requiere aceptación explícita de T&C médicos.
    Sin terms_accepted=True el usuario no se registra y la biometría no se recolecta.
    """
    if not payload.terms_accepted:
        raise HTTPException(
            status_code=400,
            detail="Debe aceptar los Términos y Condiciones médicos para continuar.",
        )

    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=409, detail="El usuario ya existe.")

    user = User(
        email=payload.email,
        full_name=payload.full_name,
        age=payload.age,
        weight=payload.weight,
        medication_frequency_hours=payload.medication_frequency_hours,
        terms_accepted=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return {"user_id": user.id, "message": "Registro exitoso. Bienvenido a EpilepsiaCare AI."}


@app.post("/report", response_model=RiesgoResponse, summary="Reportar Biometría (cada 15 min)")
def report_health(payload: DatosHealthKit, db: Session = Depends(get_db)):
    """
    Recibe el payload de HealthKit cada 15 minutos.
    1. Almacena el valor VFC en el histórico longitudinal del usuario.
    2. Calcula la media de VFC de los últimos 30 días.
    3. Ejecuta RiesgoEpilepsiaService con todos los factores.
    4. Si riesgo > 40% → alerta_critica=True (el frontend hace push al Dashboard Vivo).
    """
    user = db.query(User).filter(User.id == payload.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado.")
    if not user.terms_accepted:
        raise HTTPException(status_code=403, detail="El usuario no ha aceptado los T&C.")

    # Actualizar última dosis si se provee
    if payload.ultima_dosis_timestamp is not None:
        user.last_dose_time = datetime.datetime.utcfromtimestamp(payload.ultima_dosis_timestamp)
        db.commit()

    # Guardar VFC actual en histórico
    hrv_entry = HRVHistory(vfc_value=payload.vfc_actual, user_id=user.id)
    db.add(hrv_entry)
    db.commit()

    # Calcular media VFC de los últimos 30 días (~2880 lecturas a 15 min)
    treinta_dias_atras = datetime.datetime.utcnow() - datetime.timedelta(days=30)
    historico = (
        db.query(HRVHistory)
        .filter(HRVHistory.user_id == user.id, HRVHistory.timestamp >= treinta_dias_atras)
        .all()
    )
    vfc_media = (
        sum(h.vfc_value for h in historico) / len(historico) if historico else payload.vfc_actual
    )

    # Calcular riesgo dinámico
    ultima_dosis_ts = user.last_dose_time.timestamp() if user.last_dose_time else None
    resultado = calcular_riesgo(vfc_media, payload, ultima_dosis_ts, user.medication_frequency_hours)
    riesgo = resultado["riesgo_porcentaje"]

    estado, mensaje = estado_desde_riesgo(riesgo)
    alerta_critica = riesgo > 40.0

    return RiesgoResponse(
        riesgo_porcentaje=riesgo,
        estado=estado,
        alerta_critica=alerta_critica,
        mensaje_clinico=mensaje,
        desglose=resultado["desglose"],
    )


@app.get("/user/{user_id}/status", summary="Estado Actual del Paciente")
def get_user_status(user_id: int, db: Session = Depends(get_db)):
    """Retorna el perfil del usuario y su media de VFC histórica de 30 días."""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado.")

    treinta_dias_atras = datetime.datetime.utcnow() - datetime.timedelta(days=30)
    historico = (
        db.query(HRVHistory)
        .filter(HRVHistory.user_id == user.id, HRVHistory.timestamp >= treinta_dias_atras)
        .all()
    )
    vfc_media = (
        round(sum(h.vfc_value for h in historico) / len(historico), 2) if historico else None
    )

    return {
        "user_id": user.id,
        "full_name": user.full_name,
        "medication_frequency_hours": user.medication_frequency_hours,
        "last_dose_time": user.last_dose_time,
        "vfc_media_30dias_ms": vfc_media,
        "total_lecturas": len(historico),
    }


@app.get("/", summary="Health Check")
def root():
    return {"status": "ok", "service": "EpilepsiaCare AI Backend v2.0"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
