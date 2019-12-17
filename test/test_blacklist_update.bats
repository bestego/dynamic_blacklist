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
  true
  rm -rf $BATS_TMPDIR
}

@test "load config file readable" {
  BATS_TMPFILE="$BATS_TMPDIR/$$_dbl.cfg"
  echo "ABC=123" > $BATS_TMPFILE
  source ../blacklist_update
  run load_config $BATS_TMPFILE
  [ $status == 0 ] 
}

@test "load config file not readable" {
  source ../blacklist_update
  run load_config "notExistingFile"
  [[ "$output" =~ ^ERROR ]]
  [ $status == 1 ] 
}

@test "load whitelist readable" {
  BATS_TMPFILE="$BATS_TMPDIR/$$_whitelist"
  echo "111.222.333.444" > $BATS_TMPFILE
  source ../blacklist_update
  run load_whitelist $BATS_TMPFILE
  [ $status == 0 ]
}

@test "load whitelist empty" {
  BATS_TMPFILE="$BATS_TMPDIR/$$_whitelist"
  # valid entry with embedded spaces tabs and trailing comment
  touch $BATS_TMPFILE
  source ../blacklist_update
  run load_whitelist "$BATS_TMPFILE"
  [ ${#output} -eq 0 ]
}

@test "load whitelist valid address" {
  BATS_TMPFILE="$BATS_TMPDIR/$$_whitelist"
  # valid entry with embedded spaces tabs and trailing comment
  echo "	 111.222.333.444	 # comment" >$BATS_TMPFILE
  source ../blacklist_update
  run load_whitelist "$BATS_TMPFILE"
  [ $status == 0 ]
  [ "$output" == "111\.222\.333\.444" ]
}

@test "load whitelist valid segment" {
  BATS_TMPFILE="$BATS_TMPDIR/$$_whitelist"
  echo "111.222.333" >$BATS_TMPFILE
  source ../blacklist_update
  run load_whitelist "$BATS_TMPFILE"
  rm -f $BATS_TMPFILE
  [ $status == 0 ]
  [ "$output" == "111\.222\.333" ]
}

@test "load whitelist ignore too short address " {
  BATS_TMPFILE="$BATS_TMPDIR/$$_whitelist"
  echo "111.222" >$BATS_TMPFILE
  source ../blacklist_update
  run load_whitelist "$BATS_TMPFILE"
  rm -f $BATS_TMPFILE
  [ $status == 0 ]
  [ ${#output} -eq 0 ]
}

@test "load whitelist ignore comment lines" {
  BATS_TMPFILE="$BATS_TMPDIR/$$_whitelist"
  # comment lines with leading spaces tabs
  echo "	 # comment " >$BATS_TMPFILE
  source ../blacklist_update
  run load_whitelist "$BATS_TMPFILE"
  rm -f $BATS_TMPFILE
  [ $status == 0 ]
  [ ${#output} -eq 0 ]
}

@test "load whitelist not exisiting" {
  source ../blacklist_update
  run load_whitelist 
  [ ${#output} -eq 0 ]
}

@test "whitelisted missing argument" {
  source ../blacklist_update
  run is_whitelisted
  [[ "$output" =~ ^ERROR ]]
  [ $status == 1 ]
}

@test "whitelisted address match" {
  source ../blacklist_update
  whitelist="999\.888\.777\.666 111\.222\.333\.444"
  run is_whitelisted "111.222.333.444"
  [ $status == 0 ]
}

@test "whitelisted address nomatch" {
  source ../blacklist_update
  whitelist="999\.888\.777\.666 111\.222\.333\.444"
  run is_whitelisted "111.222.33.444"
  [ $status == 1 ]
}

@test "whitelisted domain match" {
  source ../blacklist_update
  whitelist="999\.888\.777\.666 111\.222\.333"
  run is_whitelisted "111.222.333.444"
  [ $status == 0 ]
}

@test "whitelisted domain nomatch" {
  source ../blacklist_update
  whitelist="999\.888\.777\.666 111\.222\.333"
  run is_whitelisted "111.222.33.444"
  [ $status == 1 ]
}

@test "update non-whitelisted entry above limit existing blacklist" {
  PID=$$
  # create analysis script
  BATS_TMPFILE="$BATS_TMPDIR/${PID}_analysis.sh"
  echo "ANALYSIS=BATS" >>$BATS_TMPFILE
  echo "LIMIT=2" >>$BATS_TMPFILE
  echo "echo 111.222.333.444" >>$BATS_TMPFILE
  echo "echo 111.222.333.444" >>$BATS_TMPFILE
  echo "echo 111.222.333.444" >>$BATS_TMPFILE
  SCRIPTS="$BATS_TMPDIR/${PID}_*.sh"

  source ../blacklist_update
  BLACKLIST="$BATS_TMPDIR/${PID}_blacklist"
  touch $BLACKLIST	# create empty file
  run update
  run cat $BLACKLIST
  [[ "$output" =~ 111.222.333.444 ]] 
}

@test "update non-whitelisted entry above limit missing blacklist" {
  PID=$$
  # create analysis script
  BATS_TMPFILE="$BATS_TMPDIR/${PID}_analysis.sh"
  echo "ANALYSIS=BATS" >>$BATS_TMPFILE
  echo "LIMIT=2" >>$BATS_TMPFILE
  echo "echo 111.222.333.444" >>$BATS_TMPFILE
  echo "echo 111.222.333.444" >>$BATS_TMPFILE
  echo "echo 111.222.333.444" >>$BATS_TMPFILE
  SCRIPTS="$BATS_TMPDIR/${PID}_*.sh"

  source ../blacklist_update
  BLACKLIST="$BATS_TMPDIR/${PID}_blacklist"
  run update
  run cat $BLACKLIST
  [[ "$output" =~ 111.222.333.444 ]] 
}


@test "update blacklist not readable" {
  source ../blacklist_update

  PID=$$
  BLACKLIST="$BATS_TMPDIR/${PID}_blacklist"
  touch "$BLACKLIST"		# create empty blacklist
  chmod 000 "$BLACKLIST"		# block blacklist for reading
  run update
  [[ "$output" =~ ^ERROR.*not[\ ]+readable ]] 	# space must be escaped
  [ $status -eq 1 ]
}

@test "update blacklist directory not writable" {
  source ../blacklist_update

  PID=$$
  BLOCKED_DIR="$BATS_TMPDIR/blocked_dir"
  mkdir "$BLOCKED_DIR"
  chmod a=r "$BLOCKED_DIR"	# block directory for writing
  BLACKLIST="$BLOCKED_DIR/${PID}_blacklist"
  run update
  [[ "$output" =~ ^ERROR.*not[\ ]+writable ]] # space must be escaped
  [ $status -eq 1 ]
}

@test "update whitelisted entry above limit" {
  PID=$$
  # create analysis script
  BATS_TMPFILE="$BATS_TMPDIR/${PID}_analysis.sh"
  echo "ANALYSIS=BATS" >>$BATS_TMPFILE
  echo "LIMIT=2" >>$BATS_TMPFILE
  echo "echo 111.222.333.444" >>$BATS_TMPFILE
  echo "echo 111.222.333.444" >>$BATS_TMPFILE
  echo "echo 111.222.333.444" >>$BATS_TMPFILE
  SCRIPTS="$BATS_TMPDIR/${PID}_*.sh"

  source ../blacklist_update
  BLACKLIST="$BATS_TMPDIR/${PID}_blacklist"
  whitelist="999\.888\.777 111\.222\.333 444\.555\.666"
  run update
  [ $(cat $BLACKLIST | wc -l) -eq 0 ]
}

@test "update entry below limit" {
  PID=$$
  # create analysis SCRIPT
  BATS_TMPFILE="$BATS_TMPDIR/${PID}_analysis.sh"
  echo "ANALYSIS=BATS" >>$BATS_TMPFILE
  echo "LIMIT=4" >>$BATS_TMPFILE
  echo "echo 111.222.333.444" >>$BATS_TMPFILE
  echo "echo 111.222.333.444" >>$BATS_TMPFILE
  echo "echo 111.222.333.444" >>$BATS_TMPFILE
  SCRIPTS="$BATS_TMPDIR/${PID}_*.sh"

  source ../blacklist_update
  BLACKLIST="$BATS_TMPDIR/${PID}_blacklist"
  run update
  [ $(cat $BLACKLIST | wc -l)  -eq 0 ] 
}

@test "main without arguments" {
skip
  source ../blacklist_update
  run main 
  [ $status -eq 1 ]
}

@test "main standard operation" {
skip
  source ../blacklist_update
  run main .
  [ $status -eq 0 ]
}

