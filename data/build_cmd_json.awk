# build_cmd_json.awk
# Parse Vim doc/index.txt to create a JSON with builtin cmd info
# Author: fcpg

BEGIN {
  print "[";
  first=1;
}

/\*:index\*/ { cmdsect=1; next; }
!cmdsect { next; }
cmdsect && /\*\S+\*/ { cmdsect=0; }
inprogress && /^\s*$/ { cmdsect=0; }

/^\|\S+\|/ || !cmdsect {
  if (inprogress) {
    gsub(/"/, "\\\"", data);
    printf("\"menu\": \"%s\",\n", data);
    printf("\"info\": \"%s\",\n", data);
    printf("}");
    word=data="";
    if (!cmdsect) { nextfile; }
  }
  inprogress=1;
  match($0, /^\|\S+\|\s+:(\S+)\s+(\S.*)$/, a);
  word=a[1];
  data=a[2];
  gsub(/[][]/, "", word);
  if (!first) {
    print ",";
  }
  else {
    first=0
  }
  print "{\"word\": \"" word "\",";
  next;
} 

inprogress && /^\s+\S/ {
  gsub(/^\s+/, "");
  data=data $0
}

END {
  print "]";
}

# vim: sw=2 ts=2