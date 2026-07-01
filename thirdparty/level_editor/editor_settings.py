import tkinter as tk
from tkinter import ttk, messagebox


class EditorSettings(ttk.Frame):

    def __init__(self, parent, state, grid_widget, on_modified_callback=None):
        super().__init__(parent)
        self.state = state
        self.grid_widget = grid_widget
        self._on_modified = on_modified_callback

        ttk.Separator(self, orient="horizontal").pack(fill="x", pady=(2, 6))

        # ---- Tile Size ----
        row = ttk.Frame(self)
        row.pack(fill="x", padx=6, pady=1)
        ttk.Label(row, text="Tile Size:").pack(side="left")
        self._tile_size_var = tk.StringVar(value=str(self.state.tile_size))
        ttk.Entry(row, textvariable=self._tile_size_var, width=5).pack(side="right")
        self._tile_size_var.trace_add("write", lambda *a: self._on_tile_size_changed())

        # ---- Origin ----
        row2 = ttk.Frame(self)
        row2.pack(fill="x", padx=6, pady=1)
        ttk.Label(row2, text="Origin X:").pack(side="left")
        self._origin_x_var = tk.StringVar(value=str(self.state.origin_x))
        ttk.Entry(row2, textvariable=self._origin_x_var, width=5).pack(side="right")
        self._origin_x_var.trace_add("write", lambda *a: self._on_origin_changed())

        row2b = ttk.Frame(self)
        row2b.pack(fill="x", padx=6, pady=1)
        ttk.Label(row2b, text="Origin Y:").pack(side="left")
        self._origin_y_var = tk.StringVar(value=str(self.state.origin_y))
        ttk.Entry(row2b, textvariable=self._origin_y_var, width=5).pack(side="right")
        self._origin_y_var.trace_add("write", lambda *a: self._on_origin_changed())

        # ---- Grid dims ----
        row3 = ttk.Frame(self)
        row3.pack(fill="x", padx=6, pady=(6, 1))
        ttk.Label(row3, text="Grid W:").pack(side="left")
        self._grid_w_var = tk.StringVar(value=str(self.state.cols))
        ttk.Entry(row3, textvariable=self._grid_w_var, width=5).pack(side="right")

        row4 = ttk.Frame(self)
        row4.pack(fill="x", padx=6, pady=1)
        ttk.Label(row4, text="Grid H:").pack(side="left")
        self._grid_h_var = tk.StringVar(value=str(self.state.rows))
        ttk.Entry(row4, textvariable=self._grid_h_var, width=5).pack(side="right")

        ttk.Button(self, text="Resize", command=self._on_resize).pack(pady=2)

        # ---- Clear / Fill ----
        btns = ttk.Frame(self)
        btns.pack(fill="x", padx=6, pady=(6, 6))
        ttk.Button(btns, text="Clear", command=self._on_clear).pack(side="left", padx=2)
        ttk.Button(btns, text="Fill", command=self._on_fill).pack(side="left", padx=2)

        # ---- Start / End point display ----
        ttk.Separator(self, orient="horizontal").pack(fill="x", pady=(2, 6))

        row_sp = ttk.Frame(self)
        row_sp.pack(fill="x", padx=6, pady=1)
        ttk.Label(row_sp, text="起点 [col, row]:").pack(side="left")
        self._start_label = ttk.Label(row_sp, text="[0, 0]")
        self._start_label.pack(side="right")

        row_ep = ttk.Frame(self)
        row_ep.pack(fill="x", padx=6, pady=1)
        ttk.Label(row_ep, text="终点 [col, row]:").pack(side="left")
        self._end_label = ttk.Label(row_ep, text="[0, 0]")
        self._end_label.pack(side="right")

    def _on_tile_size_changed(self):
        try:
            val = int(self._tile_size_var.get())
            self.state.tile_size = val
        except ValueError:
            pass
        self._fire_modified()

    def _on_origin_changed(self):
        try:
            self.state.origin_x = int(self._origin_x_var.get())
            self.state.origin_y = int(self._origin_y_var.get())
        except ValueError:
            pass
        self._fire_modified()

    def _on_clear(self):
        if not messagebox.askyesno("Clear All", "Clear all tiles on the map?"):
            return
        self.state.clear_all()
        self.grid_widget.rebuild()
        self._fire_modified()

    def _on_fill(self):
        tile_id = self.state.selected_tile_id
        if tile_id == 0:
            messagebox.showinfo("Fill", "Select a tile in the palette first (tile 0 is empty/erase).")
            return
        name = self.state.tile_configs.get(tile_id, {}).get("display_name", str(tile_id))
        if not messagebox.askyesno("Fill All", f"Fill entire map with tile '{name}' (ID={tile_id})?"):
            return
        self.state.fill_all(tile_id)
        self.grid_widget.rebuild()
        self._fire_modified()

    def _on_resize(self):
        try:
            w = int(self._grid_w_var.get())
            h = int(self._grid_h_var.get())
            if w <= 0 or h <= 0:
                raise ValueError
            if w != self.state.cols or h != self.state.rows:
                self.state.resize_grid(h, w)
                self._refresh_controls()
                self.grid_widget.rebuild()
                self._fire_modified()
        except ValueError:
            self._grid_w_var.set(str(self.state.cols))
            self._grid_h_var.set(str(self.state.rows))

    def _refresh_controls(self):
        self._tile_size_var.set(str(self.state.tile_size))
        self._origin_x_var.set(str(self.state.origin_x))
        self._origin_y_var.set(str(self.state.origin_y))
        self._grid_w_var.set(str(self.state.cols))
        self._grid_h_var.set(str(self.state.rows))
        sp = self.state.start_point
        ep = self.state.end_point
        self._start_label.config(text=f"[{sp[0]}, {sp[1]}]")
        self._end_label.config(text=f"[{ep[0]}, {ep[1]}]")

    def _fire_modified(self):
        if self._on_modified:
            self._on_modified()
