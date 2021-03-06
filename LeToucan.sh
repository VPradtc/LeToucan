#!/bin/sh
ResFile="$0.res"
echo $'\n\n----' >> "${ResFile}"
set -o pipefail
set -uC
( (
    set -ex
    date
    pwd

    Pattern[1]=░░░░░░░░▄▄▄▀▀▀▄▄███▄░░░░░░░░░░░░░░░░
    Pattern[2]=░░░░░▄▀▀░░░░░░░▐░▀██▌░░░░░░░░░░░░░░░
    Pattern[3]=░░░▄▀░░░░▄▄███░▌▀▀░▀█░░░░░░░░░░░░░░░
    Pattern[4]=░░▄█░░▄▀▀▒▒▒▒▒▄▐░░░░█▌░░░░░░░░░░░░░░
    Pattern[5]=░▐█▀▄▀▄▄▄▄▀▀▀▀▌░░░░░▐█▄░░░░░░░░░░░░░
    Pattern[6]=░▌▄▄▀▀░░░░░░░░▌░░░░▄███████▄░░░░░░░░
    Pattern[7]=░░░░░░░░░░░░░▐░░░░▐███████████▄░░░░░
    Pattern[8]=░░░░░le░░░░░░░▐░░░░▐█████████████▄░░
    Pattern[9]=░░░░toucan░░░░░░▀▄░░░▐█████████████▄
    Pattern[10]=░░░░░░has░░░░░░░░▀▄▄███████████████░
    Pattern[11]=░░░░░arrived░░░░░░░░░░░░█▀██████░░░░

    Index=11;

    LastSHA=''
    CurrentItem=''

    declare -A ChangesetMap

    GetCurrentItem(){
        CurrentItem=${Pattern[Index]}
        if [[ "$Index" == 1 ]]; then
            Index=11
            else
            Index=$(expr $Index - 1)
        fi
    }

    RebuildRootChangeset() {
        changesetSHA=$1;

        git checkout $changesetSHA

        GetCurrentItem;
        comment=$CurrentItem
        git commit -m "$comment" --allow-empty --author "LE TOUCAN <le.toucan@le.toucan>"
    }

    RebuildRegularChangeset() {
        changesetSHA=$1;

        currentSHA=$(git rev-parse HEAD)

        git cherry-pick $changesetSHA --allow-empty  && git reset --soft HEAD^1 || git reset --hard $changesetSHA; git reset --soft $currentSHA;

        GetCurrentItem;
        comment=$CurrentItem
        git commit -m "$comment" --allow-empty --author "LE TOUCAN <le.toucan@le.toucan>"
    }

    RebuildMergeChangeset() {
        changesetSHA=$1;
        parent1=$2;
        parent2=$3;

        GetCurrentItem;
        comment=$CurrentItem

        oldParent1=${ChangesetMap[$parent1]}
        oldParent2=${ChangesetMap[$parent2]}

        git checkout $oldParent1
        git reset --hard $changesetSHA;
        git reset --soft $oldParent1;
        git reset --hard $(git commit-tree $(git write-tree) -p HEAD -p $oldParent2 -m "$comment")
        git commit --amend --no-edit --author="LE TOUCAN <le.toucan@le.toucan>"
    }

    RebuildChangeset() {
        changesetSHA=$1

        parents=(`git rev-list --parents -n 1 $changesetSHA`)
        if [[ "${#parents[@]}" == 1 ]]; then
            RebuildRootChangeset $changesetSHA
        else
            if [[ "${#parents[@]}" == 3 ]]; then
                RebuildMergeChangeset $changesetSHA ${parents[1]} ${parents[2]}
            else
                parent1=${parents[1]}
                oldParent1=${ChangesetMap[$parent1]}
                git checkout $oldParent1

                RebuildRegularChangeset $changesetSHA
            fi
        fi

        ChangesetMap[${changesetSHA}]=$(git rev-parse HEAD)
        LastSHA=$changesetSHA
    }

    git reset --hard

    DefaultOrderChangesets=(`git log --format="%H" --all --topo-order`)

    for (( changesetIndex=${#DefaultOrderChangesets[@]}-1 ; changesetIndex>=0 ; changesetIndex-- )) ; do
        RebuildChangeset ${DefaultOrderChangesets[changesetIndex]}
    done
  )
    ExitCode=$?
    (exit ${ExitCode}) && echo 'Success' || echo "Error / ExitCode = $?"
    exit ${ExitCode}
) 2>&1 | tee -a "${ResFile}"
ExitCode=$?
exit ${ExitCode}
