#!/bin/sh

while getopts 'd:h' c
do
  case $c in
	d) DIR=$OPTARG ;;
	h)
	  echo "$0" "-d <directory>"
	  echo "If directory doesn't exist, create it"
	  exit 0
	  ;;
  esac
done

mkdir -p $DIR

NODES=`kubectl get nodes -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | sort`
for n in $NODES; do
	kubectl get nodes $n -o jsonpath='{.metadata.labels}' | tr ' ' '\n'| sort > $DIR/$n.labels
done