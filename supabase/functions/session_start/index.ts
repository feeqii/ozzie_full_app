import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

type SessionStartRequest = {
  child_id: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-user-jwt, x-client-info, apikey, content-type",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL");
const serviceRoleKey =
  Deno.env.get("SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

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

const minutesAgo = (minutes: number) => new Date(Date.now() - minutes * 60_000);

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed" });
  }

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const bearerToken = authHeader.startsWith("Bearer ")
      ? authHeader.slice("Bearer ".length).trim()
      : "";
    const userJwtHeader = req.headers.get("x-user-jwt") ?? "";
    const userToken = userJwtHeader.startsWith("Bearer ")
      ? userJwtHeader.slice("Bearer ".length).trim()
      : userJwtHeader.trim();
    const token = userToken || (bearerToken && bearerToken !== supabaseAnonKey ? bearerToken : "");
    if (!token) {
      return jsonResponse(401, { error: "Missing user auth token" });
    }

    const { data: authData, error: authError } = await supabaseAdmin.auth.getUser(token);
    if (authError || !authData?.user) {
      return jsonResponse(401, { error: "Invalid auth token" });
    }

    const payload = (await req.json()) as Partial<SessionStartRequest>;
    const childId = payload.child_id;
    if (typeof childId !== "string" || childId.length === 0) {
      return jsonResponse(400, { error: "Missing child_id" });
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

    const reuseWindowMinutes = 30;
    const reuseThreshold = minutesAgo(reuseWindowMinutes).getTime();

    // Detect an existing open session.
    const { data: openSession, error: openError } = await supabaseAdmin
      .from("sessions")
      .select("id, started_at")
      .eq("child_id", childId)
      .is("ended_at", null)
      .order("started_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (openError) {
      return jsonResponse(500, { error: "Failed to load open session" });
    }

    if (openSession?.id && openSession.started_at) {
      const startedAt = new Date(openSession.started_at as string).getTime();
      if (Number.isFinite(startedAt) && startedAt >= reuseThreshold) {
        return jsonResponse(200, {
          session_id: openSession.id,
          started_at: openSession.started_at,
          reused: true,
        });
      }

      // Close stale open session without counting time (prevents inflated durations).
      await supabaseAdmin
        .from("sessions")
        .update({
          ended_at: openSession.started_at,
          counted: false,
        })
        .eq("id", openSession.id)
        .eq("child_id", childId);
    }

    const startedAt = nowIso();
    const { data: inserted, error: insertError } = await supabaseAdmin
      .from("sessions")
      .insert({
        child_id: childId,
        started_at: startedAt,
        counted: false,
      })
      .select("id, started_at")
      .single();

    if (insertError || !inserted) {
      return jsonResponse(500, { error: "Failed to start session" });
    }

    return jsonResponse(200, {
      session_id: inserted.id,
      started_at: inserted.started_at,
      reused: false,
    });
  } catch (error) {
    return jsonResponse(500, { error: error instanceof Error ? error.message : "Unexpected error" });
  }
});
