# Biorepository Tycoon

An isometric management game built with Godot 4.2.

## How to Play
1.  **Buy Freezers**: Click the button at the bottom to enter building mode, then click on the grid to place a freezer ($1000).
2.  **Manage Storage**: Click on a placed freezer to open its inventory.
3.  **Hierarchical Storage**:
    - **Freezers** contain **Racks**.
    - **Racks** contain **Boxes**.
    - **Boxes** contain **Vials**.
4.  **Populate**: Click on empty slots within the inventory UI to "purchase" and place the next level of storage (e.g., click an empty slot in a Rack to add a Box).

## Project Structure
- `scenes/`: Godot scene files (.tscn).
- `scripts/`: GDScript logic files.
- `project.godot`: Main project configuration.

## Setup
To open this project, launch **Godot Engine 4.2+** and select **Import**, then browse to the `project.godot` file in this directory.
