#!/bin/bash
set -e
export LANG=C
PACKAGE=sunxi-boards
TARBALL=$(ls ${PACKAGE}*.tar.* | sort -r | head -n 1)
if [ -n "$(echo ${TARBALL} | grep 'xz$')" ]; then
    cp ${TARBALL} tmp_${TARBALL}
    IDENTIFIER=$(echo tmp_${TARBALL} | sed 's|\.xz$||g')
    xz -d tmp_${TARBALL}
    BOARD_CONFIGS=$(tar -tf ${IDENTIFIER} | grep '.fex')
    rm -rf ${IDENTIFIER}
else
    BOARD_CONFIGS=$(tar -tf ${TARBALL} | grep '.fex')
fi
GROUP="System/Boot"
SUMMARY="Sys_config boot files of board"
DESCRIPTION="This package contain board specifiy script.bin files"

# Add new subpackages if the tarball contain them
for board_config in ${BOARD_CONFIGS}; do
    FILE_PREFIX=$(basename ${board_config} | sed 's|\.fex||g')

    SUB_PACKAGE=$(basename ${board_config} | \
        sed 's|\.fex||g' | \
        sed 's|+|plus|g' | \
        sed 's|\.|dot|g')

    # Add new subpackages
    if [ -z "$(egrep "Name:  ${SUB_PACKAGE}$" *.yaml)" ]; then
        specify --newsub=${SUB_PACKAGE}
        sed -i "s|Requires:|Requires:\n    - ${PACKAGE}-${SUB_PACKAGE}|g" *.yaml
        sed -i "s|Summary: ^^^|Summary: ${SUMMARY} ${SUB_PACKAGE}|g" *.yaml
        sed -i "s|Group: ^^^|Group: ${GROUP}|g" *.yaml
        sed -i '/"^^^"/d' *.yaml
        echo "      AutoDepend: false" >> *.yaml
        echo "      Description: |" >> *.yaml
        echo "          ${DESCRIPTION}" >>  *.yaml
        echo "" >>  *.yaml
        echo "      Files:" >> *.yaml
        echo "          - /boot/${FILE_PREFIX}-script.bin" >> *.yaml
    fi
done

# Remove from tarball dropped subpackage
SUB_PACKAGES=$(grep '\- Name:' *.yaml | sed 's|\- Name:||g' | sed 's| ||g')
for subpackage in ${SUB_PACKAGES}; do
    MAYBE_RENAMED=$(echo ${subpackage} | \
        sed 's|plus|+|g' | \
        sed 's|dot|.|g')
    if [ -z "$(echo ${BOARD_CONFIGS} | grep "${subpackage}.fex" )" ]; then
       echo "Warning tarball does not contain fex file: ${subpackage}.fex"
       if [ -n "$(echo ${BOARD_CONFIGS} | grep "${MAYBE_RENAMED}.fex")" ]; then
           echo -n "Package was most likely renamed by rpm convention from: "
           echo "${MAYBE_RENAMED}"
       else
           echo "Remove from tarball dropped package: ${subpackage}"
           sed -i "/- Name:  ${subpackage}/,+9d" *.yaml
           sed -i "/- ${PACKAGE}-${subpackage}$/d" *.yaml
       fi
    fi
done

# Update spec file
specify
