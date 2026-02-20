// supabase/functions/eliminar-cuenta/index.ts
// Deno Edge Function — Cascade Delete transaccional
// Deploy con: supabase functions deploy eliminar-cuenta
// Requiere secret: SUPABASE_SERVICE_ROLE_KEY configurado en Supabase Dashboard

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
    // Preflight CORS
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        // 1. Extraer y verificar el JWT del usuario desde el header Authorization
        const authHeader = req.headers.get("Authorization");
        if (!authHeader?.startsWith("Bearer ")) {
            return new Response(
                JSON.stringify({ error: "Token de autorización requerido." }),
                { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }
        const userToken = authHeader.replace("Bearer ", "");

        // 2. Cliente con ROL DE USUARIO — para verificar identidad del solicitante
        const supabaseUser = createClient(
            Deno.env.get("SUPABASE_URL")!,
            Deno.env.get("SUPABASE_ANON_KEY")!,
            { global: { headers: { Authorization: `Bearer ${userToken}` } } }
        );

        const { data: { user }, error: userError } = await supabaseUser.auth.getUser();
        if (userError || !user) {
            return new Response(
                JSON.stringify({ error: "No se pudo autenticar al usuario." }),
                { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }
        const userId = user.id;

        // 3. Cliente con SERVICE ROLE — privilegios de administrador para cascade delete
        const supabaseAdmin = createClient(
            Deno.env.get("SUPABASE_URL")!,
            Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
        );

        // 4. CASCADE DELETE TRANSACCIONAL
        // Orden: tablas hijas primero → tabla raíz → auth.users

        // 4a. Eliminar eventos ictales (diario clínico)
        const { error: errorEventos } = await supabaseAdmin
            .from("eventos_ictales")
            .delete()
            .eq("user_id", userId);

        if (errorEventos) {
            console.error("[eliminar-cuenta] Error borrando eventos_ictales:", errorEventos);
            return new Response(
                JSON.stringify({ error: "Error al eliminar el diario clínico." }),
                { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        // 4b. Eliminar perfil clínico (datos fisiológicos, medicamentos)
        const { error: errorPerfil } = await supabaseAdmin
            .from("perfil_clinico")
            .delete()
            .eq("user_id", userId);

        if (errorPerfil) {
            console.error("[eliminar-cuenta] Error borrando perfil_clinico:", errorPerfil);
            return new Response(
                JSON.stringify({ error: "Error al eliminar el perfil clínico." }),
                { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        // 4c. Eliminar contactos de emergencia
        await supabaseAdmin
            .from("contactos_emergencia")
            .delete()
            .eq("user_id", userId);

        // 4d. Eliminar usuario de auth.users (GDPR/ARCO — soft delete disponible como alternativa)
        const { error: errorAuth } = await supabaseAdmin.auth.admin.deleteUser(userId);
        if (errorAuth) {
            console.error("[eliminar-cuenta] Error eliminando auth.users:", errorAuth);
            return new Response(
                JSON.stringify({ error: "Error al eliminar la cuenta de autenticación." }),
                { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        console.log(`[eliminar-cuenta] ✅ Cuenta eliminada correctamente: ${userId}`);
        return new Response(
            JSON.stringify({
                success: true,
                mensaje: "Cuenta y datos clínicos eliminados permanentemente (ARCO/GDPR).",
                user_id: userId
            }),
            { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );

    } catch (err) {
        console.error("[eliminar-cuenta] Error inesperado:", err);
        return new Response(
            JSON.stringify({ error: "Error interno del servidor." }),
            { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    }
});
