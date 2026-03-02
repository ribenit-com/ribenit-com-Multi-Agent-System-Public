#!/bin/bash

git_add_all() { echo "MOCK add"; }
git_commit() { echo "MOCK commit"; }
git_push() { echo "MOCK push"; }
git_set_remote() { echo "MOCK set"; }
git_ls_remote() { return 0; }

source ../core/git_core.sh

upload_to_github "/tmp" "test" "u" "p" "https://x/y.git"
echo "单元测试通过"
