# build_func_json.awk
# Parse Vim doc/builtin.txt to create a JSON with builtin func info
# Author: fcpg

BEGIN {
  print "[";
  first=1;
}

/\*builtin-function-list\*/ { funcsect=1; next; }
!funcsect { next; }
funcsect && /\*\S+\*/ { funcsect=0; }

/^\S+\([^)]*\)/ || !funcsect {
  if (inprogress) {
    gsub(/\\/, "\\\\", data);
    gsub(/"/, "\\\"", data);
    printf("\"menu\": \"%s\",\n", data);
    printf("\"info\": \"%s %s\\n\\n%s\"\n", sig, ret, data);
    printf("}");
    word=sig=ret=data="";
    if (!funcsect) { nextfile; }
  }
  inprogress=1;
  match($0, /^((\S+)\([^)]*\))((\s+(\S+(\s+or\s+\S+)?))(\s+(.*))?)?$/, a);
  word=a[2];
  sig=a[1];
  ret=a[5];
  data=a[8];
  if (!first) {
    print ",";
  }
  else {
    first=0
  }
  print "{\"word\": \"" word (match(sig, /\(\)$/) ? "()" : "(") "\",";
  print "\"kind\": \"f\",";
  next;
} 

inprogress && /^\s+\S/ {
  gsub(/^\s+/, "");
  if (ret == "") {
    match($0, /^(\S+(\s+or\s+\S+)?)(\s+(.*)$)?/, a);
    ret=a[1];
    data=a[4];
    next;
  }
  if (index($0, "\t")) {
    gsub(/\t/, " => ")
    data=data " / " $0
  }
  else {
    data=data $0
  }
}

END {
  print "]";
}

# vim: sw=2 ts=2