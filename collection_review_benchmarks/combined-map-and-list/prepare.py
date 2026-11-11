"""Prepare a self-contained Dart benchmark workspace from exact Git objects."""

import argparse
import io
from pathlib import Path
import shutil
import subprocess
import zipfile

BASE = "7f11cda89f00a7b04ce6d1e840138034005891c7"
ZIP = "4a21cb32144644da4605d0274b3797e07c986073"
REVISIONS = {
    "original": {
        "pr18": "f12ee261c1a2102733f6b6a9a1ffdf6bee135778",
        "pr21": "f55122ea98ac87e3761dfc20cbdcc9dd4a967880",
    },
    "reviewed": {
        "pr18": "7cda5295d16777f5a71aa3167af769e7b05f6b2a",
        "pr21": "78ddf6bed8c6f1f4ce902d122f9fa4d4aec49aa2",
    },
}
LIB = "pkgs/collection/lib"
INPUTS = ("bench.dart", "prove18-mutation.dart", "prove21.dart", "prove24.dart")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo", type=Path, help="clone with the Otzaria/core objects")
    parser.add_argument("output", type=Path, help="a new output directory")
    parser.add_argument("--variant", choices=REVISIONS, default="reviewed")
    args = parser.parse_args()

    archives = {}
    revisions = {"base": BASE, "pr24": ZIP, **REVISIONS[args.variant]}
    for directory, revision in revisions.items():
        archives[directory] = subprocess.check_output(
            ["git", "-C", str(args.repo), "archive", "--format=zip", revision, LIB]
        )

    args.output.mkdir(parents=True)
    for directory, content in archives.items():
        with zipfile.ZipFile(io.BytesIO(content)) as archive:
            archive.extractall(args.output / directory)
        print(f"{directory}: {revisions[directory]}")
    for name in INPUTS:
        shutil.copyfile(Path(__file__).with_name(name), args.output / name)


if __name__ == "__main__":
    main()
