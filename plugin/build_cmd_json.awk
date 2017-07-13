BEGIN {
  print "[";
}

/\*:index\*/ { cmdsect=1; next; }
!cmdsect { next; }
cmdsect && /\*\S+\*/ { cmdsect=0; }
ip && /^\s*$/ { cmdsect=0; }

/^\|\S+\|/ || !cmdsect {
  if (ip) {
    gsub(/"/, "\\\"", d);
    printf("\"menu\": \"%s\",\n", d);
    printf("\"info\": \"%s\",\n", d);
    print "},";
    w=d="";
    if (!cmdsect) { nextfile; }
  }
  ip=1;
  match($0, /^\|\S+\|\s+:(\S+)\s+(\S.*)$/, a);
  w=a[1];
  d=a[2];
  gsub(/[][]/, "", w);
  print "{\"word\": \"" w "\",";
  next;
} 

ip && /^\s+\S/ {
  gsub(/^\s+/, "");
  d=d $0
}

END {
  print "]";
}

# vim: sw=2 ts=2