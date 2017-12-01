# build_opt_json.awk
# Parse Vim doc/quickref.txt to create a JSON with opt info
# Author: fcpg

BEGIN {
  print "[";
  first=1;
}

/\*option-list\*/ { optsect=1; next; }
!optsect { next; }
optsect && /\*\S+\*/ { optsect=0; }
inprogress && /^\s*$/ { optsect=0; }

/^'\S+'/ || !optsect {
  if (inprogress) {
    gsub(/"/, "\\\"", data);
    gsub(/\t/, "  ", data);
    printf("\"menu\": \"%s\",\n", data);
    printf("\"info\": \"%s\"\n", data);
    printf("}");
    word=data="";
    if (!optsect) { nextfile; }
  }
  inprogress=1;
  match($0, /^'(\S+)'\s+(\S.*)$/, a);
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