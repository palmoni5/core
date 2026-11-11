"""Build and run the Dart VM AOT benchmark from a checked-in Git snapshot."""

import argparse
import hashlib
import io
import json
import platform
import shutil
import subprocess
import tarfile
import tempfile
from pathlib import Path

BASE = "7f11cda89f00a7b04ce6d1e840138034005891c7"
HERE = Path(__file__).resolve().parent
PACKAGE = Path("pkgs/collection")
SOURCE = PACKAGE / "lib/src"
BASE_BLOBS = {
    "boollist.dart": "dc6bef929c823ed8a6ffa70663d3c91232c7060f",
    "queue_list.dart": "f92dbd22aa2c3e58b0f4f3d50f950e6f9314dcea",
}
VARIANTS = [
    ("boollist-original", "boollist.dart", "review_bool_original.dart",
     "a996328297e76f1e3bc00f570cdd715f6c450852",
     "e8fc744f22440e0e4a250018b982c693b66b1a06"),
    ("boollist-reviewed", "boollist.dart", "review_bool_reviewed.dart",
     "5831c688fb080fffa7e5c9f9f6860101549e4aec",
     "d8df395fd25f2101d6b58397b66bb65ff0b577a0"),
    ("queue-proposed", "queue_list.dart", "review_queue_proposed.dart",
     "107a63f520036d16e4d148cf2e86a96821d1ebfc",
     "11caf46667b12fbb10da70e974220c0f13700e50"),
]


def checked_read(path, expected):
    contents = path.read_bytes()
    header = f"blob {len(contents)}\0".encode()
    actual = hashlib.sha1(header + contents).hexdigest()
    if actual != expected:
        raise ValueError(f"{path.name}: expected Git blob {expected}, got {actual}")
    return contents


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, required=True)
    parser.add_argument("--dart", default="dart")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--offline", action="store_true")
    parser.add_argument("--cpu-model", default=platform.processor())
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    dart = args.dart
    if Path(dart).is_file():
        dart = str(Path(dart).resolve())
    archive = subprocess.check_output(
        ["git", "-c", "core.autocrlf=false", "-C", str(args.repo.resolve()),
         "archive", BASE, PACKAGE.as_posix()]
    )
    metadata = {
        "base_commit": BASE,
        "base_blobs": BASE_BLOBS,
        "variants": {
            name: {"commit": commit, "blob": blob}
            for name, _, _, commit, blob in VARIANTS
        },
        "dart": subprocess.check_output(
            [dart, "--version"], stderr=subprocess.STDOUT, text=True
        ).strip(),
        "machine": platform.machine(),
        "os": platform.system(),
        "cpu": args.cpu_model,
        "affinity": "Unpinned; ordinary local desktop load",
        "rounds_per_case": 11,
        "runs": [],
    }
    with tempfile.TemporaryDirectory(prefix="collection-aot-") as temporary:
        root = Path(temporary)
        with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
            tar.extractall(root, filter="data")
        source = root / SOURCE
        base_files = {
            "boollist.dart": "review_bool_before.dart",
            "queue_list.dart": "review_queue_before.dart",
        }
        baselines = {
            name: checked_read(source / name, BASE_BLOBS[name]) for name in base_files
        }
        for original, destination in base_files.items():
            (source / destination).write_bytes(baselines[original])
        for name, original, destination, _, blob in VARIANTS:
            patch = (HERE / f"{name}.patch").read_text(encoding="utf-8")
            subprocess.run(
                ["git", "-c", "core.autocrlf=false", "apply", "-"],
                input=patch.encode(), cwd=root, check=True,
            )
            (source / destination).write_bytes(checked_read(source / original, blob))
            (source / original).write_bytes(baselines[original])
        package = root / PACKAGE
        benchmark = Path("benchmark/collection_review_aot.dart")
        shutil.copyfile(HERE / "benchmark.dart", package / benchmark)
        pub_get = [dart, "pub", "get"]
        if args.offline:
            pub_get.append("--offline")
        subprocess.run(pub_get, cwd=package, check=True)
        executable_name = "benchmark.exe" if platform.system() == "Windows" else "benchmark.bin"
        exe = package / executable_name
        subprocess.run(
            [dart, "compile", "exe", str(benchmark), "-o", str(exe)],
            cwd=package,
            check=True,
        )
        for index, seed in enumerate((33, 57), start=1):
            result = subprocess.check_output([str(exe), str(seed)], text=True)
            lines = result.splitlines()
            if not lines[-1].startswith("# checksum="):
                raise ValueError("Missing checksum")
            filename = f"run{index}.csv"
            (args.output / filename).write_text(
                "\n".join(lines[:-1]) + "\n", encoding="utf-8", newline="\n"
            )
            metadata["runs"].append({
                "csv": filename, "seed": seed, "rows": len(lines) - 2,
                "checksum": int(lines[-1].split("=")[1]),
            })
    (args.output / "metadata.json").write_text(
        json.dumps(metadata, indent=2) + "\n", encoding="utf-8", newline="\n"
    )


if __name__ == "__main__":
    main()
