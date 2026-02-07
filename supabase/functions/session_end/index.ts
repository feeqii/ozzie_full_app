import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

type SessionEndRequest = {
  child_id: string;
  session_id: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey =
  Deno.env.get("SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error("Missing SUPABASE_URL or service role key");
}

const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

const jsonResponse = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders,
    },
  });

const nowIso = () => new Date().toISOString();

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace("Bearer ", "");
    if (!token) {
      return jsonResponse(401, { error: "Missing bearer token" });
    }

    const { data: authData, error: authError } = await supabaseAdmin.auth.getUser(token);
    if (authError || !authData?.user) {
      return jsonResponse(401, { error: "Invalid auth token" });
    }

    const payload = (await req.json()) as Partial<SessionEndRequest>;
    const childId = payload.child_id;
    const sessionId = payload.session_id;
    if (typeof childId !== "string" || typeof sessionId !== "string" || !childId || !sessionId) {
      return jsonResponse(400, { error: "Missing required fields" });
    }

    const { data: childRow, error: childError } = await supabaseAdmin
      .from("children")
      .select("id, parent_id")
      .eq("id", childId)
      .maybeSingle();

    if (childError || !childRow) {
      return jsonResponse(404, { error: "Child not found" });
    }

    if (childRow.parent_id !== authData.user.id) {
      return jsonResponse(403, { error: "Forbidden" });
    }

    const { data: sessionRow, error: sessionError } = await supabaseAdmin
      .from("sessions")
      .select("id, started_at, ended_at, counted")
      .eq("id", sessionId)
      .eq("child_id", childId)
      .maybeSingle();

    if (sessionError) {
      return jsonResponse(500, { error: "Failed to load session" });
    }

    if (!sessionRow) {
      return jsonResponse(404, { error: "Session not found" });
    }

    const updatePayload: Record<string, unknown> = {
      counted: true,
    };

    let endedAt = sessionRow.ended_at as string | null;
    if (!endedAt) {
      endedAt = nowIso();
      updatePayload.ended_at = endedAt;
    }

    const { error: updateError } = await supabaseAdmin
      .from("sessions")
      .update(updatePayload)
      .eq("id", sessionId)
      .eq("child_id", childId);

    if (updateError) {
      return jsonResponse(500, { error: "Failed to end session" });
    }

    return jsonResponse(200, {
      session_id: sessionId,
      ended_at: endedAt,
      counted: true,
    });
  } catch (error) {
    return jsonResponse(500, { error: error instanceof Error ? error.message : "Unexpected error" });
  }
});

