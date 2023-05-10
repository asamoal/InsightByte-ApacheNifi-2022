#!/bin/bash

LOG="$NIFI_DEPLOY/logs/nifi-cli.log"

echo $@ >> $LOG

EVENT=$1
BUCKET=$2
FLOW=$3
VERSION=$4
AUTHOR=$5
COMMENT="${@:6}"

# We want to do something only when a new version of a flow is being versioned
if [[ "$EVENT" == "CREATE_FLOW_VERSION" ]]; then

  # We want to deploy in production only when the comment contains the keyword "PRODREADY"
  if [[ "$COMMENT" == *"PRODREADY"* ]]; then

    PG=`grep $FLOW $NIFI_DEPLOY/config/automation_mapping.tsv | awk '{print $2}'`
    # echo "Process Group - " $PG >> $LOG
    PCP=`grep $FLOW NIFI_DEPLOY/config/automation_mapping.tsv | awk '{print $3}'`
    # echo "Parameter Context Provider - " $PCP >> $LOG

    # Upgrade the flow to the latest version
    $NIFI_TOOLKIT/bin/cli.sh nifi pg-change-version --processGroupId $PG  >> $LOG

    # Refresh everything with the Parameter Context Provider
    $NIFI_TOOLKIT/bin/cli.sh nifi fetch-params --paramProviderId $PCP --applyParameters --sensitiveParamPattern "sens_.*" >> $LOG

    # Start associated controller services in the process group
    $NIFI_TOOLKIT/bin/cli.sh nifi pg-enable-services --processGroupId $PG >> $LOG

    # Start the process group
    $NIFI_TOOLKIT/bin/cli.sh nifi pg-start --processGroupId $PG >> $LOG

  fi
fi