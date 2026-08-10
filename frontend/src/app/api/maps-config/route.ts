/*
 * Browser map configuration endpoint. Keep the key server-side in .env.local;
 * the browser receives it only when it loads the Google Maps client.
 */
export const dynamic = "force-dynamic";

export async function GET() {
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;
  if (!apiKey) {
    return Response.json(
      { configured: false },
      { status: 503, headers: { "Cache-Control": "no-store" } },
    );
  }

  return Response.json(
    { configured: true, apiKey },
    { headers: { "Cache-Control": "private, no-store" } },
  );
}
