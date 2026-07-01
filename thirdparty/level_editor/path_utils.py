import os

def get_project_root() -> str:
    script_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.normpath(os.path.join(script_dir, "..", ".."))


def res_to_fs(res_path: str, project_root: str) -> str:
    stripped = res_path.replace("res://", "", 1)
    if stripped == res_path:
        return res_path
    return os.path.normpath(os.path.join(project_root, stripped.replace("/", os.sep)))


def to_res_path(fs_path: str, project_root: str) -> str:
    rel = os.path.relpath(fs_path, project_root)
    return "res://" + rel.replace("\\", "/")
