import json
import os


class EditorState:

    def __init__(self, project_root: str):
        self.project_root = project_root
        self.tile_configs: dict = {}
        self.tile_ids: list[int] = []
        self.grid: list[list[int]] = []
        self.selected_tile_id: int = 0
        self.tile_size: int = 100
        self.origin_x: int = 320
        self.origin_y: int = 240
        self.start_point: list[int] = [0, 0]
        self.end_point: list[int] = [0, 0]
        self.current_mode: str = "paint"
        self._current_file: str = ""
        self._modified: bool = False

    @property
    def current_file(self) -> str:
        return self._current_file

    @property
    def modified(self) -> bool:
        return self._modified

    @property
    def rows(self) -> int:
        return len(self.grid)

    @property
    def cols(self) -> int:
        return len(self.grid[0]) if self.grid else 0

    def load_tile_configs(self) -> None:
        config_path = os.path.join(self.project_root, "data", "tilemap_configs.json")
        with open(config_path, "r", encoding="utf-8") as f:
            raw = json.load(f)

        self.tile_configs.clear()
        self.tile_ids = []

        for id_str, entry in raw.items():
            tid = int(id_str)
            self.tile_configs[tid] = entry

        self.tile_ids = sorted(self.tile_configs.keys())
        if 0 not in self.tile_configs:
            self.tile_configs[0] = {"display_name": "Erase", "texture": ""}
            self.tile_ids.insert(0, 0)

    def new_level(self, width: int, height: int) -> None:
        self.grid = [[0] * width for _ in range(height)]
        self.tile_size = 100
        self.origin_x = max(width * self.tile_size // 2, 100)
        self.origin_y = max(height * self.tile_size // 2, 100)
        self.start_point = [0, 0]
        self.end_point = [0, 0]
        self.current_mode = "paint"
        self._current_file = ""
        self._modified = True

    def load_level(self, filepath: str) -> bool:
        if not os.path.exists(filepath):
            return False
        with open(filepath, "r", encoding="utf-8") as f:
            data = json.load(f)

        self.tile_size = data.get("tile_size", 100)
        origin = data.get("origin", [0, 0])
        self.origin_x = origin[0] if len(origin) >= 1 else 0
        self.origin_y = origin[1] if len(origin) >= 2 else 0

        sp = data.get("start_point", None)
        if sp and len(sp) >= 2:
            self.start_point = [int(sp[0]), int(sp[1])]
        else:
            self.start_point = [0, 0]

        ep = data.get("end_point", None)
        if ep and len(ep) >= 2:
            self.end_point = [int(ep[0]), int(ep[1])]
        else:
            self.end_point = [0, 0]

        self.current_mode = "paint"

        raw_grid = data.get("grid", [])
        if not raw_grid or not isinstance(raw_grid, list):
            self.grid = []
            return False

        self.grid = []
        for row in raw_grid:
            if isinstance(row, list):
                self.grid.append([int(c) for c in row])
            else:
                self.grid.append([int(row)])

        self._current_file = filepath
        self._modified = False
        return True

    def save_level(self, filepath: str) -> bool:
        data = {
            "tile_size": self.tile_size,
            "origin": [self.origin_x, self.origin_y],
            "start_point": self.start_point,
            "end_point": self.end_point,
            "grid": self.grid,
        }

        dirpath = os.path.dirname(filepath)
        if dirpath:
            os.makedirs(dirpath, exist_ok=True)

        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        self._current_file = filepath
        self._modified = False
        return True

    def add_to_level_list(self, filepath: str, name: str = "") -> None:
        from path_utils import to_res_path
        res = to_res_path(filepath, self.project_root)
        list_path = os.path.join(self.project_root, "data", "levels", "level_list.json")

        if os.path.exists(list_path):
            with open(list_path, "r", encoding="utf-8") as f:
                data = json.load(f)
        else:
            data = {"levels": []}

        levels: list = data.get("levels", [])
        normalized: list = []
        found = False

        for entry in levels:
            if isinstance(entry, dict):
                existing = entry.get("path", "")
                if existing == res:
                    found = True
                normalized.append({"path": existing or "", "name": entry.get("name", "")} if existing else entry)
            else:
                # legacy string format - normalize to object
                if entry == res:
                    found = True
                norm_name = os.path.splitext(os.path.basename(str(entry)))[0]
                normalized.append({"path": str(entry), "name": norm_name})

        if not found:
            if not name:
                name = os.path.splitext(os.path.basename(filepath))[0]
            normalized.append({"path": res, "name": name})
        data["levels"] = normalized

        with open(list_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

    def set_cell(self, row: int, col: int, tile_id: int) -> None:
        if 0 <= row < self.rows and 0 <= col < self.cols:
            self.grid[row][col] = tile_id
            self._modified = True

    def get_cell(self, row: int, col: int) -> int:
        if 0 <= row < self.rows and 0 <= col < self.cols:
            return self.grid[row][col]
        return -1

    def clear_all(self) -> None:
        for r in range(self.rows):
            for c in range(self.cols):
                self.grid[r][c] = 0
        self._modified = True

    def fill_all(self, tile_id: int) -> None:
        for r in range(self.rows):
            for c in range(self.cols):
                self.grid[r][c] = tile_id
        self._modified = True

    def resize_grid(self, new_rows: int, new_cols: int) -> None:
        new_grid = []
        for r in range(max(new_rows, self.rows)):
            if r < self.rows:
                old_row = self.grid[r]
                if new_cols > len(old_row):
                    new_row = list(old_row) + [0] * (new_cols - len(old_row))
                else:
                    new_row = old_row[:new_cols]
            else:
                new_row = [0] * new_cols
            if r < new_rows:
                new_grid.append(new_row)
        self.grid = new_grid
        self._modified = True

    def has_collision(self, tile_id: int) -> bool:
        cfg = self.tile_configs.get(tile_id, {})
        return bool(cfg.get("has_collision", False))

    def set_start_point(self, col: int, row: int) -> bool:
        if row < 0 or row >= self.rows or col < 0 or col >= self.cols:
            return False
        tile_id = self.grid[row][col]
        if self.has_collision(tile_id):
            return False
        self.start_point = [col, row]
        self.current_mode = "paint"
        self._modified = True
        return True

    def set_end_point(self, col: int, row: int) -> bool:
        if row < 0 or row >= self.rows or col < 0 or col >= self.cols:
            return False
        tile_id = self.grid[row][col]
        if self.has_collision(tile_id):
            return False
        self.end_point = [col, row]
        self.current_mode = "paint"
        self._modified = True
        return True
