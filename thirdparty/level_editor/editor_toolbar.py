import tkinter as tk
from tkinter import ttk, messagebox, filedialog, simpledialog
import os


class EditorToolbar(ttk.Frame):

    def __init__(self, parent, state, grid_widget, on_modified_callback=None):
        super().__init__(parent)
        self.state = state
        self.grid_widget = grid_widget
        self._on_modified = on_modified_callback
        self.settings_widget = None
        self.panel_widget = None

        ttk.Button(self, text="New", command=self._on_new).pack(side="left", padx=2)
        ttk.Button(self, text="Open", command=self._on_open).pack(side="left", padx=2)
        ttk.Button(self, text="Save", command=self._on_save).pack(side="left", padx=2)
        ttk.Button(self, text="Save As", command=self._on_save_as).pack(side="left", padx=2)

        ttk.Separator(self, orient="vertical").pack(side="left", fill="y", padx=8)

        ttk.Label(self, text="Map Name:").pack(side="left", padx=(0, 2))
        self._map_name_var = tk.StringVar(value="")
        ttk.Entry(self, textvariable=self._map_name_var, width=12).pack(side="left", padx=2)

    def _on_new(self):
        if self.state.modified:
            ok = messagebox.askyesno("Unsaved", "Discard current changes?")
            if not ok:
                return
        w = simpledialog.askinteger("New Map", "Width (columns):", minvalue=1, maxvalue=200, initialvalue=10)
        if w is None:
            return
        h = simpledialog.askinteger("New Map", "Height (rows):", minvalue=1, maxvalue=200, initialvalue=10)
        if h is None:
            return
        self.state.new_level(w, h)
        self._map_name_var.set("")
        if self.settings_widget:
            self.settings_widget._refresh_controls()
        if self.panel_widget:
            self.panel_widget.refresh_highlight()
        self.grid_widget.rebuild()
        self._fire_modified()

    def _on_open(self):
        if self.state.modified:
            ok = messagebox.askyesno("Unsaved", "Discard current changes?")
            if not ok:
                return
        path = filedialog.askopenfilename(
            initialdir=os.path.join(self.state.project_root, "data", "levels"),
            filetypes=[("JSON files", "*.json"), ("All files", "*.*")]
        )
        if not path:
            return
        if not self.state.load_level(path):
            messagebox.showerror("Error", f"Failed to load: {path}")
            return
        self._map_name_var.set("")
        if self.settings_widget:
            self.settings_widget._refresh_controls()
        if self.panel_widget:
            self.panel_widget.refresh_highlight()
        self.grid_widget.rebuild()
        self._fire_modified()

    def _on_save(self):
        name = self._map_name_var.get().strip()
        if not name:
            messagebox.showwarning("Map Name", "Map Name cannot be empty.")
            return
        if self.state.current_file:
            self.state.save_level(self.state.current_file)
            self.state.add_to_level_list(self.state.current_file, name)
            self._fire_modified()
        else:
            self._on_save_as()

    def _on_save_as(self):
        name = self._map_name_var.get().strip()
        if not name:
            messagebox.showwarning("Map Name", "Map Name cannot be empty. Enter a name before saving.")
            return

        initial = os.path.join(self.state.project_root, "data", "levels")
        path = filedialog.asksaveasfilename(
            initialdir=initial,
            defaultextension=".json",
            filetypes=[("JSON files", "*.json"), ("All files", "*.*")]
        )
        if not path:
            return

        self.state.save_level(path)
        self.state.add_to_level_list(path, name)
        self._fire_modified()

    def _fire_modified(self):
        if self._on_modified:
            self._on_modified()
