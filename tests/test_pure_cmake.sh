#!/bin/bash
# vim: dict+=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# shellcheck disable=all
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
  rlPhaseStartSetup
    rlRun "tmp=\$(mktemp -d)" 0 "Create tmp directory"
    rlRun "root=\$(pwd)" 0 "Save the tmt root path"
    rlRun "pushd $tmp"
    rlRun "set -o pipefail"
  rlPhaseEnd

  rlPhaseStartTest
    rlRun "cmake -S $root$TMT_TEST_NAME -B ./build" 0 "Configure project"
    rlRun "cmake --build ./build" 0 "Build project"
  rlPhaseEnd

  rlPhaseStartCleanup
    rlRun "popd"
    rlRun "rm -r $tmp" 0 "Remove tmp directory"
  rlPhaseEnd
rlJournalEnd
