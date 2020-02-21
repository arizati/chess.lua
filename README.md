# Chess.lua

- A basic chess library ported from https://github.com/jhlywa/chess.js
- Without chess engine.
- For Lua5.1, it requires bitwise library.

## Example

```lua
local Chess = require('chess')
local chess = Chess()
math.randomseed(tostring(os.time()):reverse():sub(1, 7))
while true do
    local moves = chess.moves()
    if #moves == 0 then
        break
    else
        local idx = math.random(1, #moves)
        local move = moves[idx]
        chess.move(move)
    end
    local over, result, reason = chess.game_over()
    if over then
        print(result, reason)
        break
    end
end
print(chess.pgn())
```

## API

The APIs are the same as [jhlywa's chess.js](https://github.com/jhlywa/chess.js).

See this https://github.com/jhlywa/chess.js/blob/master/README.md#api
