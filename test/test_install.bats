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

@test "get input no/default value" {

  INSTALL_DIR="/usr/local/bin"
  source ../install.sh
  run get_input "prompt" "$INSTALL_DIR" <<< ''

  #echo "# output: $output" >&3
  [ "$output" == "$INSTALL_DIR" ] 
}

@test "get input new value" {

  INSTALL_DIR="/usr/local/bin"
  EXPECTED="/tmp/newdir"
  source ../install.sh
  run get_input "prompt" "$INSTALL_DIR" <<< "$EXPECTED"

  #echo "# output: $output" >&3
  [ "$output" == "$EXPECTED" ] 
}

@test "main invalid user" {
  INPUTS=$BATS_TMPDIR/$$_inputs
  echo "$BATS_TMPDIR/bin" >>$INPUTS
  echo "$BATS_TMPDIR/etc" >>$INPUTS

  source ../install.sh
  run main <$INPUTS

  [ $status -eq 1 ] 
}

@test "main user root" {
  INPUTS=$BATS_TMPDIR/$$_inputs
  echo "$BATS_TMPDIR/bin" >>$INPUTS
  echo "$BATS_TMPDIR/etc" >>$INPUTS
  BATS_USER="root"	# fake user

  source ../install.sh
  run main <$INPUTS

  #echo "# status,output: $status,$output" >&3
  [ $status -eq 0 ] 
  [ $(ls "$BATS_TMPDIR/bin" | wc -w) -gt 1 ]
  [ -e "$BATS_TMPDIR/etc/dbl.cfg" ]
  [ -e "$BATS_TMPDIR/etc/dbl.d" ]
}
