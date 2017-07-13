BEGIN {
  print "[";
}

/\*functions\*/ { funcsect=1; next; }
!funcsect { next; }
funcsect && /\*\S+\*/ { funcsect=0; }

/^\S+\([^)]*\)/ || !funcsect {
  if (ip) {
    gsub(/"/, "\\\"", d);
    printf("\"menu\": \"%s\",\n", d);
    print "},";
    w=s=r=d="";
    if (!funcsect) { nextfile; }
  }
  ip=1;
  match($0, /^((\S+)\([^)]*\))((\s+(\S+(\s+or\s+\S+)?))\s+(.*))?$/, a);
  w=a[2];
  s=a[1];
  r=a[5];
  d=a[7];
  print "{\"word\": \"" w (match(s, /\(\)$/) ? "()" : "(") "\",";
  print "\"kind\": \"f\",";
  if (r == "") { next; }
  printf("\"info\": \"%s %s\",\n", s, r);
  next;
} 

ip && /^\s+\S/ {
  gsub(/^\s+/, "");
  if (r == "") {
    match($0, /^(\S+(\s+or\s+\S+)?)(\s+(.*)$)?/, a);
    r=a[1];
    d=a[4];
    printf("\"info\": \"%s %s\",\n", s, r);
    next;
  }
  d=d $0
}

END {
  print "]";
}

# vim: sw=2 ts=2