#!/bin/sh

# Used environment variables:
# - AUDACITY_VERSION: the version of audacity the language files are for
# - AUDACITY_ONLY_POT: if set to y, the script only updates the .pot file without touching the .po files

set -o errexit
set -o nounset

CDPATH= cd -- "$(dirname -- "$0")"

if [ -z "${AUDACITY_VERSION:-}" ]; then
    AUDACITY_VERSION=3.0.3
fi

echo ';; Recreating audacity.pot using .h, .cpp and .mm files'
for path in ../modules/mod-* ../libraries/lib-* ../include ../src ../crashreports ; do
   find $path -name \*.h -o -name \*.cpp -o -name \*.mm
done | LANG=c sort | \
   sed -E 's/\.\.\///g' | \
   xargs xgettext \
   --no-wrap \
   --default-domain=audacity \
   --directory=.. \
   --keyword=_ --keyword=XO --keyword=XC:1,2c --keyword=XXO --keyword=XXC:1,2c --keyword=XP:1,2 --keyword=XPC:1,2,4c \
   --add-comments=' i18n' \
   --add-location=file  \
   --copyright-holder='Audacity Team' \
   --package-name='audacity' \
   --package-version="$AUDACITY_VERSION" \
   --msgid-bugs-address='audacity-translation@lists.sourceforge.net' \
   --add-location=file -L C -o audacity.pot 

echo ';; Adding nyquist files to audacity.pot'
for path in ../plug-ins ; do find $path -name \*.ny -not -name rms.ny; done | LANG=c sort | \
   sed -E 's/\.\.\///g' | \
   xargs xgettext \
   --no-wrap \
   --default-domain=audacity \
   --directory=.. \
   --keyword=_ --keyword=_C:1,2c --keyword=ngettext:1,2 --keyword=ngettextc:1,2,4c \
   --add-comments=' i18n' \
   --add-location=file  \
   --copyright-holder='Audacity Team' \
   --package-name='audacity' \
   --package-version="$AUDACITY_VERSION" \
   --msgid-bugs-address='audacity-translation@lists.sourceforge.net' \
   --add-location=file -L Lisp -j -o audacity.pot 

echo ';; Adding resource files to audacity.pot'
for path in ../resources ; do 
   find $path -name \*.xml 
done | \
   sed -E 's/\.\.\///g' | \
   xargs xgettext \
   --its=resources.its \
   --no-wrap \
   --default-domain=audacity \
   --directory=.. \
   --add-location=file  \
   --copyright-holder='Audacity Team' \
   --package-name='audacity' \
   --package-version="$AUDACITY_VERSION" \
   --msgid-bugs-address='audacity-translation@lists.sourceforge.net' \
   -j -o audacity.pot 

if [ "${AUDACITY_ONLY_POT:-}" = y ]; then
    return 0
fi

echo ';; Rebuilding LINGUAS file'
printf '' >LINGUAS
for i in *.po; do
   echo "${i%.po}" >>LINGUAS
done

echo ';; Updating the .po files - Updating Project-Id-Version'
for i in *.po; do
    sed -i "s/^\"Project-Id-Version:.*/\"Project-Id-Version: audacity $AUDACITY_VERSION\\\\n\"/" "$i"
done

echo ';; Updating the .po files'
for i in *.po; do
   msgmerge --lang="${i%.po}" "$i" audacity.pot -o "$i"
   msgmerge --no-wrap --lang="${i%.po}" "$i" audacity.pot -o "$i"
done

echo ';; Removing '#~|' (which confuse Windows version of msgcat)'
for i in *.po; do
    sed '/^#~|/d' $i > TEMP; mv TEMP $i
done

echo ''
echo ';;Translation updated'
echo ''
head -n 11 audacity.pot | tail -n 3
wc -l audacity.pot
