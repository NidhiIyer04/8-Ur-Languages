#!/bin/bash

OUTPUT=$(a68g dungeon.a68 | tee /dev/tty)

echo "$OUTPUT"

SAVE_LINE=$(echo "$OUTPUT" | grep '^SAVE:')

echo
echo "Detected save line:"
echo "$SAVE_LINE"

if [ -z "$SAVE_LINE" ]; then
    echo "No SAVE line found."
    exit 1
fi

DATA=${SAVE_LINE#SAVE:}

IFS=',' read NAME ROOM CLUES COINS WARN WON EXP <<< "$DATA"

echo
echo "Parsed:"
echo "$NAME $ROOM $CLUES $COINS $WARN $WON $EXP"

psql -d blackthorn -c "
INSERT INTO runs
(player_name, room_reached, clues, coins, warnings, won, expelled)
VALUES
('$NAME',$ROOM,$CLUES,$COINS,$WARN,$WON,$EXP);
"

echo
echo "Saved."
