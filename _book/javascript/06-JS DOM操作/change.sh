#!/bin/bash



for fileName in *.md;
 do
	#echo $fileName;
	sed -i "" "s/\/Users\/zhanglong\/gitbook\/gitbook_backup/..\/../g" "$fileName"

done
