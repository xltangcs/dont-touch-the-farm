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
        self.grid_widget = None
        self.pack_propagate(False)

        self._images: dict[str, ImageTk.PhotoImage] = {}
        self._border_frames: dict[str, tk.Frame] = {}

        ttk.Label(self, text="Tile Palette", font=("", 10, "bold")).pack(pady=(6, 4))

        self._grid_frame = ttk.Frame(self)
        self._grid_frame.pack(fill="both", expand=True, padx=6)

    def build_palette(self) -> None:
        for widget in self._grid_frame.winfo_children():
            widget.destroy()
        self._images.clear()
        self._border_frames.clear()

        img_size = 40
        total_items = len(self.state.tile_ids)
        last_tile_row = (total_items - 1) // self.COLS if total_items > 0 else -1
        sep_row = last_tile_row + 1
        marker_row_start = sep_row + 1
        marker_row_end = sep_row + 2

        for idx, tid in enumerate(self.state.tile_ids):
            cfg = self.state.tile_configs.get(tid, {})
            row = idx // self.COLS
            col = idx % self.COLS

            frame = tk.Frame(self._grid_frame, bg="#d0d0d0", bd=2, relief="flat")
            frame.grid(row=row, column=col, padx=2, pady=2)
            key = str(tid)
            self._border_frames[key] = frame

            if tid == 0:
                img_tk = self._make_eraser_icon(img_size)
            else:
                img_tk = self._load_and_scale(cfg.get("texture", ""), img_size)
            self._images[key] = img_tk

            lbl = ttk.Label(frame, image=self._images[key],
                            text=cfg.get("display_name", str(tid)),
                            compound="top", font=("", 6), anchor="center")
            lbl.pack(padx=2, pady=1)
            lbl.bind("<Button-1>", lambda e, t=tid: self._on_select_tile(t))

        # ---- Start / End point buttons ----
        ttk.Separator(self._grid_frame, orient="horizontal").grid(
            row=sep_row, column=0, columnspan=self.COLS,
            sticky="ew", pady=(6, 4))

        # Start point
        start_frame = tk.Frame(self._grid_frame, bg="#d0d0d0", bd=2, relief="flat")
        start_frame.grid(row=marker_row_start, column=0, padx=2, pady=2)
        self._border_frames["start"] = start_frame

        start_img = self._load_marker_img("assets/animation/walk/wf_2.PNG", img_size)
        self._images["start"] = start_img
        start_lbl = ttk.Label(start_frame, image=self._images["start"],
                              text="起点", compound="top", font=("", 6), anchor="center")
        start_lbl.pack(padx=2, pady=1)
        start_lbl.bind("<Button-1>", lambda e: self._on_select_start())

        # End point
        end_frame = tk.Frame(self._grid_frame, bg="#d0d0d0", bd=2, relief="flat")
        end_frame.grid(row=marker_row_end, column=0, padx=2, pady=2)
        self._border_frames["end"] = end_frame

        end_img = self._load_marker_img("assets/scene/props/33.png", img_size)
        self._images["end"] = end_img
        end_lbl = ttk.Label(end_frame, image=self._images["end"],
                            text="终点", compound="top", font=("", 6), anchor="center")
        end_lbl.pack(padx=2, pady=1)
        end_lbl.bind("<Button-1>", lambda e: self._on_select_end())

    def _load_marker_img(self, rel_path: str, size: int) -> ImageTk.PhotoImage:
        fs_path = os.path.normpath(os.path.join(self.state.project_root, rel_path.replace("/", os.sep)))
        if not os.path.exists(fs_path):
            return self._make_eraser_icon(size)
        try:
            img = Image.open(fs_path).convert("RGBA")
            img = img.resize((size, size), Image.NEAREST)
            return ImageTk.PhotoImage(img)
        except Exception:
            return self._make_eraser_icon(size)

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

    def _clear_all_highlights(self):
        for frame in self._border_frames.values():
            frame.configure(bg="#d0d0d0", relief="flat")

    def _on_select_tile(self, tid: int) -> None:
        self.state.selected_tile_id = tid
        self.state.current_mode = "paint"
        self._clear_all_highlights()
        key = str(tid)
        if key in self._border_frames:
            self._border_frames[key].configure(bg="#4a90d9", relief="solid")
        if self.grid_widget:
            self.grid_widget.update_mode_hint()

    def _on_select_start(self) -> None:
        self.state.current_mode = "set_start"
        self._clear_all_highlights()
        if "start" in self._border_frames:
            self._border_frames["start"].configure(bg="#4a90d9", relief="solid")
        if self.grid_widget:
            self.grid_widget.update_mode_hint()

    def _on_select_end(self) -> None:
        self.state.current_mode = "set_end"
        self._clear_all_highlights()
        if "end" in self._border_frames:
            self._border_frames["end"].configure(bg="#4a90d9", relief="solid")
        if self.grid_widget:
            self.grid_widget.update_mode_hint()

    def refresh_highlight(self) -> None:
        self._clear_all_highlights()
        mode = self.state.current_mode
        if mode == "set_start" and "start" in self._border_frames:
            self._border_frames["start"].configure(bg="#4a90d9", relief="solid")
        elif mode == "set_end" and "end" in self._border_frames:
            self._border_frames["end"].configure(bg="#4a90d9", relief="solid")
        else:
            key = str(self.state.selected_tile_id)
            if key in self._border_frames:
                self._border_frames[key].configure(bg="#4a90d9", relief="solid")
