# build_shortopt_json.awk
# Parse Vim doc/quickref.txt to create a JSON with opt info
# Author: fcpg

BEGIN {
  print "{";
  first=1;
}

/\*option-list\*/ { optsect=1; next; }
!optsect { next; }
optsect && /\*\S+\*/ { optsect=0; nextfile; }

match($0, /^'(\S+)'\s+'(\S+)'\s/, a) {
  long=a[1];
  short=a[2];
  if (!first) {
    print ",";
  }
  else {
    printf("\n");
    first=0
  }
  printf("\"%s\": \"%s\"", long, short);
  next;
} 

END {
  print "}";
}

# vim: sw=2 ts=2