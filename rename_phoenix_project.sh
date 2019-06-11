#!/usr/bin/env bash

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 CURRENT_NAME NEW_NAME" >&2
  exit 1
fi

CURRENT_NAME="$1"
CURRENT_OTP=$(echo "$CURRENT_NAME" | tr '[:upper:]' '[:lower:]')

NEW_NAME="$2"
NEW_OTP=$(echo "$NEW_NAME" | tr '[:upper:]' '[:lower:]')

echo "Current name: $CURRENT_NAME"
echo "Current OTP name: $CURRENT_OTP"
echo "New name: $NEW_NAME"
echo "New OTP name: $NEW_OTP"

ack -l $CURRENT_NAME --ignore-file=is:rename_phoenix_project.sh | xargs sed -i '' -e "s/$CURRENT_NAME/$NEW_NAME/g"
ack -l $CURRENT_OTP --ignore-file=is:rename_phoenix_project.sh | xargs sed -i '' -e "s/$CURRENT_OTP/$NEW_OTP/g"

mv lib/$CURRENT_OTP lib/$NEW_OTP 2>/dev/null
mv lib/$CURRENT_OTP.ex lib/$NEW_OTP.ex 2>/dev/null
mv lib/${CURRENT_OTP}_web lib/${NEW_OTP}_web 2>/dev/null
mv lib/${CURRENT_OTP}_web.ex lib/${NEW_OTP}_web.ex 2>/dev/null
mv test/$CURRENT_OTP test/$NEW_OTP 2>/dev/null
mv test/${CURRENT_OTP}_web test/${NEW_OTP}_web 2>/dev/null
