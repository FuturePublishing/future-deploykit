#!/bin/bash

while getopts ":t:" opt; do
	case $opt in
		t)
			tag=$OPTARG
      			echo "Tag is $tag" >&2
      			;;
		\?)
      			echo "Invalid option: -$OPTARG" >&2
      			exit 1
      			;;
    		:)
      			echo "Option -$OPTARG requires an argument." >&2
      			exit 1
      			;;
  	esac
done

echo Pre-link code starts here.

exit 0
