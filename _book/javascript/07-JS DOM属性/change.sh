#!/bin/bash



for fileName in *.md;
 do
	#echo $fileName;
	sed -i "" "s/\/Users\/zhanglong\/gitbook\/gitbook_backup/..\/../g" "$fileName"
	sed -i "" "s/\/home\/stevenzhang\/home\/git\/gitbook_backup/..\/../g" "$fileName"
done
