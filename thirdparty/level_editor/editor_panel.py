import tkinter as tk
from tkinter import ttk
from PIL import Image, ImageDraw, ImageTk
import os

from path_utils import res_to_fs
from editor_state import RAIN_BUTTON_TILE_ID


class TilePalette(ttk.Frame):

    COLS = 3
    CELL = 52

    def __init__(self, parent, state):
        super().__init__(parent, width=220)
        self.state = state
        self.grid_widget = None
        self.pack_propagate(False)

        self._images: dict[str, ImageTk.PhotoImage] = {}
        self._border_frames: dict[str, tk.Frame] = {}

        scroll_outer = ttk.Frame(self)
        scroll_outer.pack(side="top", fill="both", expand=True)

        self._scroll_canvas = tk.Canvas(scroll_outer, highlightthickness=0)
        self._scroll_bar = ttk.Scrollbar(
            scroll_outer, orient="vertical", command=self._scroll_canvas.yview)
        self._scroll_canvas.configure(yscrollcommand=self._scroll_bar.set)
        self._scroll_canvas.pack(side="left", fill="both", expand=True)
        self._scroll_bar.pack(side="right", fill="y")

        self._content_frame = ttk.Frame(self._scroll_canvas)
        self._scroll_window = self._scroll_canvas.create_window(
            (0, 0), window=self._content_frame, anchor="nw")
        self._content_frame.bind("<Configure>", self._on_content_configure)
        self._scroll_canvas.bind("<Configure>", self._on_canvas_configure)
        self._scroll_canvas.bind("<Enter>", self._bind_scroll_wheel)
        self._scroll_canvas.bind("<Leave>", self._unbind_scroll_wheel)

        ttk.Label(self._content_frame, text="Tile Palette",
                  font=("", 10, "bold")).pack(pady=(6, 4))

        self._grid_frame = ttk.Frame(self._content_frame)
        self._grid_frame.pack(fill="x", padx=6)

        ttk.Separator(self._content_frame, orient="horizontal").pack(fill="x", pady=(8, 4))
        ttk.Label(self._content_frame, text="Tools", font=("", 9, "bold")).pack(pady=(0, 4))

        self._tools_frame = ttk.Frame(self._content_frame)
        self._tools_frame.pack(fill="x", padx=6, pady=(0, 8))
        self._build_tools()

    def _on_content_configure(self, _event=None) -> None:
        self._scroll_canvas.configure(scrollregion=self._scroll_canvas.bbox("all"))

    def _on_canvas_configure(self, event) -> None:
        self._scroll_canvas.itemconfig(self._scroll_window, width=event.width)

    def _bind_scroll_wheel(self, _event=None) -> None:
        self._scroll_canvas.bind_all("<MouseWheel>", self._on_scroll_wheel)

    def _unbind_scroll_wheel(self, _event=None) -> None:
        self._scroll_canvas.unbind_all("<MouseWheel>")

    def _on_scroll_wheel(self, event) -> None:
        self._scroll_canvas.yview_scroll(int(-event.delta / 120), "units")

    def _build_tools(self) -> None:
        for widget in self._tools_frame.winfo_children():
            widget.destroy()

        img_size = 40
        tools = [
            ("start", "起点", "assets/animation/walk/wf_2.PNG", self._on_select_start),
            ("end", "终点", "assets/scene/props/33.png", self._on_select_end),
            ("rain_zone", "雨区", "res://assets/environment/tileset/rain.png", self._on_select_rain_zone),
            ("rain_button", "停雨按钮", "res://assets/environment/tileset/rain_key.png", self._on_select_rain_button),
        ]

        for idx, (key, label, tex_path, handler) in enumerate(tools):
            row = idx // 2
            col = idx % 2

            frame = tk.Frame(self._tools_frame, bg="#d0d0d0", bd=2, relief="flat")
            frame.grid(row=row, column=col, padx=2, pady=2, sticky="nsew")
            self._border_frames[key] = frame

            if tex_path:
                img_tk = self._load_and_scale(tex_path, img_size)
            else:
                img_tk = self._make_eraser_icon(img_size)
            self._images[key] = img_tk

            lbl = ttk.Label(frame, image=self._images[key],
                            text=label, compound="top", font=("", 6), anchor="center")
            lbl.pack(padx=2, pady=1)
            lbl.bind("<Button-1>", lambda e, h=handler: h())

        self._tools_frame.grid_columnconfigure(0, weight=1)
        self._tools_frame.grid_columnconfigure(1, weight=1)

    def build_palette(self) -> None:
        tool_keys = {"start", "end", "rain_zone", "rain_button"}
        saved_frames = {k: v for k, v in self._border_frames.items() if k in tool_keys}
        saved_images = {k: v for k, v in self._images.items() if k in tool_keys}
        self._border_frames = saved_frames
        self._images = saved_images

        for widget in self._grid_frame.winfo_children():
            widget.destroy()

        img_size = 40
        palette_tiles = [tid for tid in self.state.tile_ids if tid != RAIN_BUTTON_TILE_ID]
        for idx, tid in enumerate(palette_tiles):
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

        self._on_content_configure()
        self.refresh_highlight()

    def _make_button_icon(self, size: int) -> ImageTk.PhotoImage:
        img = Image.new("RGBA", (size, size), (80, 120, 200, 220))
        draw = ImageDraw.Draw(img)
        margin = 6
        draw.rectangle([margin, margin, size - margin, size - margin],
                       outline="white", width=2)
        return ImageTk.PhotoImage(img)

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

    def _clear_all_highlights(self) -> None:
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

    def _on_select_rain_zone(self) -> None:
        self.state.current_mode = "paint_rain"
        self._clear_all_highlights()
        if "rain_zone" in self._border_frames:
            self._border_frames["rain_zone"].configure(bg="#4a90d9", relief="solid")
        if self.grid_widget:
            self.grid_widget.update_mode_hint()

    def _on_select_rain_button(self) -> None:
        self.state.current_mode = "set_rain_button"
        self._clear_all_highlights()
        if "rain_button" in self._border_frames:
            self._border_frames["rain_button"].configure(bg="#4a90d9", relief="solid")
        if self.grid_widget:
            self.grid_widget.update_mode_hint()

    def refresh_highlight(self) -> None:
        self._clear_all_highlights()
        mode = self.state.current_mode
        if mode == "set_start" and "start" in self._border_frames:
            self._border_frames["start"].configure(bg="#4a90d9", relief="solid")
        elif mode == "set_end" and "end" in self._border_frames:
            self._border_frames["end"].configure(bg="#4a90d9", relief="solid")
        elif mode == "paint_rain" and "rain_zone" in self._border_frames:
            self._border_frames["rain_zone"].configure(bg="#4a90d9", relief="solid")
        elif mode == "set_rain_button" and "rain_button" in self._border_frames:
            self._border_frames["rain_button"].configure(bg="#4a90d9", relief="solid")
        else:
            key = str(self.state.selected_tile_id)
            if key in self._border_frames:
                self._border_frames[key].configure(bg="#4a90d9", relief="solid")
