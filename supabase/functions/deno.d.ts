/**
 * Ambient type declarations for Deno global namespace & URL imports in Supabase Edge Functions.
 * This resolves "Cannot find name 'Deno'" and "Cannot find module 'https://...'" errors in TypeScript editor tooling.
 */
declare namespace Deno {
  export function serve(
    handler: (req: Request) => Promise<Response> | Response
  ): void;
  export function serve(
    options: { port?: number; hostname?: string; [key: string]: unknown },
    handler: (req: Request) => Promise<Response> | Response
  ): void;

  export const env: {
    get(key: string): string | undefined;
    set(key: string, value: string): void;
    delete(key: string): void;
    toObject(): Record<string, string>;
  };
}

// Ambient module declarations for URL imports used in Deno Edge Functions (e.g. esm.sh, deno.land)
declare module "https://*" {
  export const createClient: any;
  export type SupabaseClient<T = any, S extends string = string> = any;
  export const serve: any;
  export const CorsHeaders: any;
  export const corsHeaders: any;
  const content: any;
  export default content;
}

declare module "http://*" {
  const content: any;
  export default content;
}

