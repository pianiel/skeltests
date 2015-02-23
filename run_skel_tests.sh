#!/usr/bin/env sh

cores="1 2 4 8 16 32 48 64"
t=360000
model="mas_skel"

ops="emas_erl_ops"
pull="disable"

# ops="emas_test_ops"
# pull="enable"

for $core in $cores; do
	./skel_tests.sh $model $core $t $ops $pull
done