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

function matchesEtag(clientEtag: string | null, serverEtag: string | null): boolean {
  if (!clientEtag || !serverEtag) return false;
  const clean = (e: string) => e.trim().replace(/^W\//, '').replace(/^"|"$/g, '');
  const cleanServer = clean(serverEtag);
  if (clientEtag.trim() === '*') return true;
  return clientEtag.split(',').some((tag) => clean(tag) === cleanServer);
}

function isStaticAssetRequest(pathname: string): boolean {
  const cleanPath = pathname.split('?')[0].split('#')[0].toLowerCase();
  const staticExtensions = [
    '.wasm', '.wasm.gz', '.pck', '.js', '.json',
    '.png', '.svg', '.ico', '.css', '.map',
    '.jpg', '.jpeg', '.webp', '.icon.png'
  ];
  return staticExtensions.some((ext) => cleanPath.endsWith(ext)) || cleanPath.includes('.');
}

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

    // 2. Fetch requested asset from Cloudflare Workers Static Assets
    let response = await env.ASSETS.fetch(request);

    // Support pre-compressed WebAssembly (.wasm.gz)
    // Pre-compressed to comply with Cloudflare's 25 MiB static asset limit.
    const cleanPathname = url.pathname.split('?')[0];
    if ((response.status === 404 || response.status === 405) && cleanPathname.endsWith('.wasm')) {
      const gzUrl = new URL(request.url);
      gzUrl.pathname = `${cleanPathname}.gz`;

      // Fetch pre-compressed .wasm.gz from Static Assets with Accept-Encoding: identity to avoid double-compression
      const gzRequest = new Request(gzUrl.toString(), {
        method: request.method,
        headers: new Headers(request.headers),
      });
      gzRequest.headers.set('Accept-Encoding', 'identity');

      const gzResponse = await env.ASSETS.fetch(gzRequest);
      if (gzResponse.status === 200 && gzResponse.body) {
        // Always decompress at the Worker before returning the response
        const decompressedStream = gzResponse.body.pipeThrough(new DecompressionStream('gzip'));
        const headers = new Headers(gzResponse.headers);
        headers.set('Content-Type', 'application/wasm');
        headers.delete('Content-Encoding');
        headers.delete('Content-Length'); // Omit Content-Length so browser streams uncompressed bytes via chunked transfer
        headers.set('Cross-Origin-Opener-Policy', 'same-origin');
        headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
        headers.set('Cache-Control', 'public, max-age=300');
        return new Response(decompressedStream, {
          status: 200,
          statusText: 'OK',
          headers,
        });
      }

      // Explicit WASM 404 error — MUST NEVER return HTML
      return new Response('404: WebAssembly module asset not found on 4tm-games-dev', {
        status: 404,
        headers: {
          'Content-Type': 'text/plain; charset=utf-8',
          'Cross-Origin-Opener-Policy': 'same-origin',
          'Cross-Origin-Embedder-Policy': 'require-corp',
        },
      });
    }

    if ((response.status === 404 || response.status === 405) && cleanPathname.endsWith('.wasm.gz')) {
      return new Response('404: WebAssembly compressed asset not found on 4tm-games-dev', {
        status: 404,
        headers: {
          'Content-Type': 'text/plain; charset=utf-8',
          'Cross-Origin-Opener-Policy': 'same-origin',
          'Cross-Origin-Embedder-Policy': 'require-corp',
        },
      });
    }

    // Support streaming Godot package (.pck) assets stored in R2
    if (response.status === 404 && cleanPathname.endsWith('.pck')) {
      const pckPath = cleanPathname.replace(/^\/+/, '');
      const clientIfNoneMatch = request.headers.get('if-none-match');
      const clientIfModifiedSince = request.headers.get('if-modified-since');

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
            const etag = r2Object.httpEtag ? (r2Object.httpEtag.startsWith('"') ? r2Object.httpEtag : `"${r2Object.httpEtag}"`) : null;
            if (etag) {
              headers.set('ETag', etag);
            }
            headers.set('Cross-Origin-Opener-Policy', 'same-origin');
            headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
            headers.set('Cache-Control', 'no-cache, must-revalidate');

            if (clientIfNoneMatch && etag && matchesEtag(clientIfNoneMatch, etag)) {
              return new Response(null, {
                status: 304,
                statusText: 'Not Modified',
                headers,
              });
            }

            headers.set('Content-Length', r2Object.size.toString());
            return new Response(r2Object.body, {
              status: 200,
              statusText: 'OK',
              headers,
            });
          }
        }
      }

      // 2. Fallback: proxy from deployed R2 custom domain (Dev: games-dev-data.4tm.io.vn)
      try {
        const assetBase = (env.ASSET_BASE_URL || 'https://games-dev-data.4tm.io.vn').replace(/\/+$/, '');
        const candidateUrls = [
          `${assetBase}/${pckPath}`,
          pckPath.startsWith('games/') ? `${assetBase}/${pckPath.replace(/^games\//, '')}` : `${assetBase}/games/${pckPath}`,
        ];
        const proxyHeaders = new Headers();
        if (clientIfNoneMatch) proxyHeaders.set('If-None-Match', clientIfNoneMatch);
        if (clientIfModifiedSince) proxyHeaders.set('If-Modified-Since', clientIfModifiedSince);

        for (const r2Url of candidateUrls) {
          const r2Res = await fetch(r2Url, { headers: proxyHeaders });
          if (r2Res.status === 304) {
            const headers = new Headers(r2Res.headers);
            headers.set('Content-Type', 'application/octet-stream');
            headers.set('Cross-Origin-Opener-Policy', 'same-origin');
            headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
            headers.set('Cache-Control', 'no-cache, must-revalidate');
            return new Response(null, {
              status: 304,
              statusText: 'Not Modified',
              headers,
            });
          }
          if (r2Res.ok && r2Res.body) {
            const headers = new Headers(r2Res.headers);
            headers.set('Content-Type', 'application/octet-stream');
            headers.set('Cross-Origin-Opener-Policy', 'same-origin');
            headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
            headers.set('Cache-Control', 'no-cache, must-revalidate');

            const etag = headers.get('etag');
            if (clientIfNoneMatch && etag && matchesEtag(clientIfNoneMatch, etag)) {
              return new Response(null, {
                status: 304,
                statusText: 'Not Modified',
                headers,
              });
            }

            const cl = r2Res.headers.get('Content-Length');
            if (cl) {
              headers.set('Content-Length', cl);
            }
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
    // CRITICAL: Exclude static file extensions (.pck, .wasm, .js, etc.) so asset misses NEVER serve HTML!
    if (response.status === 404 && !isStaticAssetRequest(url.pathname)) {
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

    // 4. Return custom text 404 if static asset or file is missing
    if (response.status === 404) {
      return new Response(`404: Asset ${url.pathname} not found on 4tm-games-dev`, {
        status: 404,
        headers: {
          'Content-Type': 'text/plain; charset=utf-8',
          'Cross-Origin-Opener-Policy': 'same-origin',
          'Cross-Origin-Embedder-Policy': 'require-corp',
        },
      });
    }

    // 5. Ensure proper MIME types and security/isolation headers
    const headers = new Headers(response.headers);

    for (const [ext, mime] of Object.entries(MIME_MAP)) {
      if (cleanPathname.endsWith(ext)) {
        headers.set('Content-Type', mime);
        break;
      }
    }

    headers.set('Cross-Origin-Opener-Policy', 'same-origin');
    headers.set('Cross-Origin-Embedder-Policy', 'require-corp');

    if (cleanPathname.endsWith('.html') || cleanPathname.endsWith('/') || cleanPathname.endsWith('.js')) {
      headers.set('Cache-Control', 'no-cache, no-store, must-revalidate');
      headers.set('Pragma', 'no-cache');
      headers.set('Expires', '0');
    } else if (cleanPathname.endsWith('.pck')) {
      headers.set('Cache-Control', 'no-cache, must-revalidate');
    } else if (cleanPathname.endsWith('.wasm')) {
      headers.set('Cache-Control', 'public, max-age=300');
    }

    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers,
    });
  },
};

