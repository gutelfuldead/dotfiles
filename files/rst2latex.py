#!/usr/bin/python
import docutils.core
import sys

if len(sys.argv) != 2:
    sys.exit("Usage : ./rst2latex.py <rst-file-name>")

orig=str(sys.argv[1])
newstr=sys.argv[1].rsplit('.',1)[0]
newstr=newstr+".tex"


print orig
print newstr

docutils.core.publish_file(
    source_path=orig,
    destination_path=newstr,
    writer_name="latex")
