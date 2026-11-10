"""Prepare exact revisions and run the AOT comparison on one logical CPU."""
import argparse
import ctypes
import os
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parent
BASE = 'fa0c6b77d67b6837eb2891e251c40cdfbeab1f4d'
ORIGINAL = 'a58e083e5a97d0d2d3e0b78317c539cdb0ecab60'


def command(*args, cwd=ROOT):
    subprocess.run([str(a) for a in args], cwd=cwd, check=True)


def prepare():
    trees = ROOT / 'worktrees'
    trees.mkdir(exist_ok=True)
    for name, revision in [('baseline', BASE), ('original', ORIGINAL), ('generic', BASE)]:
        repo = trees / name
        if not repo.exists():
            command('git', 'clone', '--no-checkout', 'https://github.com/dart-lang/core.git', repo)
            if name == 'original':
                command('git', 'fetch', 'origin', 'refs/pull/1045/head', cwd=repo)
            command('git', 'checkout', '--detach', revision, cwd=repo)
            if name == 'generic':
                command('git', 'apply', ROOT / 'generic.patch', cwd=repo)
        actual = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo, text=True).strip()
        if actual != revision:
            raise RuntimeError(f'{name}: expected {revision}, got {actual}')
        expected = (ROOT / 'generic.patch').read_text(encoding='utf-8') if name == 'generic' else ''
        diff = subprocess.check_output(['git', 'diff', '--binary'], cwd=repo, text=True)
        if diff.replace('\r\n', '\n') != expected.replace('\r\n', '\n'):
            raise RuntimeError(f'{name}: unexpected source changes')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dart', default=shutil.which('dart'))
    parser.add_argument('--cpu', type=int, default=2)
    parser.add_argument('--output', default='new-results.csv')
    args = parser.parse_args()
    if not args.dart:
        parser.error('Dart SDK is required; use --dart /path/to/dart')
    prepare()
    binary = ROOT / ('benchmark.exe' if os.name == 'nt' else 'benchmark')
    command(args.dart, 'compile', 'exe', ROOT / 'benchmark.dart', '-o', binary)
    gate = ROOT / '.ready'
    gate.unlink(missing_ok=True)
    flags = subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
    with (ROOT / 'run.log').open('w') as log:
        process = subprocess.Popen([str(binary), args.output, str(gate)], cwd=ROOT,
                                   stdout=log, stderr=subprocess.STDOUT, creationflags=flags)
        try:
            if os.name == 'nt':
                kernel = ctypes.WinDLL('kernel32', use_last_error=True)
                kernel.SetProcessAffinityMask.argtypes = [ctypes.c_void_p, ctypes.c_size_t]
                kernel.SetPriorityClass.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
                if not kernel.SetProcessAffinityMask(int(process._handle), 1 << args.cpu):
                    raise ctypes.WinError(ctypes.get_last_error())
                if not kernel.SetPriorityClass(int(process._handle), 0x8000):
                    raise ctypes.WinError(ctypes.get_last_error())
            elif hasattr(os, 'sched_setaffinity'):
                os.sched_setaffinity(process.pid, {args.cpu})
            else:
                raise RuntimeError('Affinity requires Windows or Linux')
            gate.touch()
            if process.wait() != 0:
                raise RuntimeError('Benchmark failed; see run.log')
        finally:
            if process.poll() is None:
                process.terminate()
                process.wait()
            gate.unlink(missing_ok=True)
    command(sys.executable, ROOT / 'summarize.py', args.output, args.output + '.summary.csv')


if __name__ == '__main__':
    main()
