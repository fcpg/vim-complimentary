BEGIN {
  print "[";
}

/\*option-list\*/ { optsect=1; next; }
!optsect { next; }
optsect && /\*\S+\*/ { optsect=0; }
ip && /^\s*$/ { optsect=0; }

/^'\S+'/ || !optsect {
  if (ip) {
    gsub(/"/, "\\\"", d);
    printf("\"menu\": \"%s\",\n", d);
    printf("\"info\": \"%s\",\n", d);
    print "},";
    w=d="";
    if (!optsect) { nextfile; }
  }
  ip=1;
  match($0, /^'(\S+)'\s+(\S.*)$/, a);
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