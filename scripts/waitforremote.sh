#/usr/bin/env bash

# this script doesn't work in concourse runc contaners +busybox/alpine+ due to line 56 - export -f BARFOOBAX
# to make it work in concourse runc containers +busybox/alpine+ you need to wrap this scripts in timeout externally in the pipeline definition

URL=$1
WAIT=${2:-10}
SCHEME=$(echo "$URL" | sed "s/^.*\(https\?\).*$/\1/")
OS=$(grep "^ID=" /etc/os-release | cut -d"=" -f2 )

usage(){
  echo ""
  echo "Usage:"
  echo "$0 <url_to_test> <time_to_wait_in_seconds>        # supports http/https schemes only"
  echo ""
  echo ""
  echo "Example:"
  echo "$0 https://github.com 300"
  echo "$0 http://git.com 300"
  echo ""
}

waitForRemote(){
  if [ "$SCHEME" = "https" ]
  then
     EXTRA="-k"
  else
    EXTRA=""
  fi

  until $(curl -m2 --output /dev/null --silent --head --fail "$EXTRA" "$URL"); do
    printf '.'
    sleep 2
  done
}


# echo "$URL"
if [ -z "$URL" ] || [ ! "$URL" ]
then
  echo "error: missing URL to check"
  usage
  exit 1
fi

# logic failure below

# echo "$SCHEME"
# if [ "$SCHEME" != "http" ] || [ "$SCHEME" != "https" ]
# then
#   echo "error: unsupported URL to check"
#   usage
#   exit 1
# fi

echo "detected os: $OS"
echo "waiting $WAIT seconds for remote to be ready - $URL"
# https://stackoverflow.com/questions/9954794/execute-function-with-timeout
# https://stackoverflow.com/questions/5161193/bash-script-that-kills-a-child-process-after-a-given-timeout
#### https://stackoverflow.com/a/5161274

waitForRemote
# export -f waitForRemote
# if [ "$OS" = "alpine" ]
# then
#   timeout -t "$WAIT"  bash -c waitForRemote
# else
#   timeout --preserve-status "$WAIT"  bash -c waitForRemote
# fi
