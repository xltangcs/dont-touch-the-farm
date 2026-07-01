import tkinter as tk
from tkinter import ttk, messagebox
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from path_utils import get_project_root
from editor_state import EditorState
from editor_panel import TilePalette
from editor_grid import TileGrid
from editor_toolbar import EditorToolbar
from editor_settings import EditorSettings


class LevelEditorApp:

    def __init__(self):
        self.project_root = get_project_root()
        self.state = EditorState(self.project_root)

        self.root = tk.Tk()
        self.root.title("Tile Map Editor")
        self.root.geometry("1200x750")
        self.root.minsize(800, 500)

        try:
            self.state.load_tile_configs()
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load tile configs:\n{e}")
            self.root.destroy()
            return

        self._build_ui()
        self._bind_shortcuts()

        self.state.new_level(10, 10)
        self._panel.build_palette()
        self._settings._refresh_controls()
        self._grid.rebuild()
        self._update_title()

    def _build_ui(self):
        self._toolbar = EditorToolbar(self.root, self.state, None,
                                      on_modified_callback=self._update_title)
        self._toolbar.pack(side="top", fill="x", padx=4, pady=4)

        body = ttk.PanedWindow(self.root, orient="horizontal")
        body.pack(side="top", fill="both", expand=True)

        left_frame = ttk.Frame(body)
        body.add(left_frame, weight=0)

        self._panel = TilePalette(left_frame, self.state)
        self._panel.pack(side="top", fill="both", expand=True)

        self._grid = TileGrid(body, self.state)
        body.add(self._grid, weight=1)

        self._settings = EditorSettings(left_frame, self.state, self._grid,
                                        on_modified_callback=self._update_title)
        self._settings.pack(side="bottom", fill="x")

        self._toolbar.grid_widget = self._grid
        self._toolbar.settings_widget = self._settings
        self._toolbar.panel_widget = self._panel
        self._grid.settings_widget = self._settings
        self._panel.grid_widget = self._grid

    def _bind_shortcuts(self):
        self.root.bind("<Control-n>", lambda e: self._toolbar._on_new())
        self.root.bind("<Control-o>", lambda e: self._toolbar._on_open())
        self.root.bind("<Control-s>", lambda e: self._toolbar._on_save())
        self.root.bind("<Control-Shift-S>", lambda e: self._toolbar._on_save_as())

    def _update_title(self):
        fname = os.path.basename(self.state.current_file) if self.state.current_file else "Untitled"
        mod = " *" if self.state.modified else ""
        self.root.title(f"Tile Map Editor - {fname}{mod}")

    def run(self):
        self.root.mainloop()


def main():
    app = LevelEditorApp()
    app.run()


if __name__ == "__main__":
    main()
