#!/bin/sh -x

NODES=`kubectl get nodes -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | sort`
for n in $NODES; do
	LABELS=`kubectl get nodes turingpi01 -o json | jq '.metadata.labels' | jq keys | grep feature.node.kubernetes.io | tr ',' ' ' | tr '"' ' '`
	for l in $LABELS; do
		kubectl label node $n $l-
	done
done