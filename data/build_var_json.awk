# build_var_json.awk
# Parse Vim doc/eval.txt to create a JSON with builtin var info
# Author: fcpg

BEGIN {
  # Split records on '*tags*'
  RS = "\n[^\n]*[\t ]+[*][^\t ]+[*][\t ]*\n";
  FS = "\n";
  print "[";
  first=1;
}

RT ~ /\*v:var\*/ { varsect=1; }
!varsect { next; }

{
  inprogress=0;
  varname="";
}

oldrt ~ /\nv:/ {
  # '*tag*' was on same line as var name
  match(oldrt, /([^\n\t ]+)/, a);
  varname=a[1];
  inprogress=1;
} 

$1 ~ /^v:/ && !inprogress {
  match($1, /(v:\S+)/, a);
  varname=a[1];
  sub(/^v:\S+/,"",$1);
  inprogress=1;
} 

varname {
  if (!first) {
    print ",";
  }
  else {
    first=0;
  }
  print "{\"word\": \"" a[1] "\",";
  varname="";
}

inprogress {
  firstline=match($1, /^\s*$/) ? $2 : $1;
  gsub(/^\s*/, "", firstline);
  gsub(/\s*$/, "", firstline);
  gsub(/\s+(Only|See)\s*$/, "", firstline);
  gsub(/"/, "\\\"", firstline);
  gsub(/\s+/, " ", firstline);
  print "\"kind\": \"v\",";
  printf("\"menu\": \"%s\",\n", firstline);
  gsub(/"/, "\\\"");
  sub(/^\s+/, "");
  gsub(/\s+/, " ");
  gsub(/=*$/, "");
  printf("\"info\": \"%s\"\n", $0);
  printf("}");
} 

{ oldrt=RT; }

END {
  print "]";
}

# vim: sw=2 ts=2