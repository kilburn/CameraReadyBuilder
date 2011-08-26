# Camera Ready Builder  #

CameraReadyBuilder is a small shell script utility to generate the final camera ready version of papers written in LaTeX.

Features:

+ Generate an archive file including all the sources
+ Full recompilation of all files to avoid skipping any recent change
+ Automatic merging of \input'ed files into a single .tex
+ Automatic inclusion of references into the .tex file
+ Image location and renaming to avoid nested directories

## Usage ##

Using CameraReadyBuilder is a pretty easy four-step process:

1. Copy the file to the folder where your paper sources are.
2. Edit the file, setting the configuration variables according to your needs.
3. Give it execution permission
4. Run it (you can do this as many times as you want/need)

    cd Directory/Where/The/Sources/Are
    chmod +x cameraReadyBuilder.sh
    ./cameraReadyBuilder.sh
