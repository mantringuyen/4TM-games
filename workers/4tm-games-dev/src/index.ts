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

function supportsGzip(acceptEncoding: string | null): boolean {
  if (!acceptEncoding) return false;
  const tokens = acceptEncoding.split(',');
  let gzipQ = -1;
  let wildcardQ = -1;

  for (const token of tokens) {
    const [rawEncoding, ...rawParams] = token.trim().split(';');
    const encoding = rawEncoding.trim().toLowerCase();
    let q = 1.0;

    for (const param of rawParams) {
      const [k, v] = param.trim().split('=');
      if (k && k.trim().toLowerCase() === 'q') {
        const parsed = parseFloat(v);
        if (!isNaN(parsed)) {
          q = parsed;
        }
      }
    }

    if (encoding === 'gzip') {
      gzipQ = q;
    } else if (encoding === '*') {
      wildcardQ = q;
    }
  }

  if (gzipQ !== -1) {
    return gzipQ > 0;
  }
  if (wildcardQ !== -1) {
    return wildcardQ > 0;
  }
  return false;
}

function isSafariOrIOS(userAgent: string | null): boolean {
  if (!userAgent) return false;
  // Match iOS devices (iPhone, iPad, iPod)
  if (/iPhone|iPad|iPod/i.test(userAgent)) return true;
  // Match Safari (WebKit engine without Chromium or other forks)
  if (/Safari/i.test(userAgent) && !/Chrome|Chromium|CriOS|Edg|OPR/i.test(userAgent)) return true;
  return false;
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

      try {
        const gzResponse = await env.ASSETS.fetch(gzRequest);
        if (gzResponse.status === 200 && (request.method === 'HEAD' || gzResponse.body)) {
          const userAgent = request.headers.get('user-agent') || '';
          const clientAcceptsGzip = supportsGzip(request.headers.get('accept-encoding'));
          // Safari/iOS WebAssembly.instantiateStreaming requires uncompressed bytecode
          const shouldDecompress = !clientAcceptsGzip || isSafariOrIOS(userAgent);

          const headers = new Headers(gzResponse.headers);
          headers.set('Content-Type', 'application/wasm');
          headers.set('Cross-Origin-Opener-Policy', 'same-origin');
          headers.set('Cross-Origin-Embedder-Policy', 'require-corp');
          headers.set('Cross-Origin-Resource-Policy', 'cross-origin');
          headers.set('Access-Control-Allow-Origin', '*');
          headers.set('Cache-Control', 'public, max-age=300');
          headers.set('Vary', 'Accept-Encoding');

          if (!shouldDecompress) {
            // Stream pre-compressed .wasm.gz response directly for gzip-capable non-Safari clients
            headers.set('Content-Encoding', 'gzip');
            const cl = gzResponse.headers.get('content-length');
            if (cl) {
              headers.set('Content-Length', cl);
            }
            return new Response(request.method === 'HEAD' ? null : gzResponse.body, {
              status: 200,
              statusText: 'OK',
              headers,
            });
          } else {
            // Stream-decompress at Worker for Safari/iOS and clients that do not support gzip (e.g. gzip;q=0)
            headers.delete('Content-Encoding');
            headers.delete('Content-Length');
            const decompressedStream = gzResponse.body
              ? gzResponse.body.pipeThrough(new DecompressionStream('gzip'))
              : null;
            return new Response(request.method === 'HEAD' ? null : decompressedStream, {
              status: 200,
              statusText: 'OK',
              headers,
            });
          }
        }
      } catch (_) {}

      // Explicit WASM 404 error — MUST NEVER return HTML
      return new Response('404: WebAssembly module asset not found on 4tm-games-dev', {
        status: 404,
        headers: {
          'Content-Type': 'text/plain; charset=utf-8',
          'Cross-Origin-Opener-Policy': 'same-origin',
          'Cross-Origin-Embedder-Policy': 'require-corp',
          'Cross-Origin-Resource-Policy': 'cross-origin',
          'Access-Control-Allow-Origin': '*',
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
          'Cross-Origin-Resource-Policy': 'cross-origin',
          'Access-Control-Allow-Origin': '*',
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
          'Cross-Origin-Resource-Policy': 'cross-origin',
          'Access-Control-Allow-Origin': '*',
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
    headers.set('Cross-Origin-Resource-Policy', 'cross-origin');
    headers.set('Access-Control-Allow-Origin', '*');

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

