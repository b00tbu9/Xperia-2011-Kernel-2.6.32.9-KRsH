#!/sbin/bash


vercomp () {
    if [[ $1 == $2 ]]
    then
        # equal
        echo 0
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            # second is less than first
            echo 1
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            # second is greater than first
            echo 2
            return 2
        fi
    done
    return 0
}

vercomp $1 $2