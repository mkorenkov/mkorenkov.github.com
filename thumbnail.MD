Generate thumbnails:
====================

Requrements:
-----------

    apt-get install imagemagick

Usage:
------

    find . -name "*.JPG" | xargs -i convert -scale 15% {} ./th/{} 
    cd ./th/
    find ./ -depth -name "*.JPG" -exec sh -c 'mv "$1" "${1%.JPG}_m.JPG"' _ {} \;
