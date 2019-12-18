# usage: awk [-Fsep] -f get_ip.awk reg_expr=string filename
BEGIN { IGNORECASE = 1 } 
{ if ( $0 ~ reg_expr ) {
    for (i=1; i<NF; i++) {
      if ($i ~ /rhost/ ) {
        print $++i
        break
      }
      if ( match($i,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/) > 0 ) {
        print substr($i,RSTART,RLENGTH) 
        break
      }
    }
  }
}
