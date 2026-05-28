import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const { title, body } = await req.json();

    if (typeof title !== "string" || typeof body !== "string") {
      return new Response(JSON.stringify({ error: "Invalid request body" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const onesignalAppId = Deno.env.get("ONESIGNAL_APP_ID") ?? "";
    const onesignalRestApiKey = Deno.env.get("ONESIGNAL_REST_API_KEY") ?? "";

    if (!onesignalAppId || !onesignalRestApiKey) {
      return new Response(
        JSON.stringify({
          error: "Missing OneSignal configuration",
          details: "Set ONESIGNAL_APP_ID and ONESIGNAL_REST_API_KEY in the function environment.",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const notificationResponse = await fetch(
      "https://onesignal.com/api/v1/notifications",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Basic ${onesignalRestApiKey}`,
        },
        body: JSON.stringify({
          app_id: onesignalAppId,
          included_segments: ["Subscribed Users"],
          headings: { en: title, he: title },
          contents: { en: body, he: body },
        }),
      },
    );

    const responseText = await notificationResponse.text();

    if (!notificationResponse.ok) {
      return new Response(
        JSON.stringify({
          error: "Failed to send notification",
          status: notificationResponse.status,
          details: responseText,
        }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        details: responseText,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: "Unhandled error",
        details: String(error),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});