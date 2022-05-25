echo "Testing Stable Version"

./min-love2d-fennel/.duplicate/new-game.sh test-min-love2d -f
cd test-min-love2d

echo "Testing windows"
make windows
