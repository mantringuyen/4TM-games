# 4TM-games — Long-Term Multi-Game Repository

Official workspace for the **4TM Games** suite within the **4TM Ecosystem** (`https://4tm.io.vn`).

## Repository Architecture

```text
4TM-games/
├── showcase/                 # games.4tm.io.vn React/Vite web showcase
│   ├── index.html
│   ├── vite.config.ts
│   ├── public/
│   │   └── games/            # Target folder for Godot HTML5/WASM web exports
│   └── src/
│       ├── components/       # Showcase UI & playable demo games
│       ├── data/             # Game catalog metadata registry
│       ├── types/            # Game metadata types
│       ├── utils/            # Web Audio engine
│       ├── App.tsx           # Showcase portal entry & game runner
│       └── main.tsx
│
├── games/
│   └── xep-gach/             # Reserved for future Godot 4.x 2D game project
│       └── README.md
│
├── shared/                   # Reserved for shared brand tokens & specifications
│   └── README.md
│
├── package.json              # Root workspace build scripts
└── metadata.json             # Application metadata
```

## Production Domain Concept
- **Showcase Portal:** `https://games.4tm.io.vn`
- **Flagship Game Route:** `https://games.4tm.io.vn/games/xep-gach`
