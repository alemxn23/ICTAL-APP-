"""
Test unitario para la lógica de RiesgoEpilepsiaService (backend/services.py).
Ejecutar con: python backend/test_logic.py
"""
import math
import datetime
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from services import RiesgoEpilepsiaService

PASS = "\033[92m✓ PASS\033[0m"
FAIL = "\033[91m✗ FAIL\033[0m"

def run(name, condition):
    status = PASS if condition else FAIL
    print(f"  {status}  {name}")
    return condition

def test_riesgo_basal():
    """Sin ninguna penalización, el riesgo debe ser exactamente 5.00%."""
    svc = RiesgoEpilepsiaService(
        user_profile={"last_dose_time": None, "medication_frequency_hours": 12},
        health_data={"vfc_actual": 45, "horas_sueno": 8},
        hrv_history=45,
    )
    r = svc.calcular_riesgo_dinamico()
    return run("Riesgo basal = 5.00", r == 5.00)

def test_penalizacion_fae():
    """Con 4 horas de retraso de dosis el riesgo debe subir considerablemente."""
    now = datetime.datetime.utcnow()
    # Simulamos que la última dosis fue hace 16 horas (frecuencia cada 12 → 4h de retraso)
    last_dose = now - datetime.timedelta(hours=16)
    svc = RiesgoEpilepsiaService(
        user_profile={"last_dose_time": last_dose, "medication_frequency_hours": 12},
        health_data={"vfc_actual": 45, "horas_sueno": 8},
        hrv_history=45,
    )
    r = svc.calcular_riesgo_dinamico(now=now)
    # Con 4h de retraso: penalizacion = (1 - exp(-0.6)) * 100 * 0.40 ≈ 18.14
    expected_min = 5.00 + 15.0  # debe ser notablemente más alto
    return run(f"Penalización FAE (4h retraso) → riesgo={r:.2f} > {expected_min}", r > expected_min)

def test_penalizacion_vfc():
    """Si VFC actual (38ms) < media histórica (50ms), debe sumar penalización."""
    svc = RiesgoEpilepsiaService(
        user_profile={"last_dose_time": None, "medication_frequency_hours": 12},
        health_data={"vfc_actual": 38, "horas_sueno": 8},
        hrv_history=50,
    )
    r = svc.calcular_riesgo_dinamico()
    # Deficit VFC = (50-38)/50 * 100 * 0.35 = 8.40
    expected = 5.00 + 8.40
    return run(f"Penalización VFC (38ms vs 50ms) → riesgo={r:.2f} ≈ {expected:.2f}", abs(r - expected) < 0.5)

def test_penalizacion_sueno():
    """Con 5 horas de sueño (< 7h recomendadas) debe aplicar penalización."""
    svc = RiesgoEpilepsiaService(
        user_profile={"last_dose_time": None, "medication_frequency_hours": 12},
        health_data={"vfc_actual": 45, "horas_sueno": 5},
        hrv_history=45,
    )
    r = svc.calcular_riesgo_dinamico()
    # Deficit sueño = (7-5)/7 * 100 * 0.25 = 7.14
    expected = 5.00 + 7.14
    return run(f"Penalización sueño (5h) → riesgo={r:.2f} ≈ {expected:.2f}", abs(r - expected) < 0.5)

def test_escenario_combinado():
    """Escenario de alto riesgo: dosis retrasada + VFC baja + poco sueño → > 40%."""
    now = datetime.datetime.utcnow()
    last_dose = now - datetime.timedelta(hours=18)  # 6h de retraso
    svc = RiesgoEpilepsiaService(
        user_profile={"last_dose_time": last_dose, "medication_frequency_hours": 12},
        health_data={"vfc_actual": 28, "horas_sueno": 4},
        hrv_history=55,
    )
    r = svc.calcular_riesgo_dinamico(now=now)
    return run(f"Escenario crítico combinado → riesgo={r:.2f} > 40%", r > 40.0)

def test_tope_maximo():
    """El riesgo nunca debe superar 99.99%."""
    now = datetime.datetime.utcnow()
    last_dose = now - datetime.timedelta(hours=72)  # 60h de retraso extremo
    svc = RiesgoEpilepsiaService(
        user_profile={"last_dose_time": last_dose, "medication_frequency_hours": 12},
        health_data={"vfc_actual": 5, "horas_sueno": 0},
        hrv_history=100,
    )
    r = svc.calcular_riesgo_dinamico(now=now)
    return run(f"Tope máximo = 99.99 → riesgo={r}", r <= 99.99)

if __name__ == "__main__":
    print("\n🧪 EpilepsiaCare AI — Test de Lógica de Riesgo\n")
    results = [
        test_riesgo_basal(),
        test_penalizacion_fae(),
        test_penalizacion_vfc(),
        test_penalizacion_sueno(),
        test_escenario_combinado(),
        test_tope_maximo(),
    ]
    passed = sum(results)
    total = len(results)
    print(f"\n{'─'*40}")
    print(f"Resultado: {passed}/{total} tests pasaron\n")
    sys.exit(0 if passed == total else 1)
