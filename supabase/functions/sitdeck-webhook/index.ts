/**
 * SitDeck alert webhook → public.agent_findings (source = 'sitdeck', agent_run_id = null).
 * Deploy: Supabase Dashboard (Edge Functions) or CLI. Disable JWT verification for this function.
 * Spec: docs/specs/implementation-guide-phase-3-dc.md Step 3.6b
 * DB: docs/database/migrations/add-agent-findings-sitdeck-webhook.sql
 */
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const secret = Deno.env.get("SITDECK_WEBHOOK_SECRET");
  const auth = req.headers.get("Authorization") ?? "";
  const bearer = auth.startsWith("Bearer ") ? auth.slice(7) : "";
  if (!secret || bearer !== secret) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const propertyId = body.property_id as string | undefined;
  if (!propertyId) {
    return new Response(JSON.stringify({ error: "property_id required" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );

  const { data: property, error: propErr } = await supabase
    .from("properties")
    .select("account_id")
    .eq("id", propertyId)
    .maybeSingle();

  if (propErr || !property) {
    return new Response(JSON.stringify({ error: "Property not found" }), {
      status: 404,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const findingType =
    (typeof body.finding_type === "string" && body.finding_type) ||
    (typeof body.type === "string" && body.type) ||
    "sitdeck_alert";

  const { error: insErr } = await supabase.from("agent_findings").insert({
    agent_run_id: null,
    account_id: property.account_id,
    property_id: propertyId,
    source: "sitdeck",
    finding_type: findingType,
    payload: body,
  });

  if (insErr) {
    console.error(insErr);
    return new Response(JSON.stringify({ error: "Insert failed" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
