#!/usr/bin/env bats

setup() {
  cd "$BATS_TEST_DIRNAME"
  BATS_TMPDIR=/tmp/testdbl
  if [ ! -d $BATS_TMPDIR ] 
   then
    mkdir $BATS_TMPDIR
  fi
}

teardown() {
  true	# nop
  rm -rf $BATS_TMPDIR
}

@test "load config file readable" {
  BATS_TMPFILE="$BATS_TMPDIR/$$_dbl.cfg"
  echo "ABC=123" > $BATS_TMPFILE
  source ../bin/blacklist_mod
  run load_config $BATS_TMPFILE
  [ $status == 0 ] 
}

@test "load config file not readable" {
  source ../bin/blacklist_mod
  run load_config "notExistingFile"
  [[ "$output" =~ ^ERROR ]]
  [ $status == 1 ] 
}


@test "get firewall standard" {
  PID=$$
  TMPFILE="$BATS_TMPDIR/${PID}"
  
  source ../bin/blacklist_mod

  # stubbing ufw
  function ufw() {
    echo "Status: actief" 
    echo " "
    echo "Naar                       Actie       Van"
    echo "----                       -----       ---"
    echo "Anywhere                   DENY        210.212.203.67"
    echo "Anywhere                   DENY        123.207.241.223"
    echo "Anywhere                   DENY        69.245.220.97"
  }
  export -f ufw
 
  run get_firewall

  [ $status -eq 0 ]
  [ $(cat ${TMPFILE}_ufw | wc -l) -eq 3 ]
}

@test "get firewall error ufw" {
  PID=$$
  TMPFILE="$BATS_TMPDIR/${PID}"
  
  source ../bin/blacklist_mod
  # stubbing ufw
  function ufw() {
    return 1
  }
  export -f ufw
 
  run get_firewall

  [ $status -eq 1 ]
}

@test "get blacklist standard" {
  PID=$$
  TMPFILE="$BATS_TMPDIR/${PID}"
  BLACKLIST="$BATS_TMPDIR/${PID}_blacklist"
  echo "106.13.65.18 # 17 # authentication_failure: 2019-11-10 12:45:01" >>"$BLACKLIST"
  echo "119.29.15.120 # 17 # authentication_failure: 2019-11-10 13:00:01" >>"$BLACKLIST"
  echo "118.24.81.234 # 20 # authentication_failure: 2019-11-10 13:15:01" >>"$BLACKLIST"

  source ../bin/blacklist_mod
  run get_blacklist

  [ $(cat ${TMPFILE}_dbl | wc -l) -eq 3 ]
  [[ "$(tail -1 ${TMPFILE}_dbl)" =~ [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "get blacklist not readable" {
  PID=$$
  TMPFILE="$BATS_TMPDIR/${PID}"
  BLACKLIST="$BATS_TMPDIR/${PID}_blacklist"
  echo "106.13.65.18 # 17 # authentication_failure: 2019-11-10 12:45:01" >>"$BLACKLIST"
  echo "119.29.15.120 # 17 # authentication_failure: 2019-11-10 13:00:01" >>"$BLACKLIST"
  echo "118.24.81.234 # 20 # authentication_failure: 2019-11-10 13:15:01" >>"$BLACKLIST"
  chmod 000 $BLACKLIST

  source ../bin/blacklist_mod
  run get_blacklist

  [ $status -eq 1 ] 
}

@test "get blacklist not exisiting" {
  PID=$$
  TMPFILE="$BATS_TMPDIR/${PID}"
  BLACKLIST="$BATS_TMPDIR/${PID}_blacklist"

  source ../bin/blacklist_mod
  run get_blacklist

  [ $status -eq 0 ] 
  [ $(cat ${TMPFILE}_dbl | wc -l) -eq 0 ]
}

@test "update firewall standard" {
  PID=$$
  LOG="$BATS_TMPDIR/${PID}_log"
  LOCK="$BATS_TMPDIR/${PID}_lock"
  TMPFILE="$BATS_TMPDIR/${PID}"
  echo "1,3c1,3" >>${TMPFILE}_diff
  echo "< 69.245.220.97" >>${TMPFILE}_diff
  echo "< 123.207.241.223" >>${TMPFILE}_diff
  echo "< 210.212.203.67" >>${TMPFILE}_diff
  echo "---" >>${TMPFILE}_diff
  echo "> 106.13.65.18" >>${TMPFILE}_diff
  echo "> 118.24.81.234" >>${TMPFILE}_diff
  echo "> 119.29.15.120" >>${TMPFILE}_diff
  
  source ../bin/blacklist_mod

  # stubbing ufw
  function ufw() {
    case $1 in
      "insert") echo "Regel ingevoerd";;
      "delete") echo "Regel verwijderd";;
    esac
    return 0
  }
  export -f ufw
 
  run update_firewall

  [ $status -eq 0 ]
  [ $(grep -ci "inserted" $LOG) -eq 3 ]
  [ $(grep -ci "deleted" $LOG) -eq 3 ]
}


@test "update firewall locked" {
  PID=$$
  LOG="$BATS_TMPDIR/${PID}_log"
  LOCK="$BATS_TMPDIR/${PID}_lock"
  TMPFILE="$BATS_TMPDIR/${PID}"
  echo "1,3c1,3" >>${TMPFILE}_diff
  echo "< 69.245.220.97" >>${TMPFILE}_diff
  echo "< 123.207.241.223" >>${TMPFILE}_diff
  echo "< 210.212.203.67" >>${TMPFILE}_diff
  echo "---" >>${TMPFILE}_diff
  echo "> 106.13.65.18" >>${TMPFILE}_diff
  echo "> 118.24.81.234" >>${TMPFILE}_diff
  echo "> 119.29.15.120" >>${TMPFILE}_diff
  touch $LOCK	# create lock
  
  source ../bin/blacklist_mod

  # stubbing ufw
  function ufw() {
    case $1 in
      "insert") echo "Regel ingevoerd";;
      "delete") echo "Regel verwijderd";;
    esac
    return 0
  }
  export -f ufw
 
  run update_firewall

  [ $status -eq 1 ]
  [[ "$output" =~ WARNING ]]
}


