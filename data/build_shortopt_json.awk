BEGIN {
  print "{";
}

/\*option-list\*/ { optsect=1; next; }
!optsect { next; }
optsect && /\*\S+\*/ { optsect=0; nextfile; }

match($0, /^'(\S+)'\s+'(\S+)'\s/, a) {
  l=a[1];
  s=a[2];
  printf("\"%s\": \"%s\",\n", l, s);
  next;
} 

END {
  print "}";
}

# vim: sw=2 ts=2