// Minimal shims for TypeScript tooling outside of the Deno runtime.
// This file is only for editor type-checking and is ignored by Supabase Edge runtime.

declare module "jsr:@supabase/supabase-js@2" {
  export const createClient: (...args: unknown[]) => any;
}

declare const Deno: {
  env: {
    get(key: string): string | undefined;
  };
  serve: (handler: (req: Request) => Promise<Response> | Response) => void;
};
