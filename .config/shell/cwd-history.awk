# Ranks the cwd-history log into tiers. Read by cwd-history.zsh, and re-run
# directly by fzf's reload bindings when you narrow the scope, which is why it
# lives in its own file instead of inline in the module.
#
#   -v P    current directory
#   -v R    git toplevel, empty when not in a repo
#   -v T    highest tier to emit (0 here, 1 below, 2 repo, 3 everything)
#
# Output is NUL-separated records of "<colored gutter>\t<command>".

BEGIN {
  FS = "\t"
  if (T == "") T = 3
  E = sprintf("%c[", 27)
  MARK[0] = E "48;5;35m"  " " E "0m"   # this directory
  MARK[1] = E "48;5;39m"  " " E "0m"   # below it
  MARK[2] = E "48;5;178m" " " E "0m"   # rest of the repo
  MARK[3] = E "48;5;240m" " " E "0m"   # everywhere else
}

{
  n++
  d[n] = $1
  c[n] = substr($0, index($0, "\t") + 1)
}

END {
  for (t = 0; t <= T; t++)
    for (i = n; i >= 1; i--) {
      if (t == 0)      ok = (d[i] == P)
      else if (t == 1) ok = (index(d[i], P "/") == 1)
      else if (t == 2) ok = (R != "" && (d[i] == R || index(d[i], R "/") == 1))
      else             ok = 1
      if (!ok) continue
      if (seen[c[i]]++) continue
      s = c[i]
      gsub(NL, "\n", s)
      gsub(TB, "\t", s)
      printf "%s \t%s%c", MARK[t], s, 0
    }
}