@test "update firewall error ufw" {
  PID=$$
  LOG="$BATS_TMPDIR/${PID}_log"
  LOCK="$BATS_TMPDIR/${PID}_lock"
  TMPFILE="$BATS_TMPDIR/${PID}"
  echo "1,3c1,3" >>${TMPFILE}_diff
  echo "< 69.245.220.97" >>${TMPFILE}_diff
  echo "< 123.207.241.223" >>${TMPFILE}_diff
  echo "< 210.212.203.67" >>${TMPFILE}_diff
  echo "---" >>${TMPFILE}_diff
  echo "> 106.13.65.18" >>${TMPFILE}_diff
  echo "> 118.24.81.234" >>${TMPFILE}_diff
  echo "> 119.29.15.120" >>${TMPFILE}_diff
  
  source ../bin/blacklist_mod

  # stubbing ufw
  function ufw() {
    return 1
  }
  export -f ufw
 
  run update_firewall

  [ $(grep -c "ERROR[ ]*inserting" $LOG) -eq 3 ]
  [ $(grep -c "ERROR[ ]*deleting" $LOG) -eq 3 ]
}

@test "clean exit" {
  TMPFILE="$BATS_TMPDIR/$$_tmpfile"
  touch "$TMPFILE"

  source ../bin/blacklist_mod
  run clean_exit 9

  [ $status -eq 9 ] 
  [ ! -e $TMPFILE ]
}

@test "main without arguments" {
#skip
  source ../bin/blacklist_mod
  run main 
  [ $status -eq 1 ]
}

@test "main standard operation" {
#skip
  source ../bin/blacklist_mod

  function ufw() {
    case $1 in
      "insert") echo "Regel ingevoerd";;
      "delete") echo "Regel verwijderd";;
      "status") echo "Status: actief"
                echo " "
                echo "Naar                       Actie       Van"
                echo "----                       -----       ---"
                echo "Anywhere                   DENY        210.212.203.67"
                echo "Anywhere                   DENY        123.207.241.223"
                echo "Anywhere                   DENY        69.245.220.97" ;;
             *) return 1
    esac
    return 0
  }
  export -f ufw

  run main "${BATS_TEST_DIRNAME}/../cfg"
  #echo "# output: $output" >&3
  [ $status -eq 0 ]
}

