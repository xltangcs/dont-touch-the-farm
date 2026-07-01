import tkinter as tk
from tkinter import ttk
from PIL import Image, ImageDraw, ImageTk
import os

from path_utils import res_to_fs


class TilePalette(ttk.Frame):

    COLS = 3
    CELL = 52

    def __init__(self, parent, state):
        super().__init__(parent, width=180)
        self.state = state
        self.pack_propagate(False)

        self._images: dict[int, ImageTk.PhotoImage] = {}
        self._border_frames: dict[int, tk.Frame] = {}

        ttk.Label(self, text="Tile Palette", font=("", 10, "bold")).pack(pady=(6, 4))

        self._grid_frame = ttk.Frame(self)
        self._grid_frame.pack(fill="both", expand=True, padx=6)

    def build_palette(self) -> None:
        for widget in self._grid_frame.winfo_children():
            widget.destroy()
        self._images.clear()
        self._border_frames.clear()

        img_size = 40

        for idx, tid in enumerate(self.state.tile_ids):
            cfg = self.state.tile_configs.get(tid, {})
            row = idx // self.COLS
            col = idx % self.COLS

            frame = tk.Frame(self._grid_frame, bg="#d0d0d0", bd=2, relief="flat")
            frame.grid(row=row, column=col, padx=2, pady=2)
            self._border_frames[tid] = frame

            if tid == 0:
                img_tk = self._make_eraser_icon(img_size)
            else:
                img_tk = self._load_and_scale(cfg.get("texture", ""), img_size)
            self._images[tid] = img_tk

            lbl = ttk.Label(frame, image=self._images[tid],
                            text=cfg.get("display_name", str(tid)),
                            compound="top", font=("", 6), anchor="center")
            lbl.pack(padx=2, pady=1)
            lbl.bind("<Button-1>", lambda e, t=tid: self._on_select(t))

    def _make_eraser_icon(self, size: int) -> ImageTk.PhotoImage:
        img = Image.new("RGBA", (size, size), (255, 255, 255, 100))
        draw = ImageDraw.Draw(img)
        margin = 8
        draw.rectangle([margin, margin, size - margin, size - margin],
                       outline="red", width=2)
        draw.line([margin, margin, size - margin, size - margin], fill="red", width=2)
        draw.line([size - margin, margin, margin, size - margin], fill="red", width=2)
        return ImageTk.PhotoImage(img)

    def _load_and_scale(self, tex_path: str, size: int) -> ImageTk.PhotoImage:
        if not tex_path:
            return self._make_eraser_icon(size)
        fs_path = res_to_fs(tex_path, self.state.project_root)
        if not os.path.exists(fs_path):
            return self._make_eraser_icon(size)
        try:
            img = Image.open(fs_path).convert("RGBA")
            img = img.resize((size, size), Image.NEAREST)
            return ImageTk.PhotoImage(img)
        except Exception:
            return self._make_eraser_icon(size)

    def _on_select(self, tid: int) -> None:
        self.state.selected_tile_id = tid
        for _tid, frame in self._border_frames.items():
            if _tid == tid:
                frame.configure(bg="#4a90d9", relief="solid")
            else:
                frame.configure(bg="#d0d0d0", relief="flat")
