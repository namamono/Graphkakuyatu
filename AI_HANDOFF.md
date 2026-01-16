# AI Context / Handoff Document - Godot DOT Editor

## Project Overview
This project is a visual editor for Graphviz DOT files, built with Godot 4.x.
It supports creating nodes/edges, auto-layout, undo/redo, and exporting to `.dot` format.

## Architecture

### Core Systems (`src/core/`)
- **`GraphManager.gd`**: The simplified Model. Stores `nodes` (Dictionary) and `edges` (Array of Dictionaries). Emits signals (`node_added`, `edge_removed`, `graph_updated`) to notify views.
- **`CommandManager.gd`**: Handles Undo/Redo using the Command pattern. All state-changing actions (add, remove, move, edit label) are encapsulated in `Command` classes.
- **`LayoutEngine.gd`**: Implements a force-directed graph layout algorithm.
  - **Key Parameters**: Repulsion (~2000), Spring Length (~120), Gravity (0.05).
  - Gravity was added to keep unconnected components from drifting too far.

### Visuals / Views (`src/scenes/`)
- **`Main.gd`**: The Controller/Main View. Handles input (mouse clicks, zoom/pan), coordinates high-level logic, and syncs `GraphManager` state to `NodesLayer`/`EdgesLayer`.
- **`GraphNode.gd`**: Visual representation of a node.
  - **Dynamic Sizing**: Uses `Label` size + padding. Special logic forces a minimum circle size for short text (length <= 2) to prevent ugly ellipses.
  - **Interaction**: Handles dragging and selection signals.
- **`Edge.gd`**: Visual representation of an edge using `Line2D`.
  - **Curved Lines**: Bidirectional connections (A->B and B->A) are automatically curved (Bezier) to avoid overlap. Logic resides in `Main.gd` (calculating offsets) and `Edge.gd` (drawing).
  - **Arrows**: Drawn manually in `_draw()` at the end of the line.

### Data & Utils (`src/autoloads/`, `src/utils/`)
- **`Global.gd`**: Constants (`NODE_RADIUS`, colors) and ID generation.
- **`DotExporter.gd`**: Converts internal graph state to DOT format.
  - **Format**: `digraph` with `->` syntax.
  - **Coordinates**: Godot's Y axis (down) is negated during export to match Graphviz's Y axis (up).

## Important Implementation Details ("Gotchas")

1. **Edge Separation Logic**:
   - `Main.gd` iterates edges and groups them by node pair.
   - If multiple edges exist between A and B, it calculates a `curve_offset`.
   - **Critical**: For mutual connections (A->B, B->A), the logic compares ID strings (`from > to`) to flip the offset sign, ensuring they curve in opposite directions (e.g., one up, one down). Separation spread is set to `60.0`.

2. **Node Sizing**:
   - `GraphNode` resets `label.size = Vector2.ZERO` before updating visuals to ensure it shrinks correctly when text is shortened.
   - Heavy padding is applied to maintain a "bubble" look.

3. **Input Handling**:
   - `NodesLayer` is explicitly ordered *above* `EdgesLayer` (`move_child` in `Main._ready`).
   - `_unhandled_input` manages Camera zoom/pan.
   - `GraphNode` handles its own input events for selection/dragging.

4. **Coordinate System**:
   - Godot: (0,0) Top-Left, +Y Down.
   - Graphviz/DOT: (0,0) varies (often Bottom-Left implied), +Y Up.
   - Exporter flips Y: `pos = (x, -y)`.

## Current Status (as of 2026-01-16)
- All base features verified.
- Visuals tuned for "premium" feel (smooth curves, dynamic sizing).
- Auto Layout is stable with gravity.
- Undo/Redo covers all mutations.

## Future Tasks / ideas
- **Load DOT**: Implementing a parser to read `.dot` files back into the editor (currently write-only).
- **Node Styling**: Allow changing shapes (box, diamond) or colors per node via Property Panel.
- **Minimap**: For large graphs.
