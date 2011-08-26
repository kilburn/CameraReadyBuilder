#!/bin/bash +x

##### CONFIGURATION VARIABLES

# Master .tex file name
FILE="MasterTeXFile.tex"

# Output file name (without extension)
# This name *must* be different than the master file name without extension
OUT="OutputFile"

# Additional files to include in the package (such as style files)
INCLUDEFILES="llncs.cls"

# Additional directories to include (the whole directory will be inserted
# into the zipped archives)
INCLUDEDIRS=""

# Archive format (either "zip", "tgz" or "bz2")
ARCHIVE_FORMAT="zip"

##### SCRIPT FILE. DO NOT EDIT BELOW THIS LINE.

OUTFILE="$OUT.tex"

rm -rf build > /dev/null 2>&1
rm -rf dist > /dev/null 2>&1
mkdir build

function runLatex {
	pdflatex -halt-on-error --interaction batchmode $1 >/dev/null 2>&1 || (echo "Error." && exit)
}

function parseInput {
	line=$(nl -ba $1  | grep -m1 '\\input{[^}]*}')
	numline=$(echo $line | awk '{print $1}')
	file=$(echo $line | cut -d'{' -f2 | cut -d'}' -f1)
	file="${file%.tex}"
	echo "Parsing input file $file..."
	totallines=$(wc -l $1 | awk '{print $1}')
	headline=$(($numline - 1))
	tailline=$(($totallines - $numline))

	# Head + input file + Tail
	head -n$headline $1 > $1.tmp
	cat $file.tex >> $1.tmp
	echo "" >> $1.tmp
	tail -n$tailline $1 >> $1.tmp
	mv $1.tmp $1
}

# Create a single file by including the latex inputs
cp $FILE $OUTFILE
while `grep -q '\\input{' $OUTFILE`; do
	parseInput ${OUTFILE}
done
# Cleanup comments
echo "Cleaning up comments..."
egrep -v '^[ 	]*%' $OUTFILE | sed -E 's/([^\\])%.*/\1/g' > $OUTFILE.tmp
mv $OUTFILE.tmp $OUTFILE

# Compilation
echo "Initial compilation to generate the bbl file..."
echo "- Pass 1"
runLatex $OUTFILE
echo "- Bibtex"
bibtex $OUT
echo "- Pass 2"
runLatex $OUTFILE
echo "- Pass 3"
runLatex $OUTFILE
rm $OUT.{blg,log,aux,pdf}
mv $OUT.tex build/

# Replace the bibliography portion
cd build
BIB_LINE=$(nl -ba $OUTFILE | grep '\\bibliography{' | awk '{print $1}')
HEAD_LINE=$(($BIB_LINE -1))
TOTAL_LINES=$(wc -l $OUTFILE | awk '{print $1}')
TAIL_LINES=$(($TOTAL_LINES - $BIB_LINE))

head -n$HEAD_LINE $OUTFILE > $OUT.tmp
cat ../$OUT.bbl >> $OUT.tmp
rm ../$OUT.bbl
tail -n$TAIL_LINES $OUTFILE >> $OUT.tmp
mv $OUT.tmp $OUTFILE

# Final regeneration
echo "Including required files..."
for f in $INCLUDEFILES; do
	cp -pr ../$f ./
done

echo 'Fetching required images...'
for img in `egrep -o '\\includegraphics[^{]*{.*}' $OUTFILE | cut -d'{' -f2 | cut -d'}' -f1`; do
	if [[ ${img%.*} == ${img##*.} ]]; then
		# File has no extension
		ext='.pdf'
	else
		ext=''
	fi
	# New image name
	img2=$(echo $img | sed "s/^.\///g" | sed "s/\//_/g")
	# Escaped old image name (to replace in the source file)
	imge=$(echo $img | sed "s/\//\\\\\//g")

	# Update source .tex
	sed "s/$imge/$img2/g" $OUTFILE > $OUTFILE.tmp
	mv $OUTFILE.tmp $OUTFILE
	# Copy the image
	cp ../$img$ext ./$img2$ext
done

echo "Including required directories..."
for d in $INCLUDEDIRS; do
	cp -pr ../$d ./
	# Cleanup svn stuff
	find $d -type d -name '.svn' -print0 | xargs -0 rm -rf
	# Cleanup editable images (omnigraffle)
	find $d -name '*graffle' -print0 | xargs -0 rm -rf
done

echo "Final compilation after including the references"
echo "- Pass 1"
runLatex $OUTFILE
echo "- Pass 2"
runLatex $OUTFILE

# Cleanup
rm $OUT.{log,aux}
cd ..
find build -name '.DS_Store' -print0 | xargs -0 rm -rf
[ -d "$OUT" ] && rm -rf $OUT
mv build $OUT

# Build package and remove folder (avoiding metadata stuff)
export COPYFILE_DISABLE=true
rm $OUT.tgz $OUT.zip $OUT.bz2 2>/dev/null
case $ARCHIVE_FORMAT in
	tgz) tar -czvf $OUT.tgz $OUT ;;
	zip) zip -r $OUT.zip $OUT ;;
	bz2) tar -cjvf $OUT.bz2 $OUT ;;
esac
rm -rf $OUT