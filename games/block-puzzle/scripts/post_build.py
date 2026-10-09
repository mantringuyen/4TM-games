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

        # 4. Inject standards-safe iOS viewport height sync script before index.js
        pwa_script = (
            "\t\t<script>\n"
            "\t\t// Standards-safe iOS viewport height normalization: ensures CSS layout tracks actual client height\n"
            "\t\t(function () {\n"
            "\t\t\tfunction syncViewport() {\n"
            "\t\t\t\tvar h = (document.documentElement && document.documentElement.clientHeight) || window.innerHeight;\n"
            "\t\t\t\tif (h) {\n"
            "\t\t\t\t\tdocument.documentElement.style.setProperty('--vh', (h * 0.01) + 'px');\n"
            "\t\t\t\t}\n"
            "\t\t\t}\n"
            "\t\t\tsyncViewport();\n"
            "\t\t\twindow.addEventListener('resize', syncViewport);\n"
            "\t\t\twindow.addEventListener('orientationchange', syncViewport);\n"
            "\t\t}());\n"
            "\t\t</script>\n\t\t<script src=\"index.js\"></script>"
        )
        # Remove any obsolete monkey-patch script if already present
        content = re.sub(r'<script>\s*// iOS PWA Standalone viewport & height normalization.*?</script>\s*', '', content, flags=re.DOTALL)
        content = re.sub(r'<script>\s*// Standards-safe iOS.*?syncViewportHeight.*?</script>\s*', '', content, flags=re.DOTALL)
        if '<script src="index.js"></script>' in content:
            content = content.replace('<script src="index.js"></script>', pwa_script)

        with open(html_path, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Successfully processed and updated {html_path}")
    else:
        print(f"Error: index.html not found at {html_path}")
        sys.exit(1)

    # 3. Patch Godot 4.3 Web index.js to resolve iOS standalone PWA canvas height discrepancy
    # In iOS standalone PWA, WebKit's window.innerHeight initially omits the home indicator chin,
    # causing Godot's WebGL backbuffer to render shorter than the screen.
    # We patch Godot's sizing calculation to consider documentElement.clientHeight and visualViewport.height
    # without overriding window.innerHeight or referencing window.screen.height.
    js_path = os.path.join(target_dir, "index.js")
    if os.path.exists(js_path):
        with open(js_path, "r", encoding="utf-8") as f:
            js_content = f.read()

        target_sizing = "if(isFullscreen||wantsFullWindow){width=window.innerWidth*scale;height=window.innerHeight*scale}"
        safe_sizing = (
            "if(isFullscreen||wantsFullWindow){"
            "const vh=Math.max(window.innerHeight||0,document.documentElement?document.documentElement.clientHeight||0:0,window.visualViewport?Math.round(window.visualViewport.height)||0:0);"
            "width=window.innerWidth*scale;"
            "height=(vh||window.innerHeight)*scale}"
        )
        if target_sizing in js_content:
            js_content = js_content.replace(target_sizing, safe_sizing)
            with open(js_path, "w", encoding="utf-8") as f:
                f.write(js_content)
            print(f"Successfully patched Godot Web canvas sizing in {js_path}")
        elif safe_sizing in js_content:
            print(f"Godot Web canvas sizing already patched in {js_path}")
        else:
            print(f"Notice: Godot canvas sizing target pattern not found in {js_path} (may be custom build).")

    # 4. Safely remove index.pck from the worker public staging directory to stay under individual file size limits
    if os.path.exists(pck_path):
        os.remove(pck_path)
        print("Successfully removed index.pck from Workers Static Assets staging directory.")
    else:
        print("index.pck already absent or removed from staging directory.")

if __name__ == "__main__":
    main()
