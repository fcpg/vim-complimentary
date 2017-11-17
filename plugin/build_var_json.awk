BEGIN {
  RS = "\n[^\n]*[\t ]+[*][^\t ]+[*][\t ]*\n";
  FS = "\n";
  print "[";
}

RT ~ /\*v:var\*/ { varsect=1; }
!varsect { next; }

{ seen=0; }

oldrt ~ /\nv:/ {
  match(oldrt, /([^\n\t ]+)/, a);
  print "{\"word\": \"" a[1] "\",";
  seen=1;
} 

$1 ~ /^v:/ && !seen {
  match($1, /(v:\S+)/, a);
  print "{\"word\": \"" a[1] "\",";
  sub(/^v:\S+/,"",$1);
  seen=1;
} 

seen {
  fl=match($1, /^\s*$/) ? $2 : $1;
  gsub(/^\s*/, "", fl);
  gsub(/\s*$/, "", fl);
  gsub(/\s+(Only|See)\s*$/, "", fl);
  gsub(/"/, "\\\"", fl);
  gsub(/\s+/, " ", fl);
  print "\"kind\": \"v\",";
  printf("\"menu\": \"%s\",\n", fl);
  gsub(/"/, "\\\"");
  sub(/^\s+/, "");
  gsub(/\s+/, " ");
  gsub(/=*$/, "");
  printf("\"info\": \"%s\"\n", $0);
  print "},";
} 

{ oldrt=RT; }

END {
  print "]";
}

# vim: sw=2 ts=2