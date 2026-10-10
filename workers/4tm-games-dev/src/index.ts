/**
 * 4tm-games-dev Cloudflare Worker
 *
 * Dedicated development & testing static host for 4TM-games.
 * Serves Godot Web (HTML5/WASM/PCK) game builds under multi-game paths (e.g. /block-puzzle/, /game-2/).
 *
 * Features:
 * - Direct static asset streaming via Cloudflare Workers Static Assets (env.ASSETS)
 * - Trailing slash normalization for game base paths (/block-puzzle -> /block-puzzle/)
 * - Enforced accurate MIME types for WebAssembly (.wasm) and Godot packages (.pck)
 * - Cross-Origin Isolation headers for WebAssembly and Audio Worklet performance
 * - Sub-path fallback for client-side navigation and browser page refresh
 */

interface Env {
  ASSETS: Fetcher;
  BUCKET?: R2Bucket;
  ASSET_BASE_URL?: string;
}

const MIME_MAP: Record<string, string> = {
  '.wasm': 'application/wasm',
  '.pck': 'application/octet-stream',
  '.js': 'application/javascript; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.json': 'application/json',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.css': 'text/css; charset=utf-8',
  '.map': 'application/json',
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    // 1. Normalize game base URLs: redirect /<game> -> /<game>/ (301)
    // Ensures relative assets in index.html (like "index.js", "index.wasm")
    // resolve properly to "/<game>/index.js" instead of root "/index.js".
    if (!url.pathname.endsWith('/') && !url.pathname.includes('.')) {
      url.pathname = `${url.pathname}/`;
      return Response.redirect(url.toString(), 301);
    }

    // 2. Fetch the requested asset from Cloudflare Workers Static Assets
    let response = await env.ASSETS.fetch(request);

    // Support pre-compressed WebAssembly (.wasm.gz) to stay well under Cloudflare's 25 MiB asset limit.
    // Decompress the stream at the edge so the client receives native uncompressed WASM bytecode with full length tracking.
    if (response.status === 404 && url.pathname.endsWith('.wasm')) {
      const gzUrl = new URL(request.url);
      gzUrl.pathname = `${gzUrl.pathname}.gz`;
      const gzResponse = await env.ASSETS.fetch(new Request(gzUrl.toString(), request));
      if (gzResponse.status === 200 && gzResponse.body) {
        const decompressedStream = gzResponse.body.pipeThrough(new DecompressionStream('gzip'));
        const headers = new Headers(gzResponse.headers);
        headers.set('Content-Type', 'application/wasm');
        headers.set('Content-Length', '35376909');
        headers.delete('Content-Encoding');
        headers.set('Cross-Origin-Opener-Policy', 'same-origin');
        headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
        headers.set('Cache-Control', 'public, max-age=300');
        return new Response(decompressedStream, {
          status: 200,
          statusText: 'OK',
          headers,
        });
      }
    }

    // Support streaming Godot package (.pck) assets stored in R2
    // Ensures .pck requests never fall back to index.html and have exact content-type & isolation headers.
    if (response.status === 404 && url.pathname.endsWith('.pck')) {
      const pckPath = url.pathname.replace(/^\/+/, '');
      // 1. Check R2 bucket binding first (env.BUCKET)
      if (env.BUCKET) {
        const candidateKeys = [
          pckPath,
          pckPath.startsWith('games/') ? pckPath.replace(/^games\//, '') : `games/${pckPath}`,
        ];
        for (const key of candidateKeys) {
          const r2Object = await env.BUCKET.get(key);
          if (r2Object) {
            const headers = new Headers();
            r2Object.writeHttpMetadata(headers);
            headers.set('Content-Type', 'application/octet-stream');
            headers.set('Content-Length', r2Object.size.toString());
            if (r2Object.httpEtag) {
              headers.set('ETag', r2Object.httpEtag);
            }
            headers.set('Cross-Origin-Opener-Policy', 'same-origin');
            headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
            headers.set('Cache-Control', 'public, max-age=300');
            return new Response(r2Object.body, {
              status: 200,
              statusText: 'OK',
              headers,
            });
          }
        }
      }

      // 2. Fallback: proxy from the deployed R2 custom domain (Dev: games-dev-data.4tm.io.vn)
      try {
        const assetBase = (env.ASSET_BASE_URL || 'https://games-dev-data.4tm.io.vn').replace(/\/+$/, '');
        const candidateUrls = [
          `${assetBase}/${pckPath}`,
          pckPath.startsWith('games/') ? `${assetBase}/${pckPath.replace(/^games\//, '')}` : `${assetBase}/games/${pckPath}`,
        ];
        for (const r2Url of candidateUrls) {
          const r2Res = await fetch(r2Url);
          if (r2Res.ok && r2Res.body) {
            const headers = new Headers(r2Res.headers);
            headers.set('Content-Type', 'application/octet-stream');
            headers.set('Cross-Origin-Opener-Policy', 'same-origin');
            headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
            headers.set('Cache-Control', 'public, max-age=300');
            return new Response(r2Res.body, {
              status: 200,
              statusText: 'OK',
              headers,
            });
          }
        }
      } catch (_) {}
    }

    // 3. Fallback for browser refresh / client-side sub-routes:
    // If a request under /<game>/subpath 404s, attempt serving /<game>/index.html
    // CRITICAL: Exclude static file extensions (.pck, .wasm, .js, etc.) so asset misses NEVER serve HTML!
    if (response.status === 404 && !url.pathname.includes('.')) {
      const match = url.pathname.match(/^(\/[a-zA-Z0-9_-]+)\/.+/);
      if (match) {
        const gameRoot = match[1];
        const fallbackUrl = new URL(request.url);
        fallbackUrl.pathname = `${gameRoot}/index.html`;
        const fallbackResponse = await env.ASSETS.fetch(new Request(fallbackUrl.toString(), request));
        if (fallbackResponse.status === 200) {
          response = fallbackResponse;
        }
      }
    }

    // 4. Return custom 404 if asset is still missing
    if (response.status === 404) {
      return new Response('404: Game asset not found on 4tm-games-dev', {
        status: 404,
        headers: {
          'Content-Type': 'text/plain; charset=utf-8',
        },
      });
    }

    // 5. Ensure proper MIME types and security/isolation headers
    const headers = new Headers(response.headers);

    // Enforce correct Content-Type for Godot Web assets
    for (const [ext, mime] of Object.entries(MIME_MAP)) {
      if (url.pathname.endsWith(ext)) {
        headers.set('Content-Type', mime);
        break;
      }
    }

    // Standard cross-origin headers for WebAssembly & audio worklets
    headers.set('Cross-Origin-Opener-Policy', 'same-origin');
    headers.set('Cross-Origin-Embedder-Policy', 'require-corp');

    // Caching policy:
    if (url.pathname.endsWith('.html') || url.pathname.endsWith('/') || url.pathname.endsWith('.js')) {
      // Entry points and scripts: prevent stale caching during rapid dev iteration
      headers.set('Cache-Control', 'no-cache, no-store, must-revalidate');
      headers.set('Pragma', 'no-cache');
      headers.set('Expires', '0');
    } else if (url.pathname.endsWith('.wasm') || url.pathname.endsWith('.pck')) {
      // Large binary assets: 5-minute cache for fast dev iteration
      headers.set('Cache-Control', 'public, max-age=300');
    }

    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers,
    });
  },
};
