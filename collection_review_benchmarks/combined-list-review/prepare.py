from pathlib import Path
import subprocess as s
import sys
repo=Path(sys.argv[1])
p="pkgs/collection/lib/src/combined_wrappers/"
def read(ref,name):
    return s.check_output(["git","-C",str(repo),"show",ref+":"+p+name]).decode()
base=read("fa0c6b77","combined_list.dart")
full=read("60b51d26","combined_list.dart")
method="""  @override
  int indexOf(Object? element, [int start = 0]) {
    if (element is! T) return super.indexOf(element, start);
    if (start < 0) start = 0;
    var offset = 0;
    for (var list in _lists) {
      var length = list.length;
      if (length > start) {
        var index = list.indexOf(element, start);
        if (index >= 0) return offset + index;
        start = 0;
      } else {
        start -= length;
      }
      offset += length;
    }
    return -1;
  }

"""
for name, src in (("base",base),("full",full),("delegate",base.replace("  @override\n  set length",method+"  @override\n  set length",1))):
    d=Path(name);d.mkdir(exist_ok=True)
    (d/"combined_list.dart").write_text(src,encoding="utf8")
    (d/"combined_iterator.dart").write_text(read("fa0c6b77","combined_iterator.dart"),encoding="utf8")