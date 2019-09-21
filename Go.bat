@echo off
bash -c './Go %*' 2>&1 | tee "_go"
