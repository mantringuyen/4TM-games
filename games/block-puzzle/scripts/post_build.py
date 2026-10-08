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
            with open(html_path, "w", encoding="utf-8") as f:
                f.write(content)
            print(f"Successfully injected mainPack URL: {r2_asset_url}")
        else:
            print("Error: const GODOT_CONFIG block not found in index.html.")
            sys.exit(1)
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
