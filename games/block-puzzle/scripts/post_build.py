#!/usr/bin/env python3
import os
import sys

def main():
    target_dir = "workers/4tm-games-dev/public/block-puzzle"
    if len(sys.argv) > 1:
        target_dir = sys.argv[1]
        
    print(f"Running post-build processing on target directory: {target_dir}")
    
    html_path = os.path.join(target_dir, "index.html")
    pck_path = os.path.join(target_dir, "index.pck")
    
    # 1. Ensure clean and correct Godot engine package configuration in index.html
    if os.path.exists(html_path):
        with open(html_path, "r", encoding="utf-8") as f:
            content = f.read()
        
        import re
        # Ensure canonical package configuration: strip any legacy or cross-origin mainPack URL
        # so Godot engine defaults to canonical relative 'index.pck' (/block-puzzle/index.pck via Worker)
        content = re.sub(r'"mainPack":"[^"]*",?', '', content)
        
        # If index.pck exists locally or in build/web before staging removal, synchronize exact fileSizes tracking
        actual_pck_size = None
        if os.path.exists(pck_path):
            actual_pck_size = os.path.getsize(pck_path)
        elif os.path.exists("build/web/index.pck"):
            actual_pck_size = os.path.getsize("build/web/index.pck")
        elif os.path.exists("../../build/web/index.pck"):
            actual_pck_size = os.path.getsize("../../build/web/index.pck")

        if actual_pck_size:
            content = re.sub(r'"index\.pck":\s*\d+', f'"index.pck":{actual_pck_size}', content)

        # 2. Ensure iOS viewport, safe-area, theme-color and PWA meta tags
        content = re.sub(r'<meta\s+name=["\'](theme-color|description|apple-mobile-web-app-[^"\']+|mobile-web-app-capable)["\'][^>]*>\s*', '', content)
        content = re.sub(r'<link\s+rel=["\']manifest["\'][^>]*>\s*', '', content)
        meta_tags = (
            '\n\t\t<meta name="description" content="Official 4TM 2D block puzzle game (Xếp Gạch — 4TM) supporting Classic and Modern Drag-and-Drop modes.">'
            '\n\t\t<meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, viewport-fit=cover">'
            '\n\t\t<meta name="theme-color" content="#1f3885">'
            '\n\t\t<meta name="apple-mobile-web-app-capable" content="yes">'
            '\n\t\t<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">'
            '\n\t\t<meta name="apple-mobile-web-app-title" content="Block Puzzle — 4TM">'
            '\n\t\t<meta name="mobile-web-app-capable" content="yes">'
            '\n\t\t<link rel="manifest" href="manifest.json">'
        )
        if '<head>' in content:
            if '<meta name="viewport"' in content:
                content = re.sub(r'<meta\s+name=["\']viewport["\'][^>]*>', meta_tags, content, count=1)
            else:
                content = content.replace('<head>', f'<head>{meta_tags}')

        # 3. Ensure edge-to-edge full viewport CSS styling without artificial black gaps
        css_replacement = (
            "html, body, #canvas {\n\tmargin: 0;\n\tpadding: 0;\n\tborder: 0;\n}\n\n"
            "html, body {\n\twidth: 100%;\n\theight: 100%;\n\theight: 100dvh;\n\tmin-height: 100vh;\n\tmin-height: 100dvh;\n\tmin-height: -webkit-fill-available;\n\tcolor: white;\n\tbackground-color: #1f3885;\n\toverflow: hidden;\n\toverscroll-behavior: none;\n\ttouch-action: none;\n\t-webkit-touch-callout: none;\n\t-webkit-user-select: none;\n\tuser-select: none;\n}\n\n"
            "#canvas {\n\tdisplay: block;\n\tposition: fixed;\n\ttop: 0;\n\tleft: 0;\n\tright: 0;\n\tbottom: 0;\n\twidth: 100%;\n\twidth: 100vw;\n\twidth: 100dvw;\n\theight: 100%;\n\theight: 100vh;\n\theight: 100dvh;\n\tbackground-color: #1f3885;\n}"
        )
        old_css_pat = re.compile(r'html,\s*body,\s*#canvas\s*\{[^}]*\}(?:\s*html\s*,\s*body|\s*body)\s*\{[^}]*\}\s*#canvas\s*\{[^}]*\}', re.DOTALL)
        if old_css_pat.search(content):
            content = old_css_pat.sub(css_replacement, content, count=1)

        # 4. Inject standards-safe iOS viewport height sync script and diagnostic HUD before index.js
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
            "\t\t\t\tif (!probe.parentNode && document.body) {\n"
            "\t\t\t\t\tdocument.body.appendChild(probe);\n"
            "\t\t\t\t}\n"
            "\t\t\t\tif (!ins.parentNode && document.body) {\n"
            "\t\t\t\t\tdocument.body.appendChild(ins);\n"
            "\t\t\t\t}\n"
            "\t\t\t\tvar probeH = probe.offsetHeight || (probe.getBoundingClientRect ? Math.round(probe.getBoundingClientRect().height) : 0);\n"
            "\t\t\t\tvar docH = (document.documentElement && document.documentElement.clientHeight) || 0;\n"
            "\t\t\t\tvar winH = window.innerHeight || 0;\n"
            "\t\t\t\tvar vvH = (window.visualViewport && Math.round(window.visualViewport.height)) || 0;\n"
            "\t\t\t\tvar insetBot = 0;\n"
            "\t\t\t\tif (ins) {\n"
            "\t\t\t\t\tvar cs = window.getComputedStyle(ins);\n"
            "\t\t\t\t\tinsetBot = parseFloat(cs.paddingBottom) || 0;\n"
            "\t\t\t\t}\n"
            "\t\t\t\tvar isStandalone = !!(window.navigator && window.navigator.standalone);\n"
            "\t\t\t\tvar standaloneH = isStandalone ? (winH + insetBot) : 0;\n"
            "\t\t\t\treturn Math.max(probeH, docH, winH, vvH, standaloneH);\n"
            "\t\t\t}\n"
            "\t\t\tfunction syncViewport() {\n"
            "\t\t\t\tvar h = getEffectiveHeight();\n"
            "\t\t\t\tif (h) {\n"
            "\t\t\t\t\tdocument.documentElement.style.setProperty('--vh', (h * 0.01) + 'px');\n"
            "\t\t\t\t}\n"
            "\t\t\t}\n"
            "\t\t\tsyncViewport();\n"
            "\t\t\twindow.addEventListener('resize', syncViewport);\n"
            "\t\t\twindow.addEventListener('orientationchange', syncViewport);\n"
            "\t\t\t// Controlled settling triggers for iOS standalone PWA bottom chin layout\n"
            "\t\t\t[100, 250, 500, 1000].forEach(function (delay) {\n"
            "\t\t\t\tsetTimeout(function () {\n"
            "\t\t\t\t\tsyncViewport();\n"
            "\t\t\t\t\twindow.dispatchEvent(new Event('resize'));\n"
            "\t\t\t\t}, delay);\n"
            "\t\t\t});\n"
            "\t\t}());\n"
            "\t\t// Standards-safe iOS viewport diagnostic telemetry (headless)\n"
            "\t\t(function () {\n"
            "\t\t\tfunction updateDiag() {\n"
            "\t\t\t\tvar probe = document.getElementById('gd-vh-probe');\n"
            "\t\t\t\tvar ins = document.getElementById('gd-ins-probe');\n"
            "\t\t\t\tvar canvas = document.getElementById('canvas');\n"
            "\t\t\t\tvar winH = window.innerHeight || 0;\n"
            "\t\t\t\tvar winW = window.innerWidth || 0;\n"
            "\t\t\t\tvar docH = (document.documentElement && document.documentElement.clientHeight) || 0;\n"
            "\t\t\t\tvar vvH = (window.visualViewport && Math.round(window.visualViewport.height)) || 0;\n"
            "\t\t\t\tvar probeH = (probe && (probe.offsetHeight || (probe.getBoundingClientRect && Math.round(probe.getBoundingClientRect().height)))) || 0;\n"
            "\t\t\t\tvar scrH = (window.screen && window.screen.height) || 0;\n"
            "\t\t\t\tvar isStandalone = !!(window.navigator && window.navigator.standalone);\n"
            "\t\t\t\tvar displayModeStandalone = window.matchMedia && window.matchMedia('(display-mode: standalone)').matches;\n"
            "\t\t\t\tvar insetT = 0, insetB = 0;\n"
            "\t\t\t\tif (ins) {\n"
            "\t\t\t\t\tvar cs = window.getComputedStyle(ins);\n"
            "\t\t\t\t\tinsetT = parseFloat(cs.paddingTop) || 0;\n"
            "\t\t\t\t\tinsetB = parseFloat(cs.paddingBottom) || 0;\n"
            "\t\t\t\t}\n"
            "\t\t\t\tvar csw = canvas ? canvas.style.width : 'N/A';\n"
            "\t\t\t\tvar csh = canvas ? canvas.style.height : 'N/A';\n"
            "\t\t\t\tvar cw = canvas ? canvas.width : 'N/A';\n"
            "\t\t\t\tvar ch = canvas ? canvas.height : 'N/A';\n"
            "\t\t\t\tvar modeStr = isStandalone ? 'PWA-STANDALONE' : (displayModeStandalone ? 'STANDALONE-MEDIA' : 'SAFARI-WEB');\n"
            "\t\t\t\twindow.__4TM_DIAG__ = {\n"
            "\t\t\t\t\tbuild: '2026.10.10-v1',\n"
            "\t\t\t\t\tmode: modeStr,\n"
            "\t\t\t\t\turl: window.location.href,\n"
            "\t\t\t\t\twinH: winH, winW: winW, docH: docH, vvH: vvH, probeH: probeH, scrH: scrH,\n"
            "\t\t\t\t\tinsetTop: insetT, insetBottom: insetB,\n"
            "\t\t\t\t\tcanvasStyle: { width: csw, height: csh },\n"
            "\t\t\t\t\tcanvasPixels: { width: cw, height: ch }\n"
            "\t\t\t\t};\n"
            "\t\t\t}\n"
            "\t\t\twindow.addEventListener('resize', updateDiag);\n"
            "\t\t\twindow.addEventListener('orientationchange', updateDiag);\n"
            "\t\t\tupdateDiag();\n"
            "\t\t}());\n"
            "\t\t</script>\n\t\t<script src=\"index.js?v=20261010-v1\"></script>"
        )
        # Remove any obsolete monkey-patch or previous sync scripts if already present
        content = re.sub(r'<script>\s*// iOS PWA Standalone viewport & height normalization.*?</script>\s*', '', content, flags=re.DOTALL)
        content = re.sub(r'<script>\s*// Standards-safe iOS.*?syncViewport.*?</script>\s*', '', content, flags=re.DOTALL)
        content = re.sub(r'<script>\s*// Standards-safe iOS.*?\[4TM-DIAG.*?</script>\s*', '', content, flags=re.DOTALL)
        content = re.sub(r'<script\s+src="index\.js(?:\?[^"]*)?"></script>\s*', '', content)
        if '<div id="status">' in content:
            content = content.replace('<div id="status">', f'{pwa_script}\n\t\t<div id="status">')
        elif '</body>' in content:
            content = content.replace('</body>', f'{pwa_script}\n</body>')

        with open(html_path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Successfully processed and updated {html_path}")
    else:
        print(f"Error: index.html not found at {html_path}")
        sys.exit(1)

    # 3. Patch Godot 4.3 Web index.js to resolve iOS standalone PWA canvas height discrepancy
    # In iOS standalone PWA, WebKit's window.innerHeight initially omits the home indicator chin,
    # causing Godot's WebGL backbuffer to render shorter than the screen.
    # We patch Godot's sizing calculation to evaluate documentElement.clientHeight, visualViewport,
    # and safe-area inset bottom when standalone, keeping DOM canvas size and backbuffer strictly synced.
    js_path = os.path.join(target_dir, "index.js")
    if os.path.exists(js_path):
        with open(js_path, "r", encoding="utf-8") as f:
            js_content = f.read()

        target_sizing = "if(isFullscreen||wantsFullWindow){width=window.innerWidth*scale;height=window.innerHeight*scale}"
        prev_patch = (
            "if(isFullscreen||wantsFullWindow){"
            "const vh=Math.max(window.innerHeight||0,document.documentElement?document.documentElement.clientHeight||0:0,window.visualViewport?Math.round(window.visualViewport.height)||0:0);"
            "width=window.innerWidth*scale;"
            "height=(vh||window.innerHeight)*scale}"
        )
        old_robust_sizing = (
            "if(isFullscreen||wantsFullWindow){"
            "let probeH=0;"
            "try{let pb=document.getElementById('gd-vh-probe');if(!pb){pb=document.createElement('div');pb.id='gd-vh-probe';pb.style.cssText='position:fixed;top:0;bottom:0;left:0;right:0;height:100dvh;pointer-events:none;visibility:hidden;z-index:-9999;';document.body&&document.body.appendChild(pb)}probeH=pb.offsetHeight||(pb.getBoundingClientRect?Math.round(pb.getBoundingClientRect().height):0)}catch(e){}"
            "const vh=Math.max(probeH||0,window.innerHeight||0,document.documentElement?document.documentElement.clientHeight||0:0,window.visualViewport?Math.round(window.visualViewport.height)||0:0);"
            "width=window.innerWidth*scale;"
            "height=(vh||window.innerHeight)*scale}"
        )
        robust_sizing = (
            "if(isFullscreen||wantsFullWindow){"
            "let probeH=0,insetBot=0;"
            "try{"
            "let pb=document.getElementById('gd-vh-probe');if(!pb){pb=document.createElement('div');pb.id='gd-vh-probe';pb.style.cssText='position:fixed;top:0;bottom:0;left:0;right:0;pointer-events:none;visibility:hidden;z-index:-9999;';document.body&&document.body.appendChild(pb)}"
            "probeH=pb.offsetHeight||(pb.getBoundingClientRect?Math.round(pb.getBoundingClientRect().height):0);"
            "let ins=document.getElementById('gd-ins-probe');if(!ins){ins=document.createElement('div');ins.id='gd-ins-probe';ins.style.cssText='position:fixed;bottom:0;left:0;padding-bottom:env(safe-area-inset-bottom,0px);pointer-events:none;visibility:hidden;z-index:-9999;';document.body&&document.body.appendChild(ins)}"
            "if(ins){insetBot=parseFloat(window.getComputedStyle(ins).paddingBottom)||0}"
            "}catch(e){}"
            "const isStandalone=!!(window.navigator&&window.navigator.standalone);"
            "const standaloneH=isStandalone?((window.innerHeight||0)+insetBot):0;"
            "const vh=Math.max(probeH||0,standaloneH||0,window.innerHeight||0,document.documentElement?document.documentElement.clientHeight||0:0,window.visualViewport?Math.round(window.visualViewport.height)||0:0);"
            "width=window.innerWidth*scale;"
            "height=(vh||window.innerHeight)*scale}"
        )
        if target_sizing in js_content:
            js_content = js_content.replace(target_sizing, robust_sizing)
            with open(js_path, "w", encoding="utf-8") as f:
                f.write(js_content)
            print(f"Successfully patched Godot Web canvas sizing in {js_path}")
        elif prev_patch in js_content:
            js_content = js_content.replace(prev_patch, robust_sizing)
            with open(js_path, "w", encoding="utf-8") as f:
                f.write(js_content)
            print(f"Successfully upgraded Godot Web canvas sizing in {js_path}")
        elif old_robust_sizing in js_content:
            js_content = js_content.replace(old_robust_sizing, robust_sizing)
            with open(js_path, "w", encoding="utf-8") as f:
                f.write(js_content)
            print(f"Successfully updated Godot Web canvas sizing to standalone safe-area probe in {js_path}")
        elif robust_sizing in js_content:
            print(f"Godot Web canvas sizing already patched in {js_path}")
        else:
            print(f"Notice: Godot canvas sizing target pattern not found in {js_path} (may be custom build).")

    # 4. Generate Web App Manifest for complete metadata compliance
    manifest_path = os.path.join(target_dir, "manifest.json")
    import json
    manifest_data = {
        "name": "Block Puzzle — 4TM",
        "short_name": "Block Puzzle",
        "description": "Official 4TM 2D block puzzle game (Xếp Gạch — 4TM) supporting Classic and Modern Drag-and-Drop modes.",
        "start_url": "./",
        "scope": "./",
        "display": "standalone",
        "background_color": "#1f3885",
        "theme_color": "#1f3885",
        "orientation": "portrait",
        "icons": [
            {
                "src": "index.icon.png",
                "sizes": "192x192",
                "type": "image/png"
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

    # 5. Safely remove index.pck from the worker public staging directory to stay under individual file size limits
    if os.path.exists(pck_path):
        os.remove(pck_path)
        print("Successfully removed index.pck from Workers Static Assets staging directory.")
    else:
        print("index.pck already absent or removed from staging directory.")

if __name__ == "__main__":
    main()
