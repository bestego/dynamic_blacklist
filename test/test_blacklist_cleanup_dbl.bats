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
  rm -rf $BATS_TMPDIR
}

@test "load config file readable" {
  BATS_TMPFILE="$BATS_TMPDIR/$$_dbl.cfg"
  echo "ABC=123" > $BATS_TMPFILE
  source ../blacklist_cleanup_dbl
  run load_config $BATS_TMPFILE
  [ $status == 0 ] 
}

@test "load config file not readable" {
  source ../blacklist_cleanup_dbl
  run load_config "notExistingFile"
  [[ "$output" =~ ^ERROR ]]
  [ $status == 1 ] 
}

@test "expiration date valid input" {
  source ../blacklist_cleanup_dbl
  run expiration_date 37
  [ $status -eq 0 ]
  [ ${#output} -ge 10 ]
  [[ "$output" =~ ^[0-9]+$ ]]
}

@test "expiration date non-numeric input" {
  source ../blacklist_cleanup_dbl
  run expiration_date 3a7
  [ $status -eq 1 ]
}

@test "expiration date missing input" {
  source ../blacklist_cleanup_dbl
  run expiration_date 
  [ $status -eq 1 ]
}

@test "update no expired line" {
  PID=$$
  BLACKLIST="$BATS_TMPDIR/${PID}_blacklist"
  dateTime=`date -d "now -37 days" "+%F %T"`
  expirationDate=`date -d "now -99 days" +%s`
  echo "111.222.333.444 # 3 # BATS: $dateTime" >> "$BLACKLIST"
  
  source ../blacklist_cleanup_dbl
  run update $expirationDate
  
  [ $status -eq 0 ]
  [ $(cat $BLACKLIST | wc -l) -eq 1 ]
  [ ! -e ${BLACKLIST}.old ]
}

@test "update expired line" {
  PID=$$
  BLACKLIST="$BATS_TMPDIR/${PID}_blacklist"
  dateTime=`date -d "now -37 days" "+%F %T"`
  expirationDate=`date -d "now -9 days" +%s`
  echo "111.222.333.444 # 3 # BATS: $dateTime" >> "$BLACKLIST"
  
  source ../blacklist_cleanup_dbl
  run update $expirationDate
  
  [ $status -eq 0 ]
  [ $(cat $BLACKLIST | wc -l) -eq 0 ]
  [ $(cat ${BLACKLIST}.old | wc -l) -eq 1 ]
}

@test "update missing input" {
  source ../blacklist_cleanup_dbl
  run update 

  [ $status -eq 1 ]
  [[ $output =~ ERROR.*missing ]]
}

@test "update non-numeric input" {
  source ../blacklist_cleanup_dbl
  run update 1a2

  [ $status -eq 1 ]
  [[ $output =~ ERROR.*invalid ]]
}

@test "update too short numberic input" {
  source ../blacklist_cleanup_dbl
  run update 123

  [ $status -eq 1 ]
  [[ $output =~ ERROR.*invalid ]]
}

@test "update blacklist not readable" {
  PID=$$
  BLACKLIST="$BATS_TMPDIR/${PID}_blacklist"
  touch "$BLACKLIST"		# create empty blacklist
  chmod 000 "$BLACKLIST"	# block blacklist for reading

  source ../blacklist_cleanup_dbl
  run update 1234567890		# param length >= 10

  [ $status -eq 1 ]
  [[ "$output" =~ ERROR.*not[\ ]+readable ]] 	# space must be escaped
}

@test "main without arguments" {
#skip
  source ../blacklist_cleanup_dbl
  run main 
  [ $status -eq 1 ]
}

@test "main standard operation" {
#skip
  source ../blacklist_cleanup_dbl
  run main "${BATS_TEST_DIRNAME}/../etc"
  [ $status -eq 0 ]
}

