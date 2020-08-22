#!/bin/bash
vals=$(ls -Q $HOME/.lighthouse/validators | grep 0x | awk '/START/{if (x)print x;x="";next}{x=(!x)?$0:x","$0;}END{print x;}')
echo $vals
 
bv=$(curl -s -X POST http://localhost:5052/beacon/validators -d "{\"pubkeys\": [ ${vals} ]}")
# echo "${bv}" | jq

echo "${bv}" | jq -r 'keys_unsorted[] as $k | (if $k == 0 then "#TYPE validator_balance gauge\n" else "" end) + "validator_balance{index=\"\(.[$k].validator_index)\"} \(.[$k].balance)"' \
 |  curl --data-binary @- http://localhost:9091/metrics/job/validators
echo "pushed balance data $?"

echo "${bv}" | jq -r 'keys_unsorted[] as $k | (if $k == 0 then "#TYPE validator_effective_balance gauge\n" else "" end) + "validator_effective_balance{index=\"\(.[$k].validator_index)\"} \(.[$k].validator.effective_balance)"' \
 |  curl --data-binary @- http://localhost:9091/metrics/job/validators

echo "${bv}" | jq -r 'keys_unsorted[] as $k | (if $k == 0 then "#TYPE validator_slashed gauge\n" else "" end) + "validator_slashed{index=\"\(.[$k].validator_index)\"} \(if .[$k].validator.slashed then 1 else 0 end)"' \
 |  curl --data-binary @- http://localhost:9091/metrics/job/validators


echo "${bv}" | jq -r 'reduce .[].balance as $b (0; . + $b) | "#TYPE balance_all_validators gauge\nbalance_all_validators \(.)"' \
 | curl --data-binary @- http://localhost:9091/metrics/job/validators
echo "validator push done $?"

head=$(curl -s http://localhost:5052/beacon/head)
slot=$(echo "${head}" | jq '.slot')
epoch=$(echo "${head}" | jq '.slot/32 | floor')

echo "slot ${slot} epoch ${epoch}"

duties=$(curl -s -X POST http://localhost:5052/validator/duties -d "{\"pubkeys\": [ ${vals} ], \"epoch\": ${epoch}}")
att=$(echo "${duties}" | jq -r 'reduce .[] as $v ("#TYPE scheduled_attestation_slot counter@"; . + "scheduled_attestation_slot{index=\"\($v.validator_index)\"} \($v.attestation_slot)@") | split("@")[]')
echo "attestation ${att}"
echo "${att}" | curl --data-binary @- http://localhost:9091/metrics/job/validators


