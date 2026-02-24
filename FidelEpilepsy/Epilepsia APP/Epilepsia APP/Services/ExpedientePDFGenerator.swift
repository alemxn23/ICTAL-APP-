import Foundation
import WebKit
import UIKit

// MARK: - ExpedientePDFGenerator
// Genera un PDF médico profesional usando WebKit para renderizar HTML.
// Proceso: datos → HTML → WKWebView → UIPrintPageRenderer → Data → archivo temporal
// El archivo resultante se pasa a UIActivityViewController para el Share Sheet.

actor ExpedientePDFGenerator {

    static let shared = ExpedientePDFGenerator()
    private init() {}

    // MARK: - Punto de Entrada Principal

    /// Genera el PDF y devuelve la URL al archivo temporal listo para compartir.
    func generarExpediente(
        perfil: PerfilClinicoDB?,
        medicamentos: [Medicamento],
        eventos: [EventoIctalDB],
        perfilLocal: PerfilUsuario
    ) async throws -> URL {

        let html = construirHTML(
            perfil: perfil,
            medicamentos: medicamentos,
            eventos: eventos,
            perfilLocal: perfilLocal
        )

        // El renderizado de WebKit debe ocurrir en el hilo principal
        let pdfData = try await MainActor.run {
            try renderizarHTMLaPDF(html: html)
        }

        return try guardarArchivoPDF(data: pdfData)
    }

    // MARK: - Renderizado WebKit → PDF

    @MainActor
    private func renderizarHTMLaPDF(html: String) throws -> Data {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        let webView = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 595, height: 842), // A4 en puntos (72 ppp)
            configuration: config
        )
        webView.loadHTMLString(html, baseURL: nil)

        // Espera síncrona usando DispatchSemaphore (solo en Task background)
        let semaphore = DispatchSemaphore(value: 0)
        var pdfData: Data = Data()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let renderer = UIPrintPageRenderer()
            renderer.addPrintFormatter(webView.viewPrintFormatter(), startingAtPageAt: 0)

            let pageSize = CGSize(width: 595.2, height: 841.8)           // A4
            let printable = pageSize.inset(by: UIEdgeInsets(             // margen 36pt
                top: 36, left: 36, bottom: 36, right: 36))

            renderer.setValue(NSValue(cgRect: CGRect(origin: .zero, size: pageSize)),
                              forKey: "paperRect")
            renderer.setValue(NSValue(cgRect: CGRect(origin: CGPoint(x: 36, y: 36),
                                                     size: printable)),
                              forKey: "printableRect")
            let pdfMutable = NSMutableData()
            UIGraphicsBeginPDFContextToData(pdfMutable, .zero, nil)
            for page in 0..<renderer.numberOfPages {
                UIGraphicsBeginPDFPage()
                renderer.drawPage(at: page, in: UIGraphicsGetPDFContextBounds())
            }
            UIGraphicsEndPDFContext()
            pdfData = pdfMutable as Data
            semaphore.signal()
        }
        semaphore.wait()
        return pdfData
    }

    // MARK: - Guardar en archivo temporal

    private func guardarArchivoPDF(data: Data) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let nombre = "Expediente_\(formatter.string(from: Date())).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(nombre)
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: - Template HTML

    private func construirHTML(
        perfil: PerfilClinicoDB?,
        medicamentos: [Medicamento],
        eventos: [EventoIctalDB],
        perfilLocal: PerfilUsuario
    ) -> String {

        let nombrePaciente = perfil?.nombre_completo ?? perfilLocal.nombreCompleto
        let peso = perfil?.peso_kg ?? perfilLocal.pesoKg
        let sexo = perfil?.sexo ?? perfilLocal.sexo.rawValue
        let edad = perfilLocal.edad

        let fechaReporte = Date().formatted(.dateTime.day().month(.wide).year())

        // Tabla de medicamentos
        let filaMed = medicamentos.map { med in
            """
            <tr>
                <td>\(med.nombre)</td>
                <td>\(Int(med.dosisMg)) mg</td>
                <td>\(med.frecuencia.rawValue)</td>
                <td>\(String(format: "%.2f", med.dosisMg / Double(peso))) mg/kg</td>
            </tr>
            """
        }.joined()

        // Tabla de eventos ictales
        let filaEvento = eventos.prefix(30).map { ev in
            """
            <tr>
                <td>\(formatearFecha(ev.fecha_inicio))</td>
                <td>\(ev.tipo_crisis ?? "No especificado")</td>
                <td>\(ev.duracion_segundos.map { "\($0) seg" } ?? "—")</td>
                <td>\(ev.intensidad.map { "\($0)/10" } ?? "—")</td>
                <td>\(ev.nota_paciente ?? "")</td>
            </tr>
            """
        }.joined()

        let totalEventos = eventos.count
        let durPromedio = eventos.compactMap(\.duracion_segundos).reduce(0, +) /
                          max(1, eventos.filter { $0.duracion_segundos != nil }.count)

        return """
        <!DOCTYPE html>
        <html lang="es">
        <head>
        <meta charset="UTF-8">
        <style>
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body { font-family: -apple-system, 'SF Pro Text', Helvetica, Arial, sans-serif;
                   font-size: 11px; color: #1d1d1f; background: white; padding: 0 4px; }
            .header { background: #1c1c1e; color: white; padding: 20px 24px;
                      border-radius: 10px; margin-bottom: 20px; }
            .header h1 { font-size: 20px; font-weight: 700; letter-spacing: -0.5px; }
            .header p  { font-size: 11px; color: #aeaeb2; margin-top: 4px; }
            .badge { display: inline-block; background: #34c759; color: white;
                     font-size: 9px; font-weight: 700; padding: 2px 8px;
                     border-radius: 20px; margin-top: 6px; }
            .seccion { margin-bottom: 18px; }
            .seccion-titulo { font-size: 10px; font-weight: 700; color: #8e8e93;
                              text-transform: uppercase; letter-spacing: 0.8px;
                              margin-bottom: 8px; border-bottom: 1px solid #e5e5ea;
                              padding-bottom: 4px; }
            .ficha { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 12px; }
            .dato { background: #f2f2f7; border-radius: 8px; padding: 10px 14px;
                    flex: 1; min-width: 80px; }
            .dato label { font-size: 9px; color: #8e8e93; font-weight: 600;
                          text-transform: uppercase; display: block; margin-bottom: 3px; }
            .dato span  { font-size: 15px; font-weight: 700; color: #1d1d1f; }
            table { width: 100%; border-collapse: collapse; font-size: 10.5px; }
            th { background: #f2f2f7; font-weight: 700; color: #3a3a3c;
                 padding: 7px 10px; text-align: left; border-radius: 4px; }
            td { padding: 6px 10px; border-bottom: 1px solid #f2f2f7; color: #3a3a3c; }
            tr:last-child td { border-bottom: none; }
            .alerta { background: #fff3cd; border-left: 3px solid #ff9500;
                      padding: 8px 12px; border-radius: 6px; margin-top: 6px;
                      font-size: 10.5px; color: #6d4c00; }
            .footer { text-align: center; color: #aeaeb2; font-size: 9px;
                      margin-top: 24px; border-top: 1px solid #e5e5ea; padding-top: 12px; }
            .resumen-kpi { display: flex; gap: 8px; }
            .kpi { flex: 1; background: #1c1c1e; color: white; border-radius: 8px;
                   padding: 10px 12px; text-align: center; }
            .kpi .numero { font-size: 24px; font-weight: 800; }
            .kpi .label  { font-size: 9px; color: #aeaeb2; margin-top: 2px; }
        </style>
        </head>
        <body>

        <!-- CABECERA -->
        <div class="header">
            <h1>Expediente Clínico — ICTAL</h1>
            <p>Generado el \(fechaReporte) · Reporte mensual (últimos 30 días)</p>
            <span class="badge">DOCUMENTO MÉDICO CONFIDENCIAL</span>
        </div>

        <!-- DATOS DEL PACIENTE -->
        <div class="seccion">
            <div class="seccion-titulo">Datos del Paciente</div>
            <div class="ficha">
                <div class="dato"><label>Nombre</label><span>\(nombrePaciente)</span></div>
                <div class="dato"><label>Edad</label><span>\(edad) años</span></div>
                <div class="dato"><label>Sexo</label><span>\(sexo)</span></div>
                <div class="dato"><label>Peso</label><span>\(peso) kg</span></div>
            </div>
        </div>

        <!-- KPI DE CRISIS -->
        <div class="seccion">
            <div class="seccion-titulo">Resumen del Período (30 días)</div>
            <div class="resumen-kpi">
                <div class="kpi">
                    <div class="numero">\(totalEventos)</div>
                    <div class="label">Crisis Registradas</div>
                </div>
                <div class="kpi">
                    <div class="numero">\(durPromedio)s</div>
                    <div class="label">Duración Promedio</div>
                </div>
                <div class="kpi">
                    <div class="numero">\(String(format: "%.1f", Double(totalEventos) / 4.3))</div>
                    <div class="label">Crisis / Semana</div>
                </div>
            </div>
        </div>

        <!-- MEDICAMENTOS -->
        <div class="seccion">
            <div class="seccion-titulo">Fármacos Antiepilépticos (FAE) Actuales</div>
            \(medicamentos.isEmpty ?
              "<p style='color:#8e8e93;font-size:11px'>Sin medicación registrada.</p>" :
            """
            <table>
                <thead><tr>
                    <th>Fármaco</th><th>Dosis</th><th>Frecuencia</th><th>mg/kg</th>
                </tr></thead>
                <tbody>\(filaMed)</tbody>
            </table>
            """)
            \(medicamentos.contains { $0.nombre.lowercased().contains("valproico") } && sexo == "Femenino" ?
              "<div class='alerta'>⚠️ Riesgo teratogénico: Ácido Valproico documentado en paciente femenino. Notificar al médico tratante.</div>" : "")
        </div>

        <!-- REGISTRO DE CRISIS -->
        <div class="seccion">
            <div class="seccion-titulo">Registro de Events Ictales</div>
            \(eventos.isEmpty ?
              "<p style='color:#8e8e93;font-size:11px'>Sin eventos registrados en los últimos 30 días.</p>" :
            """
            <table>
                <thead><tr>
                    <th>Fecha</th><th>Tipo</th><th>Duración</th><th>Intensidad</th><th>Nota</th>
                </tr></thead>
                <tbody>\(filaEvento)</tbody>
            </table>
            """)
        </div>

        <div class="footer">
            Generado automáticamente por ICTAL · Este documento no reemplaza el criterio médico profesional.
        </div>
        </body>
        </html>
        """
    }

    private func formatearFecha(_ isoString: String) -> String {
        let isoF = ISO8601DateFormatter()
        isoF.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let fecha = isoF.date(from: isoString) else { return isoString }
        return fecha.formatted(.dateTime.day().month(.abbreviated).hour().minute())
    }
}

// MARK: - CGSize Extension para márgenes

private extension CGSize {
    func inset(by insets: UIEdgeInsets) -> CGSize {
        CGSize(width: width - insets.left - insets.right,
               height: height - insets.top - insets.bottom)
    }
}
