@echo off
bash -c './Go %*; echo "## Exit code $?."' 2>&1 | tee "_go"
