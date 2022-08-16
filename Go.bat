@echo off
rem bash -c './Go %*; echo "## Exit code $?."' 2>&1 | tee "_go"
bash -c './Go.pl %*; echo; echo "## Script exit code $?."' 2>&1 | tee "_go"
