import tkinter as tk
from PIL import Image, ImageTk
import os

from path_utils import res_to_fs


CELL_SIZE = 48
MIN_CELL_SIZE = 16
MAX_CELL_SIZE = 128
ZOOM_STEP = 8


class TileGrid(tk.Frame):

    def __init__(self, parent, state):
        super().__init__(parent)
        self.state = state
        self._tile_cache: dict[int, ImageTk.PhotoImage] = {}
        self._cell_size = CELL_SIZE
        self._drag_painting = False
        self._last_painted_cell = (-1, -1)
        self._space_pressed = False
        self._panning = False

        self._h_scroll = tk.Scrollbar(self, orient="horizontal")
        self._v_scroll = tk.Scrollbar(self, orient="vertical")
        self._canvas = tk.Canvas(self, bg="#3a3a3a",
                                 xscrollcommand=self._h_scroll.set,
                                 yscrollcommand=self._v_scroll.set)
        self._h_scroll.config(command=self._canvas.xview)
        self._v_scroll.config(command=self._canvas.yview)

        self._canvas.grid(row=0, column=0, sticky="nsew")
        self._v_scroll.grid(row=0, column=1, sticky="ns")
        self._h_scroll.grid(row=1, column=0, sticky="ew")
        self.grid_rowconfigure(0, weight=1)
        self.grid_columnconfigure(0, weight=1)

        self._hint_label = tk.Label(self, text="Scroll: Zoom  |  Space+Drag: Pan",
                                    bg="#222222", fg="#aaaaaa", font=("", 8),
                                    padx=6, pady=2)
        self._hint_label.place(relx=0, rely=0, anchor="nw", x=4, y=4)

        self._bind_events()

    def _bind_events(self):
        self._canvas.bind("<Enter>", lambda e: self._canvas.focus_set())
        self._canvas.bind("<Button-1>", self._on_left_down)
        self._canvas.bind("<B1-Motion>", self._on_left_drag)
        self._canvas.bind("<ButtonRelease-1>", self._on_left_up)
        self._canvas.bind("<Button-3>", self._on_right_click)
        self._canvas.bind("<MouseWheel>", self._on_mousewheel)

        self._canvas.bind("<KeyPress-space>", self._on_space_down)
        self._canvas.bind("<KeyRelease-space>", self._on_space_up)

    def _on_space_down(self, event):
        self._space_pressed = True

    def _on_space_up(self, event):
        self._space_pressed = False

    def _on_left_down(self, event):
        if self._space_pressed:
            self._panning = True
            self._canvas.scan_mark(event.x, event.y)
            return
        self._drag_painting = True
        self._last_painted_cell = (-1, -1)
        self._paint_at(self._canvas.canvasx(event.x), self._canvas.canvasy(event.y))

    def _on_left_drag(self, event):
        if self._panning:
            self._canvas.scan_dragto(event.x, event.y, gain=1)
            return
        if self._drag_painting:
            self._paint_at(self._canvas.canvasx(event.x), self._canvas.canvasy(event.y))

    def _on_left_up(self, event):
        self._drag_painting = False
        self._panning = False

    def _on_right_click(self, event):
        x = self._canvas.canvasx(event.x)
        y = self._canvas.canvasy(event.y)
        row, col = self._xy_to_cell(x, y)
        if row < 0 or col < 0:
            return
        self.state.set_cell(row, col, 0)
        self._redraw_cell(row, col)

    def _on_mousewheel(self, event):
        delta = ZOOM_STEP if event.delta > 0 else -ZOOM_STEP
        new_size = self._cell_size + delta
        new_size = max(MIN_CELL_SIZE, min(MAX_CELL_SIZE, new_size))
        if new_size != self._cell_size:
            self._cell_size = new_size
            self._tile_cache.clear()
            self.rebuild()

    def _paint_at(self, x, y):
        row, col = self._xy_to_cell(x, y)
        if row < 0 or col < 0:
            return
        if (row, col) == self._last_painted_cell:
            return
        self._last_painted_cell = (row, col)
        self.state.set_cell(row, col, self.state.selected_tile_id)
        self._redraw_cell(row, col)

    def _xy_to_cell(self, x, y):
        col = int(x // self._cell_size)
        row = int(y // self._cell_size)
        rows = self.state.rows
        cols = self.state.cols
        if 0 <= row < rows and 0 <= col < cols:
            return row, col
        return -1, -1

    def rebuild(self) -> None:
        self._canvas.delete("all")
        self._tile_cache.clear()
        rows = self.state.rows
        cols = self.state.cols
        sz = self._cell_size

        scroll_w = cols * sz + 2
        scroll_h = rows * sz + 2
        self._canvas.configure(scrollregion=(0, 0, scroll_w, scroll_h))

        for r in range(rows + 1):
            y = r * sz
            self._canvas.create_line(0, y, cols * sz, y, fill="#555555", width=1)

        for c in range(cols + 1):
            x = c * sz
            self._canvas.create_line(x, 0, x, rows * sz, fill="#555555", width=1)

        for r in range(rows):
            for c in range(cols):
                self._draw_cell(r, c)

    def _draw_cell(self, row, col):
        tid = self.state.get_cell(row, col)
        sz = self._cell_size
        x = col * sz
        y = row * sz

        tag = f"cell_{row}_{col}"
        self._canvas.delete(tag)

        if tid != 0:
            img_tk = self._get_tile_image(tid)
            if img_tk:
                self._canvas.create_image(x + 1, y + 1, anchor="nw", image=img_tk, tag=tag)
        else:
            self._canvas.create_rectangle(x + 1, y + 1, x + sz, y + sz,
                                          fill="#2a2a2a", outline="", tag=tag)

    def _redraw_cell(self, row, col):
        sz = self._cell_size
        x = col * sz
        y = row * sz
        tag = f"cell_{row}_{col}"
        self._canvas.delete(tag)

        tid = self.state.get_cell(row, col)
        if tid == 0:
            self._canvas.create_rectangle(x + 1, y + 1, x + sz, y + sz,
                                          fill="#2a2a2a", outline="", tag=tag)
        else:
            img_tk = self._get_tile_image(tid)
            if img_tk:
                self._canvas.create_image(x + 1, y + 1, anchor="nw", image=img_tk, tag=tag)

    def _get_tile_image(self, tid: int) -> ImageTk.PhotoImage | None:
        if tid in self._tile_cache:
            return self._tile_cache[tid]

        cfg = self.state.tile_configs.get(tid, {})
        tex_path = cfg.get("texture", "")
        if not tex_path:
            self._tile_cache[tid] = None
            return None

        fs_path = res_to_fs(tex_path, self.state.project_root)
        if not os.path.exists(fs_path):
            self._tile_cache[tid] = None
            return None

        try:
            img = Image.open(fs_path).convert("RGBA")
            img = img.resize((self._cell_size - 2, self._cell_size - 2), Image.NEAREST)
            photo = ImageTk.PhotoImage(img)
            self._tile_cache[tid] = photo
            return photo
        except Exception:
            self._tile_cache[tid] = None
            return None
