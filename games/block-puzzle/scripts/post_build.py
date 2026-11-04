#!/usr/bin/env python3
import os
import sys
import re
import shutil
import json

def main():
    target_dir = "workers/4tm-games-dev/public/block-puzzle"
    if len(sys.argv) > 1:
        target_dir = sys.argv[1]
    
    print(f"Running post-build processing on target directory: {target_dir}")

    # Determine paths for assets/branding, root public dir, and target block-puzzle dir
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir) # games/block-puzzle
    repo_root = os.path.dirname(os.path.dirname(project_dir)) # repo root
    
    branding_dir = os.path.join(project_dir, "assets/branding")
    if not os.path.exists(branding_dir):
        branding_dir = os.path.join(repo_root, "games/block-puzzle/assets/branding")

    dev_root_public = os.path.join(repo_root, "workers/4tm-games-dev/public")

    # 1. Copy root-level branding assets to workers/4tm-games-dev/public
    root_brand_files = [
        "games-logo-light.svg", "games_logo_light.svg",
        "games-logo-dark.svg", "games_logo_dark.svg", "games-logo.svg",
        "games-logo-light.png", "games_logo_light.png",
        "games-logo-dark.png", "games_logo_dark.png", "games-logo-1024.png",
        "games-favicon.svg", "favicon.svg",
        "games-favicon-32.png", "favicon.png",
        "apple-touch-icon.png",
        "block-puzzle-logo-light.svg", "block_puzzle_logo_light.svg",
        "block-puzzle-logo-dark.svg", "block_puzzle_logo_dark.svg", "block-puzzle-logo.svg",
        "block-puzzle-logo-light.png", "block_puzzle_logo_light.png",
        "block-puzzle-logo-dark.png", "block_puzzle_logo_dark.png", "block-puzzle-logo.png", "block-puzzle-logo-1024.png",
        "block-puzzle-favicon.svg", "block-puzzle-favicon-32.png"
    ]

    if os.path.exists(dev_root_public) and os.path.exists(branding_dir):
        root_copied = 0
        for fname in root_brand_files:
            src = os.path.join(branding_dir, fname)
            if os.path.exists(src):
                shutil.copy2(src, os.path.join(dev_root_public, fname))
                root_copied += 1
        print(f"Synchronized {root_copied} root branding assets to {dev_root_public}")

    # 2. Copy game-specific branding assets to target_dir (workers/4tm-games-dev/public/block-puzzle)
    game_brand_files = [
        "games_logo.png", "games-logo.png", "games-logo-1024.png", "games-logo-dark.png", "games_logo_dark.png",
        "games-logo-light.png", "games_logo_light.png", "index.png",
        "games_logo.svg", "games-logo.svg", "games-logo-dark.svg", "games_logo_dark.svg",
        "games-logo-light.svg", "games_logo_light.svg",
        "games_favicon.svg", "games-favicon.svg", "games_favicon.png", "games-favicon.png",
        "games_favicon-32.png", "games-favicon-32.png",
        "block-puzzle-logo.svg", "block_puzzle_logo.svg", "block-puzzle-logo-dark.svg", "block_puzzle_logo_dark.svg",
        "block-puzzle-logo-light.svg", "block_puzzle_logo_light.svg",
        "block-puzzle-logo.png", "block_puzzle_logo.png", "block-puzzle-logo-1024.png", "block-puzzle-logo-dark.png", "block_puzzle_logo_dark.png",
        "block-puzzle-logo-light.png", "block_puzzle_logo_light.png",
        "block-puzzle-favicon.svg", "block_puzzle_favicon.svg",
        "block-puzzle-favicon.png", "block_puzzle_favicon.png", "pwa-512.png", "pwa-192.png",
        "pwa-maskable-512.png", "pwa-maskable-192.png",
        "block-puzzle-favicon-32.png", "block_puzzle_favicon-32.png",
        "index.apple-touch-icon.png", "apple-touch-icon.png", "index.icon.png"
    ]

    os.makedirs(target_dir, exist_ok=True)
    if os.path.exists(branding_dir):
        game_copied = 0
        for fname in game_brand_files:
            src = os.path.join(branding_dir, fname)
            if os.path.exists(src):
                shutil.copy2(src, os.path.join(target_dir, fname))
                game_copied += 1
        print(f"Synchronized {game_copied} branding files to {target_dir}")

    html_path = os.path.join(target_dir, "index.html")
    pck_path = os.path.join(target_dir, "index.pck")

    # 3. Ensure clean and correct Godot engine package configuration & idempotent head links
    if os.path.exists(html_path):
        with open(html_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Ensure canonical package configuration: strip any legacy or cross-origin mainPack URL
        content = re.sub(r'"mainPack":"[^"]*",?', "", content)

        # Synchronize exact fileSizes tracking from local build artifacts
        actual_pck_size = None
        for p in [pck_path, "build/web/index.pck", "../../build/web/index.pck", "games/block-puzzle/index.pck", "../games/block-puzzle/index.pck"]:
            if os.path.exists(p):
                actual_pck_size = os.path.getsize(p)
                break

        actual_wasm_size = None
        wasm_path = os.path.join(target_dir, "index.wasm")
        for p in [wasm_path, "build/web/index.wasm", "../../build/web/index.wasm", "games/block-puzzle/index.wasm", "../games/block-puzzle/index.wasm"]:
            if os.path.exists(p):
                actual_wasm_size = os.path.getsize(p)
                break

        if actual_pck_size:
            content = re.sub(r'"index\.pck":\s*\d+', f'"index.pck":{actual_pck_size}', content)

        if actual_wasm_size:
            content = re.sub(r'"index\.wasm":\s*\d+', f'"index.wasm":{actual_wasm_size}', content)

        # Remove ALL existing managed meta tags and ALL existing favicon / icon / manifest links
        # This guarantees 100% IDEMPOTENCY when running post_build repeatedly
        content = re.sub(r'<meta\s+name=["\'](?:theme-color|description|apple-mobile-web-app-[^"\']+|mobile-web-app-capable)["\'][^>]*>\s*', "", content)
        content = re.sub(r'<link\s+[^>]*rel=["\'](?:icon|shortcut icon|apple-touch-icon|manifest)["\'][^>]*>\s*', "", content)
        content = re.sub(r'<link\s+[^>]*href=["\'][^"\']*(?:favicon|icon|manifest)[^"\']*["\'][^>]*>\s*', "", content)

        status_bar_style = "black-translucent"
        meta_tags = (
            '\n\t\t<meta name="description" content="Official 4TM 2D block puzzle game (Xếp Gạch — 4TM) supporting Classic and Modern Drag-and-Drop modes.">'
            '\n\t\t<meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, viewport-fit=cover">'
            '\n\t\t<meta name="theme-color" content="#414141">'
            '\n\t\t<meta name="apple-mobile-web-app-capable" content="yes">'
            f'\n\t\t<meta name="apple-mobile-web-app-status-bar-style" content="{status_bar_style}">'
            '\n\t\t<meta name="apple-mobile-web-app-title" content="Block Puzzle — 4TM">'
            '\n\t\t<meta name="mobile-web-app-capable" content="yes">'
            '\n\t\t<link rel="icon" type="image/svg+xml" href="block-puzzle-favicon.svg">'
            '\n\t\t<link rel="icon" type="image/png" sizes="32x32" href="block-puzzle-favicon-32.png">'
            '\n\t\t<link rel="apple-touch-icon" href="index.apple-touch-icon.png">'
            '\n\t\t<link rel="manifest" href="manifest.json">'
        )

        if "<head>" in content:
            if '<meta name="viewport"' in content:
                content = re.sub(r'<meta\s+name=["\']viewport["\'][^>]*>', meta_tags, content, count=1)
            else:
                content = content.replace("<head>", f"<head>{meta_tags}")

        # 4. Ensure edge-to-edge full viewport CSS styling without artificial gaps or color mismatches
        css_replacement = (
            "<style>\n"
            "html, body, #canvas {\n\tmargin: 0;\n\tpadding: 0;\n\tborder: 0;\n}\n\n"
            "html, body {\n\twidth: 100%;\n\theight: 100%;\n\theight: 100dvh;\n\tmin-height: 100vh;\n\tmin-height: 100dvh;\n\tmin-height: -webkit-fill-available;\n\tcolor: white;\n\tbackground-color: #050B1A;\n\toverflow: hidden;\n\toverscroll-behavior: none;\n\ttouch-action: none;\n\t-webkit-touch-callout: none;\n\t-webkit-user-select: none;\n\tuser-select: none;\n}\n\n"
            "#canvas {\n\tdisplay: block;\n\tposition: fixed;\n\ttop: 0;\n\tleft: 0;\n\tright: 0;\n\tbottom: 0;\n\twidth: 100%;\n\twidth: 100vw;\n\twidth: 100dvw;\n\theight: 100%;\n\theight: 100vh;\n\theight: 100dvh;\n\tbackground-color: #050B1A;\n}\n\n"
            "#canvas:focus {\n\toutline: none;\n}\n\n"
            "#status {\n\tposition: fixed;\n\ttop: 0;\n\tleft: 0;\n\tright: 0;\n\tbottom: 0;\n\twidth: 100%;\n\theight: 100%;\n\theight: 100dvh;\n\tbackground-color: #050B1A;\n\tdisplay: flex;\n\tflex-direction: column;\n\tjustify-content: center;\n\talign-items: center;\n\tvisibility: hidden;\n\tz-index: 10;\n}\n\n"
            "#status-container {\n\tposition: relative;\n\tdisplay: flex;\n\tjustify-content: center;\n\talign-items: center;\n\twidth: 150px;\n\theight: 150px;\n}\n\n"
            "#status-logo {\n\twidth: 100px;\n\theight: 100px;\n\tobject-fit: contain;\n\tz-index: 2;\n}\n\n"
            "#status-ring {\n\tposition: absolute;\n\twidth: 150px;\n\theight: 150px;\n\tborder-radius: 50%;\n\tbackground: conic-gradient(\n\t\t#ff0000 0%, #ff7f00 14%, #ffff00 28%, #00ff00 42%, \n\t\t#0000ff 56%, #4b0082 70%, #9400d3 84%, #ff0000 100%\n\t);\n\t-webkit-mask: radial-gradient(transparent 75%, #000 76%);\n\tmask: radial-gradient(transparent 75%, #000 76%);\n\tanimation: rotate 2s linear infinite;\n\tz-index: 1;\n}\n\n"
            "@keyframes rotate {\n\tfrom { transform: rotate(0deg); }\n\tto { transform: rotate(360deg); }\n}\n\n"
            "#status-progress, #status-notice {\n\tdisplay: none;\n}\n\n"
            "#status-progress {\n\tposition: absolute;\n\tleft: 0;\n\tright: 0;\n\tbottom: calc(10% + env(safe-area-inset-bottom, 0px));\n\twidth: 50%;\n\tmargin: 0 auto;\n}\n\n"
            "#status-notice {\n\tbackground-color: #5b3943;\n\tborder-radius: 0.5rem;\n\tborder: 1px solid #9b3943;\n\tcolor: #e0e0e0;\n\tfont-family: 'Noto Sans', 'Droid Sans', Arial, sans-serif;\n\tline-height: 1.3;\n\tmargin: 0 2rem;\n\toverflow: hidden;\n\tpadding: 1rem;\n\ttext-align: center;\n\tz-index: 11;\n}\n\n"
            "#status-splash {\n\tdisplay: none;\n}\n\t\t</style>"
        )

        if "<style>" in content:
            content = re.sub(r'<style>.*?</style>', css_replacement, content, flags=re.DOTALL)

        # 5. Inject standards-safe iOS viewport height sync script and diagnostic HUD before index.js
        pwa_script = (
            "\t\t<script>\n"
            "\t\t// Standards-safe iOS viewport height normalization and settled resize trigger\n"
            "\t\t(function () {\n"
            "\t\t\tvar probe = document.createElement('div');\n"
            "\t\t\tprobe.id = 'gd-vh-probe';\n"
            "\t\t\tprobe.style.cssText = 'position:fixed;top:0;bottom:0;left:0;right:0;pointer-events:none;visibility:hidden;z-index:-9999;';\n"
            "\t\t\tvar ins = document.createElement('div');\n"
            "\t\t\tins.id = 'gd-ins-probe';\n"
            "\t\t\tins.style.cssText = 'position:fixed;bottom:0;left:0;padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px);pointer-events:none;visibility:hidden;z-index:-9999;';\n"
            "\t\t\tfunction getEffectiveHeight() {\n"
            "\t\t\t\tvar isStandalone = !!(window.navigator && window.navigator.standalone) || (window.matchMedia && window.matchMedia('(display-mode: standalone)').matches);\n"
            "\t\t\t\tvar isIOS = /iPhone|iPad|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);\n"
            "\t\t\t\tif (isStandalone && isIOS && window.screen) {\n"
            "\t\t\t\t\tvar isLandscape = (window.orientation === 90 || window.orientation === -90);\n"
            "\t\t\t\t\treturn isLandscape ? Math.min(window.screen.width, window.screen.height) : Math.max(window.screen.width, window.screen.height);\n"
            "\t\t\t\t}\n"
            "\t\t\t\tvar probeH = probe.offsetHeight || (probe.getBoundingClientRect ? probe.getBoundingClientRect().height : 0);\n"
            "\t\t\t\tvar winH = window.innerHeight || 0;\n"
            "\t\t\t\tvar docH = document.documentElement ? document.documentElement.clientHeight || 0 : 0;\n"
            "\t\t\t\tvar vvH = (window.visualViewport && window.visualViewport.height) ? window.visualViewport.height : 0;\n"
            "\t\t\t\treturn Math.max(probeH, winH, docH, vvH);\n"
            "\t\t\t}\n"
            "\t\t\tfunction syncViewport() {\n"
            "\t\t\t\tvar h = getEffectiveHeight();\n"
            "\t\t\t\tif (h > 0) {\n"
            "\t\t\t\t\tdocument.documentElement.style.height = h + 'px';\n"
            "\t\t\t\t\tdocument.body.style.height = h + 'px';\n"
            "\t\t\t\t\tvar cv = document.getElementById('canvas');\n"
            "\t\t\t\t\tif (cv) cv.style.height = h + 'px';\n"
            "\t\t\t\t}\n"
            "\t\t\t}\n"
            "\t\t\tfunction triggerSettledResize() {\n"
            "\t\t\t\tsyncViewport();\n"
            "\t\t\t\t[50, 150, 300, 500, 1000].forEach(function (delay) {\n"
            "\t\t\t\t\tsetTimeout(function () {\n"
            "\t\t\t\t\t\tsyncViewport();\n"
            "\t\t\t\t\t\twindow.dispatchEvent(new Event('resize'));\n"
            "\t\t\t\t\t}, delay);\n"
            "\t\t\t\t});\n"
            "\t\t\t}\n"
            "\t\t\tif (document.body) {\n"
            "\t\t\t\tdocument.body.appendChild(probe);\n"
            "\t\t\t\tdocument.body.appendChild(ins);\n"
            "\t\t\t} else {\n"
            "\t\t\t\tdocument.addEventListener('DOMContentLoaded', function () {\n"
            "\t\t\t\t\tdocument.body.appendChild(probe);\n"
            "\t\t\t\t\tdocument.body.appendChild(ins);\n"
            "\t\t\t\t\ttriggerSettledResize();\n"
            "\t\t\t\t});\n"
            "\t\t\t}\n"
            "\t\t\twindow.addEventListener('resize', syncViewport);\n"
            "\t\t\twindow.addEventListener('orientationchange', triggerSettledResize);\n"
            "\t\t\ttriggerSettledResize();\n"
            "\t\t\t// Diagnostics HUD for verification\n"
            "\t\t\tvar diagEvents = [];\n"
            "\t\t\twindow.__4TM_RECORD_ERROR__ = function (type, detail, extra) {\n"
            "\t\t\t\tdiagEvents.push({ time: Date.now(), type: 'error:' + type, detail: detail, extra: extra });\n"
            "\t\t\t\tif (window.__4TM_UPDATE_DIAG_UI__) window.__4TM_UPDATE_DIAG_UI__();\n"
            "\t\t\t};\n"
            "\t\t\twindow.__4TM_RECORD_MILESTONE__ = function (milestone, detail) {\n"
            "\t\t\t\tdiagEvents.push({ time: Date.now(), type: 'milestone:' + milestone, detail: detail });\n"
            "\t\t\t\tif (window.__4TM_UPDATE_DIAG_UI__) window.__4TM_UPDATE_DIAG_UI__();\n"
            "\t\t\t};\n"
            "\t\t\tfunction createDiagUI() {\n"
            "\t\t\t\tvar isDev = location.hostname.indexOf('dev') !== -1 || location.search.indexOf('diag=1') !== -1;\n"
            "\t\t\t\tif (!isDev) return;\n"
            "\t\t\t\tvar ui = document.createElement('div');\n"
            "\t\t\t\tui.id = 'gd-diag-hud';\n"
            "\t\t\t\tui.style.cssText = 'position:fixed;bottom:env(safe-area-inset-bottom,0px);left:0;right:0;max-height:180px;background:rgba(9,9,11,0.85);backdrop-filter:blur(6px);color:#e4e4e7;font-family:monospace;font-size:11px;line-height:1.4;padding:6px 10px;z-index:99999;border-top:1px solid #27272a;display:none;';\n"
            "\t\t\t\tvar header = document.createElement('div');\n"
            "\t\t\t\theader.style.cssText = 'display:flex;justify-content:space-between;align-items:center;font-weight:bold;margin-bottom:4px;';\n"
            "\t\t\t\theader.innerHTML = '<span>[4TM-DIAG] Diagnostics HUD</span><span style=\"cursor:pointer;color:#a1a1aa;padding:0 4px;\" onclick=\"this.parentNode.parentNode.style.display=\\'none\\'\">&times;</span>';\n"
            "\t\t\t\tvar details = document.createElement('div');\n"
            "\t\t\t\tdetails.id = 'gd-diag-content';\n"
            "\t\t\t\tui.appendChild(header);\n"
            "\t\t\t\tui.appendChild(details);\n"
            "\t\t\t\tdocument.body.appendChild(ui);\n"
            "\t\t\t\twindow.__4TM_UPDATE_DIAG_UI__ = updateHUD;\n"
            "\t\t\t\tupdateHUD();\n"
            "\t\t\t\tfunction formatTime(ms) {\n"
            "\t\t\t\t\tvar d = new Date(ms);\n"
            "\t\t\t\t\treturn d.toTimeString().split(' ')[0] + '.' + ('00' + d.getMilliseconds()).slice(-3);\n"
            "\t\t\t\t}\n"
            "\t\t\t\tfunction formatDetailStr(detail) {\n"
            "\t\t\t\t\tif (!detail) return '';\n"
            "\t\t\t\t\tif (typeof detail === 'object') {\n"
            "\t\t\t\t\t\ttry { return ' ' + JSON.stringify(detail); } catch (e) { return ' ' + String(detail); }\n"
            "\t\t\t\t\t}\n"
            "\t\t\t\t\treturn ' ' + String(detail);\n"
            "\t\t\t\t}\n"
            "\t\t\t\tfunction updateHUD() {\n"
            "\t\t\t\t\tvar hasErrors = diagEvents.some(function (e) { return e.type.indexOf('error:') === 0; });\n"
            "\t\t\t\t\tif (hasErrors || location.search.indexOf('diag=1') !== -1) {\n"
            "\t\t\t\t\t\tui.style.display = 'block';\n"
            "\t\t\t\t\t}\n"
            "\t\t\t\t\tvar html = '<div>';\n"
            "\t\t\t\t\thtml += '<span style=\"color:#a1a1aa;\">Viewport:</span> ' + window.innerWidth + '&times;' + window.innerHeight + ' | ';\n"
            "\t\t\t\t\thtml += '<span style=\"color:#a1a1aa;\">Effective:</span> ' + getEffectiveHeight() + 'px | ';\n"
            "\t\t\t\t\thtml += '<span style=\"color:#a1a1aa;\">Standalone:</span> ' + (!!(window.navigator && window.navigator.standalone) || (window.matchMedia && window.matchMedia('(display-mode: standalone)').matches)) + '<br>';\n"
            "\t\t\t\t\thtml += '<details><summary style=\"color:#60a5fa;cursor:pointer;\">Live Events (' + diagEvents.length + ' events)</summary>';\n"
            "\t\t\t\t\thtml += '<div style=\"max-height:120px;overflow-y:auto;background:#09090b;padding:4px;border-radius:2px;margin-top:2px;font-size:10px;\">';\n"
            "\t\t\t\t\tif (diagEvents.length === 0) {\n"
            "\t\t\t\t\t\thtml += '<div style=\"color:#64748b;\">(No events yet)</div>';\n"
            "\t\t\t\t\t} else {\n"
            "\t\t\t\t\t\tvar baseC = diagEvents[0].time;\n"
            "\t\t\t\t\tdiagEvents.forEach(function (ev) {\n"
            "\t\t\t\t\t\tvar diff = ev.time - baseC;\n"
            "\t\t\t\t\t\tvar isM = ev.type.indexOf('milestone:') === 0;\n"
            "\t\t\t\t\t\tvar isErr = ev.type.indexOf('error:') === 0;\n"
            "\t\t\t\t\t\tvar col = isErr ? '#ef4444' : (isM ? '#34d399' : '#94a3b8');\n"
            "\t\t\t\t\t\thtml += '<div style=\"color:' + col + ';word-break:break-all;\">[' + formatTime(ev.time) + ' +' + diff + 'ms] ' + ev.type + formatDetailStr(ev.detail) + '</div>';\n"
            "\t\t\t\t\t});\n"
            "\t\t\t\t\t}\n"
            "\t\t\t\t\thtml += '</div></details>';\n"
            "\t\t\t\t\thtml += '</div>';\n\n"
            "\t\t\t\tdetails.innerHTML = html;\n"
            "\t\t\t}\n\n"
            "\t\t\tif (document.readyState === 'loading') {\n"
            "\t\t\t\tdocument.addEventListener('DOMContentLoaded', createDiagUI);\n"
            "\t\t\t} else {\n"
            "\t\t\t\tcreateDiagUI();\n"
            "\t\t\t}\n"
            "\t\t}\n"
            "\t\t}());\n"
            "\t\t</script>\n\t\t<script src=\"index.js?v=20261026-diag-v1\"></script>\n"
        )

        # Remove any obsolete monkey-patch or previous sync scripts if already present
        content = re.sub(r'<script>\s*// iOS PWA Standalone viewport & height normalization.*?</script>\s*', "", content, flags=re.DOTALL)
        content = re.sub(r'<script>\s*// Standards-safe iOS.*?syncViewport.*?</script>\s*', "", content, flags=re.DOTALL)
        content = re.sub(r'<script>\s*// Standards-safe iOS.*?\[4TM-DIAG.*?</script>\s*', "", content, flags=re.DOTALL)
        content = re.sub(r'<script\s+src="index\.js(?:\?[^"]*)?"></script>\s*', "", content)

        # Remove any previous status-container or status-logo remnants so repeated post_build runs don't duplicate it
        content = re.sub(r'(?:<div id="status-container">.*?</div>|<img id="status-logo"[^>]*></div>)\s*', "", content, flags=re.DOTALL)

        # Loading screen exclusively uses the Dark Games logo (games_logo.svg -> games-logo-dark.svg)
        if '<div id="status">' in content:
            content = content.replace('<div id="status">', f'{pwa_script}\n\t\t<div id="status"><div id="status-container"><div id="status-ring"></div><img id="status-logo" src="games_logo.svg" alt="4TM Games"></div>')
        elif "</body>" in content:
            content = content.replace("</body>", f"{pwa_script}\n</body>")

        with open(html_path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Successfully processed and updated {html_path}")
    else:
        print(f"Error: index.html not found at {html_path}")
        sys.exit(1)

    # 6. Patch Godot 4.3 Web index.js to resolve iOS standalone PWA canvas height discrepancy
    js_path = os.path.join(target_dir, "index.js")
    if os.path.exists(js_path):
        with open(js_path, "r", encoding="utf-8") as f:
            js_content = f.read()

        robust_sizing = (
            "if(isFullscreen||wantsFullWindow){"
            "let probeH=0,insetBot=0;"
            "try{"
            "let pb=document.getElementById('gd-vh-probe');if(!pb){pb=document.createElement('div');pb.id='gd-vh-probe';pb.style.cssText='position:fixed;top:0;bottom:0;left:0;right:0;pointer-events:none;visibility:hidden;z-index:-9999;';document.body&&document.body.appendChild(pb)}"
            "probeH=pb.offsetHeight||(pb.getBoundingClientRect?Math.round(pb.getBoundingClientRect().height):0);"
            "let ins=document.getElementById('gd-ins-probe');if(!ins){ins=document.createElement('div');ins.id='gd-ins-probe';ins.style.cssText='position:fixed;bottom:0;left:0;padding-bottom:env(safe-area-inset-bottom,0px);pointer-events:none;visibility:hidden;z-index:-9999;';document.body&&document.body.appendChild(ins)}"
            "if(ins){insetBot=parseFloat(window.getComputedStyle(ins).paddingBottom)||0}"
            "}catch(e){}"
            "const isIOS=/iPhone|iPad|iPod/.test(navigator.userAgent)||(navigator.platform==='MacIntel'&&navigator.maxTouchPoints>1);"
            "const isStandalone=!!(window.navigator&&window.navigator.standalone)||(window.matchMedia&&window.matchMedia('(display-mode: standalone)').matches);"
            "let standaloneH=0;"
            "if(isStandalone&&isIOS&&window.screen){"
            "const isLand=(window.orientation===90||window.orientation===-90);"
            "standaloneH=isLand?Math.min(window.screen.width,window.screen.height):Math.max(window.screen.width,window.screen.height);"
            "}else if(isStandalone){"
            "standaloneH=(window.innerHeight||0)+insetBot;"
            "}"
            "const vh=Math.max(probeH||0,standaloneH||0,window.innerHeight||0,document.documentElement?document.documentElement.clientHeight||0:0,window.visualViewport?Math.round(window.visualViewport.height)||0:0);"
            "width=window.innerWidth*scale;"
            "height=(vh||window.innerHeight)*scale}"
        )
        sizing_pat = re.compile(r'if\(isFullscreen\|\|wantsFullWindow\)\{.*?(?:height=\(vh\|\|window\.innerHeight\)\*scale|height=window\.innerHeight\*scale)\}')
        if sizing_pat.search(js_content):
            js_content = sizing_pat.sub(robust_sizing, js_content, count=1)
            with open(js_path, "w", encoding="utf-8") as f:
                f.write(js_content)
            print(f"Successfully patched Godot Web canvas sizing in {js_path}")
        else:
            print(f"Notice: Godot canvas sizing target pattern not found in {js_path} (may be custom build).")

    # 7. Generate Web App Manifest for complete metadata compliance with maskable & any purposes
    manifest_path = os.path.join(target_dir, "manifest.json")
    manifest_data = {
        "name": "Block Puzzle — 4TM",
        "short_name": "Block Puzzle",
        "description": "Official 4TM 2D block puzzle game (Xếp Gạch — 4TM) supporting Classic and Modern Drag-and-Drop modes.",
        "start_url": "./",
        "scope": "./",
        "display": "standalone",
        "background_color": "#050B1A",
        "theme_color": "#050B1A",
        "orientation": "portrait",
        "icons": [
            {
                "src": "block-puzzle-favicon.svg",
                "sizes": "any",
                "type": "image/svg+xml"
            },
            {
                "src": "pwa-192.png",
                "sizes": "192x192",
                "type": "image/png",
                "purpose": "any"
            },
            {
                "src": "pwa-512.png",
                "sizes": "512x512",
                "type": "image/png",
                "purpose": "any"
            },
            {
                "src": "pwa-maskable-192.png",
                "sizes": "192x192",
                "type": "image/png",
                "purpose": "maskable"
            },
            {
                "src": "pwa-maskable-512.png",
                "sizes": "512x512",
                "type": "image/png",
                "purpose": "maskable"
            },
            {
                "src": "index.apple-touch-icon.png",
                "sizes": "180x180",
                "type": "image/png"
            }
        ]
    }
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest_data, f, indent=2)
    print(f"Generated manifest.json at {manifest_path}")

    # 8. Safely remove index.pck from the worker public staging directory to stay under individual file size limits
    if os.path.exists(pck_path):
        os.remove(pck_path)
        print("Successfully removed index.pck from Workers Static Assets staging directory (served via R2).")
    else:
        print("Notice: index.pck already absent from staging directory.")

    # 9. Inject robust loading error reporting, unhandled rejection catchers, and stall watchdog into index.html
    if os.path.exists(html_path):
        with open(html_path, "r", encoding="utf-8") as f:
            html_content = f.read()

        robust_startup_script = (
            "setStatusMode('progress');\n"
            "\t\tvar lastProgressTime = Date.now();\n"
            "\t\tvar lastProgressBytes = 0;\n"
            "\t\tvar STALL_TIMEOUT_MS = 30000;\n"
            "\t\tvar watchdogTimer = setInterval(function () {\n"
            "\t\t\tif (!initializing) {\n"
            "\t\t\t\tclearInterval(watchdogTimer);\n"
            "\t\t\t\treturn;\n"
            "\t\t\t}\n"
            "\t\t\tvar idleMs = Date.now() - lastProgressTime;\n"
            "\t\t\tif (idleMs > STALL_TIMEOUT_MS) {\n"
            "\t\t\t\tconsole.warn('Startup watchdog: network transfer inactive for ' + Math.round(idleMs / 1000) + 's.');\n"
            "\t\t\t\tsetStatusNotice('Loading is taking longer than expected (network transfer delayed). Please check your connection or refresh.');\n"
            "\t\t\t\tsetStatusMode('notice');\n"
            "\t\t\t}\n"
            "\t\t}, 3000);\n\n"
            "\t\twindow.addEventListener('error', function (event) {\n"
            "\t\t\tvar errMsg = (event.error && (event.error.message || event.error.stack)) || event.message || 'Script error';\n"
            "\t\t\tconsole.error('[4TM-DIAG] Uncaught error:', errMsg);\n"
            "\t\t\tif (typeof window.__4TM_RECORD_ERROR__ === 'function') {\n"
            "\t\t\t\twindow.__4TM_RECORD_ERROR__('uncaught_error', errMsg, { filename: event.filename, lineno: event.lineno, colno: event.colno });\n"
            "\t\t\t}\n"
            "\t\t\tif (initializing) {\n"
            "\t\t\t\tdisplayFailureNotice(event.error || event.message || 'Global script error occurred during startup.');\n"
            "\t\t\t}\n"
            "\t\t});\n\n"
            "\t\twindow.addEventListener('unhandledrejection', function (event) {\n"
            "\t\t\tvar reason = event.reason ? (event.reason.message || event.reason.stack || event.reason) : 'Unhandled rejection';\n"
            "\t\t\tconsole.error('[4TM-DIAG] Unhandled rejection:', reason);\n"
            "\t\t\tif (typeof window.__4TM_RECORD_ERROR__ === 'function') {\n"
            "\t\t\t\twindow.__4TM_RECORD_ERROR__('unhandled_rejection', reason, {});\n"
            "\t\t\t}\n"
            "\t\t\tif (initializing) {\n"
            "\t\t\t\tvar rMsg = event.reason ? (event.reason.message || event.reason) : 'Unhandled promise rejection.';\n"
            "\t\t\t\tdisplayFailureNotice('Startup rejection: ' + rMsg);\n"
            "\t\t\t}\n"
            "\t\t});\n\n"
            "\t\tengine.startGame({\n"
            "\t\t\t'onProgress': function (current, total) {\n"
            "\t\t\t\tif (current > lastProgressBytes) {\n"
            "\t\t\t\t\tlastProgressBytes = current;\n"
            "\t\t\t\t\tlastProgressTime = Date.now();\n"
            "\t\t\t\t\tif (statusMode === 'notice' && initializing) {\n"
            "\t\t\t\t\t\tsetStatusMode('progress');\n"
            "\t\t\t\t\t}\n"
            "\t\t\t\t}\n"
            "\t\t\t\tif (current > 0 && total > 0) {\n"
            "\t\t\t\t\tstatusProgress.value = current;\n"
            "\t\t\t\t\tstatusProgress.max = total;\n"
            "\t\t\t\t} else {\n"
            "\t\t\t\t\tstatusProgress.removeAttribute('value');\n"
            "\t\t\t\t\tstatusProgress.removeAttribute('max');\n"
            "\t\t\t\t}\n"
            "\t\t\t},\n"
            "\t\t}).then(() => {\n"
            "\t\t\tif (watchdogTimer) clearInterval(watchdogTimer);\n"
            "\t\t\tsetStatusMode('hidden');\n"
            "\t\t\tif (statusOverlay && statusOverlay.parentNode) {\n"
            "\t\t\t\tstatusOverlay.remove();\n"
            "\t\t\t}\n"
            "\t\t\tinitializing = false;\n"
            "\t\t\t// On Safari web only (non-PWA standalone), switch browser-visible background and theme-color to navy blue #293D8A\n"
            "\t\t\tvar isIOS = /iPhone|iPad|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);\n"
            "\t\t\tvar isStandalone = !!(window.navigator && window.navigator.standalone) || (window.matchMedia && window.matchMedia('(display-mode: standalone)').matches);\n"
            "\t\t\tvar isSafari = isIOS || /^((?!chrome|android).)*safari/i.test(navigator.userAgent);\n"
            "\t\t\tif (isSafari && !isStandalone) {\n"
            "\t\t\t\tdocument.body.style.backgroundColor = '#293D8A';\n"
            "\t\t\t\tdocument.documentElement.style.backgroundColor = '#293D8A';\n"
            "\t\t\t\tvar metaTheme = document.querySelector('meta[name=\"theme-color\"]');\n"
            "\t\t\t\tif (metaTheme) {\n"
            "\t\t\t\t\tmetaTheme.setAttribute('content', '#293D8A');\n"
            "\t\t\t\t}\n"
            "\t\t\t}\n"
            "\t\t}, function (err) {\n"
            "\t\t\tif (watchdogTimer) clearInterval(watchdogTimer);\n"
            "\t\t\tconsole.error('Godot startup failure:', err);\n"
            "\t\t\tif (typeof window.__4TM_RECORD_ERROR__ === 'function') {\n"
            "\t\t\t\twindow.__4TM_RECORD_ERROR__('godot_startup_failure', err, {});\n"
            "\t\t\t}\n"
            "\t\t\tdisplayFailureNotice(err);\n"
            "\t\t});"
        )

        engine_start_pattern = re.compile(
            r"setStatusMode\('progress'\);.+?engine\.startGame\(.+?(?:displayFailureNotice\(err\);\s*\}\);|displayFailureNotice\s*\);)",
            re.DOTALL
        )
        if engine_start_pattern.search(html_content):
            html_content = engine_start_pattern.sub(robust_startup_script, html_content, count=1)
            with open(html_path, "w", encoding="utf-8") as f:
                f.write(html_content)
            print("Successfully injected robust loading error handlers and stall watchdog into index.html")
        else:
            print("Notice: engine.startGame pattern not found in index.html")

if __name__ == "__main__":
    main()
