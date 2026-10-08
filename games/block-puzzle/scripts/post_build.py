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
    
    # 1. Inject mainPack configuration into index.html
    if os.path.exists(html_path):
        with open(html_path, "r", encoding="utf-8") as f:
            content = f.read()
        
        # Determine the R2 Asset URL (use custom domain, support override via env var)
        r2_asset_url = os.environ.get("R2_ASSET_URL", "https://games-data.4tm.io.vn/games/block-puzzle/index.pck")
        
        import re
        # Remove any existing mainPack key to prevent duplicates
        content = re.sub(r'"mainPack":"[^"]*",', '', content)
        
        target = "const GODOT_CONFIG = {"
        replacement = f'const GODOT_CONFIG = {{"mainPack":"{r2_asset_url}",'
        
        if target in content:
            content = content.replace(target, replacement)
        else:
            print("Error: const GODOT_CONFIG block not found in index.html.")
            sys.exit(1)

        # 2. Ensure iOS viewport, safe-area, theme-color and PWA meta tags
        content = re.sub(r'<meta\s+name=["\'](theme-color|apple-mobile-web-app-[^"\']+|mobile-web-app-capable)["\'][^>]*>\s*', '', content)
        meta_tags = (
            '\n\t\t<meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, viewport-fit=cover">'
            '\n\t\t<meta name="theme-color" content="#1f3885">'
            '\n\t\t<meta name="apple-mobile-web-app-capable" content="yes">'
            '\n\t\t<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">'
            '\n\t\t<meta name="apple-mobile-web-app-title" content="Block Puzzle — 4TM">'
            '\n\t\t<meta name="mobile-web-app-capable" content="yes">'
        )
        if '<head>' in content:
            if '<meta name="viewport"' in content:
                content = re.sub(r'<meta\s+name=["\']viewport["\'][^>]*>', meta_tags, content, count=1)
            else:
                content = content.replace('<head>', f'<head>{meta_tags}')

        # 3. Ensure edge-to-edge full viewport CSS styling without artificial black gaps
        css_replacement = (
            "html, body, #canvas {\n\tmargin: 0;\n\tpadding: 0;\n\tborder: 0;\n}\n\n"
            "html, body {\n\twidth: 100%;\n\theight: 100%;\n\tmin-height: 100vh;\n\tmin-height: 100dvh;\n\tmin-height: -webkit-fill-available;\n\tcolor: white;\n\tbackground-color: #1f3885;\n\toverflow: hidden;\n\ttouch-action: none;\n\t-webkit-touch-callout: none;\n\t-webkit-user-select: none;\n\tuser-select: none;\n}\n\n"
            "#canvas {\n\tdisplay: block;\n\tposition: fixed;\n\ttop: 0;\n\tleft: 0;\n\twidth: 100%;\n\theight: 100%;\n}"
        )
        old_css_pat = re.compile(r'html,\s*body,\s*#canvas\s*\{[^}]*\}\s*body\s*\{[^}]*\}\s*#canvas\s*\{[^}]*\}', re.DOTALL)
        if old_css_pat.search(content):
            content = old_css_pat.sub(css_replacement, content, count=1)

        # 4. Inject iOS standalone PWA height normalization script before index.js to prevent bottom chin gap
        pwa_script = (
            "\t\t<script>\n"
            "\t\t// iOS PWA Standalone viewport & height normalization: eliminates bottom chin gap\n"
            "\t\t(function () {\n"
            "\t\t\tfunction fixPwaViewport() {\n"
            "\t\t\t\tvar isStandalone = (window.navigator && window.navigator.standalone === true) ||\n"
            "\t\t\t\t\t(window.matchMedia && window.matchMedia('(display-mode: standalone)').matches);\n"
            "\t\t\t\tvar isIOS = /iPhone|iPad|iPod/.test(navigator.userAgent) ||\n"
            "\t\t\t\t\t(navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);\n"
            "\t\t\t\tif (isIOS && isStandalone) {\n"
            "\t\t\t\t\tvar screenH = window.screen.height;\n"
            "\t\t\t\t\tif (screenH && window.innerHeight < screenH) {\n"
            "\t\t\t\t\t\ttry {\n"
            "\t\t\t\t\t\t\tObject.defineProperty(window, 'innerHeight', {\n"
            "\t\t\t\t\t\t\t\tget: function () { return window.screen.height; },\n"
            "\t\t\t\t\t\t\t\tconfigurable: true\n"
            "\t\t\t\t\t\t\t});\n"
            "\t\t\t\t\t\t} catch (e) {}\n"
            "\t\t\t\t\t}\n"
            "\t\t\t\t}\n"
            "\t\t\t}\n"
            "\t\t\tfixPwaViewport();\n"
            "\t\t\twindow.addEventListener('resize', fixPwaViewport);\n"
            "\t\t\twindow.addEventListener('orientationchange', fixPwaViewport);\n"
            "\t\t}());\n"
            "\t\t</script>\n\t\t<script src=\"index.js\"></script>"
        )
        if '<script src="index.js"></script>' in content and 'fixPwaViewport' not in content:
            content = content.replace('<script src="index.js"></script>', pwa_script)

        with open(html_path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Successfully processed and updated {html_path}")
    else:
        print(f"Error: index.html not found at {html_path}")
        sys.exit(1)
        
    # 2. Safely remove index.pck from the worker public staging directory to stay under individual file size limits
    if os.path.exists(pck_path):
        os.remove(pck_path)
        print("Successfully removed index.pck from Workers Static Assets staging directory.")
    else:
        print("index.pck already absent or removed from staging directory.")

if __name__ == "__main__":
    main()
