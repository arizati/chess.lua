require 'bit'
-- local bit=bit
local BLACK = 'b'
local WHITE = 'w'

local EMPTY = -1

local PAWN = 'p'
local KNIGHT = 'n'
local BISHOP = 'b'
local ROOK = 'r'
local QUEEN = 'q'
local KING = 'k'

local SYMBOLS = 'pnbrqkPNBRQK'

local DEFAULT_POSITION = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'

local POSSIBLE_RESULTS = { '1-0', '0-1', '1/2-1/2', '*' }

local PAWN_OFFSETS = {
    b = { 16, 32, 17, 15 },
    w = {-16, -32, -17, -15 }
}

local PIECE_OFFSETS = {
    n = {-18, -33, -31, -14, 18, 33, 31, 14 },
    b = {-17, -15, 17, 15 },
    r = {-16, 1, 16, -1 },
    q = {-17, -16, -15, 1, 17, 16, 15, -1 },
    k = {-17, -16, -15, 1, 17, 16, 15, -1 }
}

-- prettier-ignore
local ATTACKS = {
    20, 0, 0, 0, 0, 0, 0, 24, 0, 0, 0, 0, 0, 0, 20, 0,
    0, 20, 0, 0, 0, 0, 0, 24, 0, 0, 0, 0, 0, 20, 0, 0,
    0, 0, 20, 0, 0, 0, 0, 24, 0, 0, 0, 0, 20, 0, 0, 0,
    0, 0, 0, 20, 0, 0, 0, 24, 0, 0, 0, 20, 0, 0, 0, 0,
    0, 0, 0, 0, 20, 0, 0, 24, 0, 0, 20, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 20, 2, 24, 2, 20, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 2, 53, 56, 53, 2, 0, 0, 0, 0, 0, 0,
    24, 24, 24, 24, 24, 24, 56, 0, 56, 24, 24, 24, 24, 24, 24, 0,
    0, 0, 0, 0, 0, 2, 53, 56, 53, 2, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 20, 2, 24, 2, 20, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 20, 0, 0, 24, 0, 0, 20, 0, 0, 0, 0, 0,
    0, 0, 0, 20, 0, 0, 0, 24, 0, 0, 0, 20, 0, 0, 0, 0,
    0, 0, 20, 0, 0, 0, 0, 24, 0, 0, 0, 0, 20, 0, 0, 0,
    0, 20, 0, 0, 0, 0, 0, 24, 0, 0, 0, 0, 0, 20, 0, 0,
    20, 0, 0, 0, 0, 0, 0, 24, 0, 0, 0, 0, 0, 0, 20
}

-- prettier-ignore
local RAYS = {
    17, 0, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 0, 15, 0,
    0, 17, 0, 0, 0, 0, 0, 16, 0, 0, 0, 0, 0, 15, 0, 0,
    0, 0, 17, 0, 0, 0, 0, 16, 0, 0, 0, 0, 15, 0, 0, 0,
    0, 0, 0, 17, 0, 0, 0, 16, 0, 0, 0, 15, 0, 0, 0, 0,
    0, 0, 0, 0, 17, 0, 0, 16, 0, 0, 15, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 17, 0, 16, 0, 15, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 17, 16, 15, 0, 0, 0, 0, 0, 0, 0,
    1, 1, 1, 1, 1, 1, 1, 0, -1, -1, -1, -1, -1, -1, -1, 0,
    0, 0, 0, 0, 0, 0, -15, -16, -17, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, -15, 0, -16, 0, -17, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, -15, 0, 0, -16, 0, 0, -17, 0, 0, 0, 0, 0,
    0, 0, 0, -15, 0, 0, 0, -16, 0, 0, 0, -17, 0, 0, 0, 0,
    0, 0, -15, 0, 0, 0, 0, -16, 0, 0, 0, 0, -17, 0, 0, 0,
    0, -15, 0, 0, 0, 0, 0, -16, 0, 0, 0, 0, 0, -17, 0, 0,
    -15, 0, 0, 0, 0, 0, 0, -16, 0, 0, 0, 0, 0, 0, -17
}

local SHIFTS = { p = 0, n = 1, b = 2, r = 3, q = 4, k = 5 }

local FLAGS = {
    NORMAL = 'n',
    CAPTURE = 'c',
    BIG_PAWN = 'b',
    EP_CAPTURE = 'e',
    PROMOTION = 'p',
    KSIDE_CASTLE = 'k',
    QSIDE_CASTLE = 'q'
}

local BITS = {
    NORMAL = 1,
    CAPTURE = 2,
    BIG_PAWN = 4,
    EP_CAPTURE = 8,
    PROMOTION = 16,
    KSIDE_CASTLE = 32,
    QSIDE_CASTLE = 64
}

local RANK_1 = 7
local RANK_2 = 6
local RANK_3 = 5
local RANK_4 = 4
local RANK_5 = 3
local RANK_6 = 2
local RANK_7 = 1
local RANK_8 = 0

-- prettier-ignore
local SQUARES = {
    a8 = 0, b8 = 1, c8 = 2, d8 = 3, e8 = 4, f8 = 5, g8 = 6, h8 = 7,
    a7 = 16, b7 = 17, c7 = 18, d7 = 19, e7 = 20, f7 = 21, g7 = 22, h7 = 23,
    a6 = 32, b6 = 33, c6 = 34, d6 = 35, e6 = 36, f6 = 37, g6 = 38, h6 = 39,
    a5 = 48, b5 = 49, c5 = 50, d5 = 51, e5 = 52, f5 = 53, g5 = 54, h5 = 55,
    a4 = 64, b4 = 65, c4 = 66, d4 = 67, e4 = 68, f4 = 69, g4 = 70, h4 = 71,
    a3 = 80, b3 = 81, c3 = 82, d3 = 83, e3 = 84, f3 = 85, g3 = 86, h3 = 87,
    a2 = 96, b2 = 97, c2 = 98, d2 = 99, e2 = 100, f2 = 101, g2 = 102, h2 = 103,
    a1 = 112, b1 = 113, c1 = 114, d1 = 115, e1 = 116, f1 = 117, g1 = 118, h1 = 119
}

local ROOKS = {
    w = { --array
        { square = SQUARES.a1, flag = BITS.QSIDE_CASTLE },
        { square = SQUARES.h1, flag = BITS.KSIDE_CASTLE }
    },
    b = { --array
        { square = SQUARES.a8, flag = BITS.QSIDE_CASTLE },
        { square = SQUARES.h8, flag = BITS.KSIDE_CASTLE }
    }
}

------------------------------
-- COMMON UTILITY FUNCTIONS --
------------------------------
local function rank(i)
    return bit.brshift(i, 4) -- i >> 4
end

local function file(i)
    return bit.band(i, 15) -- i & 15
end

local function algebraic(i)
    local f, r = file(i) + 1, rank(i) + 1
    return ('abcdefgh'):sub(f, f) .. ('87654321'):sub(r, r)
end

local function swap_color(c)
    return c == WHITE and BLACK or WHITE
end

local function is_digit(c)
    return ({[0] = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 })[c] ~= nil
    -- return ('0123456789').indexOf(c) ~= -1
end

--- just copy
local function clone(obj)
    local function _copy(org, res)
        for k, v in pairs(org) do
            if type(v) ~= "table" then
                res[k] = v;
            else
                res[k] = {};
                _copy(v, res[k])
            end
        end
    end
    local res = {}
    _copy(obj, res)
    return res
end

local function trim(str)
    local from = str:match "^%s*()"
    return from > #str and "" or str:match(".*%S", from)
end

-- parses all of the decorators out of a SAN string
local function stripped_san(move)
    return move:gsub('=', ''):gsub('[+#]?[?!]*$', '')
    --   return move.replace(/=/, '').replace(/[+#]?[?!]*$/, '')
end

local function str_split(str, sep)
    local sep, fields = sep or " ", {}
    local pattern = string.format("([^%s]+)", sep)
    str:gsub(pattern, function(c) fields[#fields + 1] = c end)
    return fields
end
--------------------------
--- TODO: this function is pretty much crap - it validates structure but
--completely ignores content (e.g. doesn't verify that each side has a king)
--... we should rewrite this, and ditch the silly error_number field while
--we're at it
--
local function validate_fen(fen)
    local errors = {
        [1] = 'FEN string must contain six space-delimited fields.',
        [2] = '6th field (move number) must be a positive integer.',
        [3] = '5th field (half move counter) must be a non-negative integer.',
        [4] = '4th field (en-passant square) is invalid.',
        [5] = '3rd field (castling availability) is invalid.',
        [6] = '2nd field (side to move) is invalid.',
        [7] = "1st field (piece positions) does not contain 8 '/'-delimited rows.",
        [8] = '1st field (piece positions) is invalid [consecutive numbers].',
        [9] = '1st field (piece positions) is invalid [invalid piece].',
        [10] = '1st field (piece positions) is invalid [row too large].',
        [11] = 'Illegal en-passant square',
        [12] = 'No errors.',
    }

    --- 1st criterion: 6 space-seperated fields? 
    local tokens = str_split(fen)
    if #tokens ~= 6 then
        return { valid = false, error_number = 1, error = errors[1] }
    end

    --- 2nd criterion: move number field is a integer value > 0?
    local t6 = tonumber(tokens[6])
    if type(t6) ~= "number" or t6 <= 0 then
        return { valid = false, error_number = 2, error = errors[2] }
    end

    --- 3rd criterion: half move counter is an integer >= 0? 
    local t5 = tonumber(tokens[5])
    if type(t5) ~= "number" or t5 < 0 then
        return { valid = false, error_number = 3, error = errors[3] }
    end

    --- 4th criterion: 4th field is a valid e.p.-string?
    local t4 = tokens[4]
    if not (t4 == '-' or t4:find('^([abcdefgh][36])$')) then
        return { valid = false, error_number = 4, error = errors[4] }
    end

    --- 5th criterion: 3th field is a valid castle-string? 
    local function valid_castle_str(str)
        if str == '-' or str == 'q' then return true end
        local str_find = string.find
        for _, re in ipairs({ '^KQ?k?q?$', '^Qk?q?$', '^kq?$' }) do
            if str_find(str, re) then return true end
        end
        return false
    end
    if not valid_castle_str(tokens[3]) then
        return { valid = false, error_number = 5, error = errors[5] }
    end

    --- 6th criterion: 2nd field is "w" (white) or "b" (black)? 
    local t2 = tokens[2]
    if not (t2 == 'w' or t2 == 'b') then
        return { valid = false, error_number = 6, error = errors[6] }
    end

    --- 7th criterion: 1st field contains 8 rows? 
    local rows = str_split(tokens[1], '/')
    if #rows ~= 8 then
        return { valid = false, error_number = 7, error = errors[7] }
    end

    --- 8th criterion = every row is valid?
    for i, v in ipairs(rows) do
        local sum_fields = 0
        local previous_was_number = false
        v:gsub('.', function(ch)
            if tonumber(ch) ~= nil then
                if previous_was_number then
                    return { valid = false, error_number = 8, error = errors[8] }
                end
                sum_fields = sum_fields + tonumber(ch, 10)
                previous_was_number = true
            else
                if not (ch):find('^[prnbqkPRNBQK]$') then
                    return { valid = false, error_number = 9, error = errors[9] }
                end
                sum_fields = sum_fields + 1
                previous_was_number = false
            end
        end)
        if sum_fields ~= 8 then
            return { valid = false, error_number = 10, error = errors[10] }
        end
    end

    local rk = t4:sub(2, 2)
    if (rk == '3' and t2 == 'w') or (rk == '6' and t2 == 'b') then
        return { valid = false, error_number = 11, error = errors[11] }
    end

    --- everything's okay!
    return { valid = true, error_number = 0, error = errors[12] }
end
--------------------------
local function gen_squares()
    local keys = {} --array
    local i = SQUARES.a8
    repeat
        if bit.band(i, 0x88) ~= 0 then
            i = i + 8
        else
            table.insert(keys, algebraic(i))
            i = i + 1
        end
    until i > SQUARES.h1
    return keys
end
local function gen_empty_board()
    --Array(128)
    return {
        false, false, false, false, false, false, false, false, false, false, false,
        false, false, false, false, false, false, false, false, false, false, false,
        false, false, false, false, false, false, false, false, false, false, false,
        false, false, false, false, false, false, false, false, false, false, false,
        false, false, false, false, false, false, false, false, false, false, false,
        false, false, false, false, false, false, false, false, false, false, false,
        false, false, false, false, false, false, false, false, false, false, false,
        false, false, false, false, false, false, false, false, false, false, false,
        false, false, false, false, false, false, false, false, false, false, false,
        false, false, false, false, false, false, false, false, false, false, false,
        false, false, false, false, false, false, false, false, false, false, false,
        false, false, false, false, false, false, false,
    }
end
local Chess = {
    --PUBLIC CONSTANTS
    WHITE = WHITE,
    BLACK = BLACK,
    PAWN = PAWN,
    KNIGHT = KNIGHT,
    BISHOP = BISHOP,
    ROOK = ROOK,
    QUEEN = QUEEN,
    KING = KING,
    SQUARES = gen_squares(),
    FLAGS = FLAGS
}
Chess.__index = Chess

function Chess:create(start_fen)
    local obj = {}             -- our new object
    setmetatable(obj, self)
    -- init
    local self_board = gen_empty_board()  --new Array(128)
    local self_kings = { w = EMPTY, b = EMPTY }
    local self_turn = WHITE
    local self_castling = { w = 0, b = 0 }
    local self_ep_square = EMPTY
    local self_half_moves = 0
    local self_move_number = 1
    local self_history = {} --array
    local self_header = {}
    -------------------------------------------------
    -- called when the initial board setup is changed with put() or remove().
    -- modifies the SetUp and FEN properties of the header object.  if the FEN is
    -- equal to the default position, the SetUp and FEN are deleted
    -- the setup is only updated if history.length is zero, ie moves haven't been
    -- made.
    local function update_setup(fen)
        if #self_history > 0 then return end

        if fen ~= DEFAULT_POSITION then
            self_header['SetUp'] = '1'
            self_header['FEN'] = fen
        else
            self_header['SetUp'] = nil
            self_header['FEN'] = nil
        end
    end

    local function generate_fen()
        local empty = 0;
        local fen = '';

        local i = SQUARES.a8
        repeat
            local idx = i + 1
            --!!!
            local piece = self_board[idx]
            if not piece then
                empty = empty + 1
            else
                if empty > 0 then
                    fen = fen .. empty
                    empty = 0
                end
                local color = piece.color;
                local piece_type = piece.type;
                fen = fen .. (color == WHITE and piece_type:upper() or piece_type:lower())
            end

            if bit.band(idx, 0x88) ~= 0 then
                if empty > 0 then
                    fen = fen .. empty
                end
                if i ~= SQUARES.h1 then
                    fen = fen .. '/'
                end
                empty = 0
                i = idx + 8
            end
            i = i + 1
        until i > SQUARES.h1

        local cflags = ''
        if bit.band(self_castling[WHITE], BITS.KSIDE_CASTLE) ~= 0 then
            cflags = cflags .. 'K'
        end
        if bit.band(self_castling[WHITE], BITS.QSIDE_CASTLE) ~= 0 then
            cflags = cflags .. 'Q'
        end
        if bit.band(self_castling[BLACK], BITS.KSIDE_CASTLE) ~= 0 then
            cflags = cflags .. 'k'
        end
        if bit.band(self_castling[BLACK], BITS.QSIDE_CASTLE) ~= 0 then
            cflags = cflags .. 'q'
        end

        -- do we have an empty castling flag?
        if #cflags == 0 then
            cflags = '-'
        end
        local epflags = self_ep_square == EMPTY and '-' or algebraic(self_ep_square);

        return table.concat({ fen, self_turn, cflags, epflags, self_half_moves, self_move_number }, ' ')
    end

    local function clear(keep_headers)
        self_board = gen_empty_board() --new Array(128)
        self_kings = { w = EMPTY, b = EMPTY }
        self_turn = WHITE
        self_castling = { w = 0, b = 0 }
        self_ep_square = EMPTY
        self_half_moves = 0
        self_move_number = 1
        self_history = {}
        if not keep_headers then
            self_header = {}
        end
        update_setup(generate_fen())
    end

    local function set_header(args)
        for i = 1, #args, 2 do
            local a1, a2 = args[i], args[i + 1]
            if type(a1) == 'string' and type(a2) == 'string' then
                self_header[a1] = a2
            end
        end
        return self_header
    end

    local function get(square)
        local sq = SQUARES[square]
        --!!!
        local piece = sq and self_board[sq + 1]
        if type(piece) == 'table' then return { type = piece.type, color = piece.color } end
    end

    local function put(piece, square)
        local p_type, p_color
        if type(piece) == 'table' then
            p_type, p_color = piece.type, piece.color
        end
        --check for valid piece object
        if type(p_type) ~= "string" or type(p_color) ~= "string" then
            return false
        end

        --check for piece
        if SYMBOLS:find(p_type:lower()) then
            return false
        end

        local sq = SQUARES[square]
        --check for valid square
        if type(sq) ~= 'number' then
            return false
        end

        --don't let the user place more than one king
        if p_type == KING and not (self_kings[p_color] == EMPTY or self_kings[p_color] == sq) then
            return false
        end
        --!!!
        self_board[sq + 1] = { type = p_type, color = p_color }
        if p_type == KING then
            self_kings[p_color] = sq;
        end
        update_setup(generate_fen())
        return true
    end

    local function push(move)
        table.insert(self_history, {
            move = move,
            kings = { b = self_kings.b, w = self_kings.w },
            turn = self_turn,
            castling = { b = self_castling.b, w = self_castling.w },
            ep_square = self_ep_square,
            half_moves = self_half_moves,
            move_number = self_move_number
        })
    end

    local function remove(square)
        local piece = get(square)
        if piece then
            self_board[SQUARES[square] + 1] = false --!!!
        end
        if piece and piece.type == KING then
            self_kings[piece.color] = EMPTY
        end
        update_setup(generate_fen())
        return piece
    end

    local function load(fen, keep_headers)
        if keep_headers == nil then
            keep_headers = false
        end

        local tokens = str_split(fen)
        local position = tokens[1]
        local square = 0

        if not validate_fen(fen).valid then
            return false
        end

        clear(keep_headers);

        position:gsub('.', function(ch)
            if ch == '/' then
                square = square + 8
            elseif is_digit(ch) then
                square = square + tonumber(ch, 10)
            else
                local color = ch:byte() < 97 and WHITE or BLACK
                put({ type = ch:lower(), color = color }, algebraic(square))
                square = square + 1
            end
        end)

        self_turn = tokens[2];

        local tokens_3 = tokens[3]

        if tokens_3:find('K') then
            self_castling.w = bit.bor(self_castling.w, BITS.KSIDE_CASTLE)
        end
        if tokens_3:find('Q') then
            self_castling.w = bit.bor(self_castling.w, BITS.QSIDE_CASTLE)
            -- self_castling.w |= BITS.QSIDE_CASTLE;
        end
        if tokens_3:find('k') then
            self_castling.b = bit.bor(self_castling.b, BITS.KSIDE_CASTLE)
            -- self_castling.b |= BITS.KSIDE_CASTLE;
        end
        if tokens_3:find('q') then
            self_castling.b = bit.bor(self_castling.b, BITS.QSIDE_CASTLE)
            --   self_castling.b |= BITS.QSIDE_CASTLE;
        end

        --En passant target square
        local tokens_4 = tokens[4]
        self_ep_square = tokens_4 == '-' and EMPTY or SQUARES[tokens_4]
        self_half_moves = tonumber(tokens[5], 10)
        self_move_number = tonumber(tokens[6], 10)

        update_setup(generate_fen());

        return true;
    end

    local function reset()
        load(DEFAULT_POSITION)
    end

    local function attacked(color, square)
        local i = SQUARES.a8
        repeat
            -- did we run off the end of the board
            if bit.band(i, 0x88) ~= 0 then
                i = i + 8 -- +7 +1
            else
                local piece = self_board[i + 1] --!!!
                -- nonempty square and correct color
                if piece and piece.color == color then

                    local difference = i - square
                    local index = difference + 120 --!!! +119 +1

                    local piece_type, piece_color = piece.type, piece.color
                    --!!!
                    if bit.band(ATTACKS[index], bit.lshift(1, SHIFTS[piece_type])) ~= 0 then
                        if piece_type == PAWN then
                            if difference > 0 then
                                if piece_color == WHITE then return true end
                            else
                                if piece_color == BLACK then return true end
                            end
                        else
                            -- if the piece is a knight or a king
                            if piece_type == 'n' or piece_type == 'k' then return true end

                            local offset = RAYS[index] --!!!
                            local j = i + offset

                            local blocked = false
                            while j ~= square do
                                if not self_board[j + 1] then --!!!
                                    blocked = true
                                    break
                                end
                                j = j + offset
                            end

                            if not blocked then return true end
                        end
                    end
                end
                --
                i = i + 1
            end
        until i > SQUARES.h1

        return false
    end

    local function king_attacked(color)
        return attacked(swap_color(color), self_kings[color])
    end

    local function in_check()
        return king_attacked(self_turn)
    end

    local function make_move(move)
        local us = self_turn;
        local them = swap_color(us)
        push(move)

        local move_to, move_from = move.to, move.from
        local move_to_i, move_from_i = move_to + 1, move_from + 1 --!!!
        --!!!
        self_board[move_to_i] = self_board[move_from_i]
        self_board[move_from_i] = false

        -- if ep capture, remove the captured pawn
        if bit.band(move.flags, BITS.EP_CAPTURE) ~= 0 then
            if self_turn == BLACK then
                self_board[move_to_i - 16] = false --!!!
            else
                self_board[move_to_i + 16] = false --!!!
            end
        end

        -- if pawn promotion, replace with new piece
        if bit.band(move.flags, BITS.PROMOTION) ~= 0 then
            self_board[move_to_i] = { type = move.promotion, color = us } --!!!
        end

        -- if we moved the king
        if self_board[move_to_i].type == KING then --!!!
            self_kings[self_board[move_to_i].color] = move_to --!!!
            -- if we castled, move the rook next to the king
            if bit.band(move.flags, BITS.KSIDE_CASTLE) ~= 0 then
                local castling_to = move_to --!!! move_to -1           +1
                local castling_from = move_to_i + 1 --!!! move_to +1   +1
                self_board[castling_to] = self_board[castling_from]
                self_board[castling_from] = false
            elseif bit.band(move.flags, BITS.QSIDE_CASTLE) ~= 0 then
                local castling_to = move_to_i + 1 --!!! move_to + 1 _+1
                local castling_from = move_to - 1 --!!! move_to - 2 +1
                self_board[castling_to] = self_board[castling_from]
                self_board[castling_from] = false
            end
            -- turn off castling
            self_castling[us] = 0 --???
        end

        -- turn off castling if we move a rook
        local self_castling_us = self_castling[us]
        if self_castling_us and self_castling_us ~= 0 and self_castling_us ~= '' then
            local ROOKS_us = ROOKS[us]
            for _, r in ipairs(ROOKS_us) do --!!!
                if move_from == r.square and bit.band(self_castling_us, r.flag) ~= 0 then
                    self_castling[us] = bit.bxor(self_castling_us, r.flag)
                    break
                end
            end
        end

        -- turn off castling if we capture a rook
        local self_castling_them = self_castling[them]
        if self_castling_them and self_castling_them ~= 0 and self_castling_them ~= '' then
            local ROOKS_them = ROOKS[them]
            for _, r in ipairs(ROOKS_them) do --!!!
                if move_to == r.square and bit.band(self_castling_them, r.flag) ~= 0 then
                    self_castling[them] = bit.bxor(self_castling_them, r.flag)
                    break
                end
            end
        end

        -- if big pawn move, update the en passant square
        if bit.band(move.flags, BITS.BIG_PAWN) ~= 0 then
            if self_turn == 'b' then
                self_ep_square = move_to - 16
            else
                self_ep_square = move_to + 16
            end
        else
            self_ep_square = EMPTY;
        end

        -- reset the 50 move counter if a pawn is moved or a piece is captured
        if move.piece == PAWN then
            self_half_moves = 0;
        elseif bit.band(move.flags, bit.bor(BITS.CAPTURE, BITS.EP_CAPTURE)) ~= 0 then
            self_half_moves = 0
        else
            self_half_moves = self_half_moves + 1
        end

        if self_turn == BLACK then
            self_move_number = self_move_number + 1
        end
        self_turn = swap_color(self_turn)
    end

    local function undo_move()
        local count = #self_history
        if count == 0 then
            return
        end
        local old = self_history[count]
        table.remove(self_history, count)

        local move = old.move
        self_kings = old.kings
        self_turn = old.turn
        self_castling = old.castling
        self_ep_square = old.ep_square
        self_half_moves = old.half_moves
        self_move_number = old.move_number

        local us = self_turn
        local them = swap_color(self_turn)

        local move_from, move_to = move.from, move.to
        local move_from_i, move_to_i = move_from + 1, move_to + 1
        self_board[move_from_i] = self_board[move_to_i]
        self_board[move_from_i].type = move.piece -- to undo any promotions
        self_board[move_to_i] = false

        local move_flags = move.flags
        if bit.band(move_flags, BITS.CAPTURE) ~= 0 then
            self_board[move_to_i] = { type = move.captured, color = them }
        elseif bit.band(move_flags, BITS.EP_CAPTURE) ~= 0 then
            local index
            if us == BLACK then
                index = move_to_i - 16 --!!! move_to -16 +1
            else
                index = move_to_i + 16 --!!! move_to +16 +1
            end
            self_board[index] = { type = PAWN, color = them } --!!!
        end

        if bit.band(move_flags, bit.bor(BITS.KSIDE_CASTLE, BITS.QSIDE_CASTLE)) ~= 0 then
            local castling_to, castling_from
            if bit.band(move_flags, BITS.KSIDE_CASTLE) ~= 0 then
                castling_to = move_to_i + 1 --!!! move_to + 1 +1
                castling_from = move_to --!!! move_to - 1 +1
            elseif bit.band(move_flags, BITS.QSIDE_CASTLE) ~= 0 then
                castling_to = move_to - 1 --!!! move_to -2 +1
                castling_from = move_to_i + 1 --!!! move_to +1 +1
            end
            self_board[castling_to] = self_board[castling_from]
            self_board[castling_from] = false
        end

        return move
    end

    -----
    local function insufficient_material()
        local pieces = {}
        local bishops = {} --array
        local num_pieces = 0
        local sq_color = 0

        local i = SQUARES.a8
        repeat
            sq_color = (sq_color + 1) % 2
            if bit.band(i, 0x88) ~= 0 then
                i = i + 8
            else
                local piece = self_board[i + 1] --!!!
                if piece then
                    local piece_type = piece.type
                    local p = pieces[piece_type]
                    pieces[piece_type] = p and p + 1 or 1
                    if piece_type == BISHOP then
                        table.insert(bishops, sq_color)
                    end
                    num_pieces = num_pieces + 1
                end
                ---
                i = i + 1
            end
        until i > SQUARES.h1

        -- k vs. k
        if num_pieces == 2 then
            return true
        elseif num_pieces == 3 and (pieces[BISHOP] == 1 or pieces[KNIGHT] == 1) then
            -- k vs. kn .... or .... k vs. kb
            return true
        elseif num_pieces == pieces[BISHOP] + 2 then
            -- kb vs. kb where any number of bishops are all on the same color
            local sum = 0
            local len = #bishops
            for _, v in ipairs(bishops) do --!!
                sum = sum + v
            end
            if sum == 0 or sum == len then
                return true
            end
        end

        return false
    end

    local function in_threefold_repetition()
        -- TODO: while this function is fine for casual use, a better
        -- implementation would use a Zobrist key (instead of FEN). the
        -- Zobrist key would be maintained in the make_move/undo_move functions,
        -- avoiding the costly that we do below.
        --
        local moves = {} --array
        local positions = {}
        local repetition = false

        while true do
            local move = undo_move()
            if not move then break end
            table.insert(moves, move)
        end

        for _, m in ipairs(moves) do
            -- remove the last two fields in the FEN string, they're not needed
            -- when checking for draw by rep
            local fen = table.concat(str_split(generate_fen(), ' '), ' ', 1, 4)

            -- has the position occurred three or move times
            local p = positions[fen]
            positions[fen] = p and p + 1 or 1
            if positions[fen] >= 3 then
                repetition = true
            end
            make_move(m)
        end

        return repetition
    end

    -----
    local function build_move(board, from, to, flags, promotion)
        --board は、self_board です
        local move = {
            color = self_turn,
            from = from,
            to = to,
            flags = flags,
            piece = board[from + 1].type --!!!
        }

        if promotion then
            move.flags = bit.bor(move.flags, BITS.PROMOTION)
            move.promotion = promotion
        end
        --!!!
        local board_to = board[to + 1]
        if board_to then
            move.captured = board_to.type
        elseif bit.band(flags, BITS.EP_CAPTURE) ~= 0 then
            move.captured = PAWN
        end
        return move
    end

    local function generate_moves(options) --: array
        local function add_move(board, moves, from, to, flags)
            --board は、self_board です
            -- if pawn promotion --!!!
            if board[from + 1].type == PAWN and (rank(to) == RANK_8 or rank(to) == RANK_1) then
                local pieces = { QUEEN, ROOK, BISHOP, KNIGHT } --array<string>
                for _, p in ipairs(pieces) do
                    table.insert(moves, build_move(board, from, to, flags, p))
                end
            else
                table.insert(moves, build_move(board, from, to, flags))
            end
            -- return moves
        end

        local moves = {} --array
        local us = self_turn
        local them = swap_color(us)
        local second_rank = { b = RANK_7, w = RANK_2 }

        local first_sq = SQUARES.a8
        local last_sq = SQUARES.h1
        local single_square = false

        -- do we want legal moves?
        local legal = true

        if type(options) == 'table' then
            legal = options.legal
            -- are we generating moves for a single square?
            local sq = SQUARES[options.square]
            if sq then
                first_sq = sq
                last_sq = sq
                single_square = true
            else
                return {} --array
            end
        end

        local i = first_sq
        repeat
            -- did we run off the end of the board
            if bit.band(i, 0x88) ~= 0 then
                i = i + 8
            else
                local idx = i + 1
                local piece = self_board[idx] --!!!
                if piece and piece.color == us then

                    if piece.type == PAWN then
                        local PAWN_OFFSETS_us = PAWN_OFFSETS[us]
                        -- single square, non-capturingy
                        local square = i + PAWN_OFFSETS_us[1] --!!!
                        if not self_board[square + 1] then --!!!
                            add_move(self_board, moves, i, square, BITS.NORMAL)
                            -- double square
                            local square = i + PAWN_OFFSETS_us[2] --!!!
                            if second_rank[us] == rank(i) and not self_board[square + 1] then --!!!
                                add_move(self_board, moves, i, square, BITS.BIG_PAWN)
                            end
                        end

                        -- pawn captures 
                        for j = 3, 4 do --!!!
                            local square = i + PAWN_OFFSETS_us[j]
                            if bit.band(square, 0x88) == 0 then
                                local enemy = self_board[square + 1]--!!!
                                if enemy and enemy.color == them then
                                    add_move(self_board, moves, i, square, BITS.CAPTURE)
                                elseif square == self_ep_square then
                                    add_move(self_board, moves, i, self_ep_square, BITS.EP_CAPTURE)
                                end
                            end
                        end
                    else
                        local offsets = PIECE_OFFSETS[piece.type]
                        for _, offset in ipairs(offsets) do --!!!
                            local square = i
                            while (true) do -- 俥 相 后
                                square = square + offset
                                if bit.band(square, 0x88) ~= 0 then break end
                                local enemy = self_board[square + 1] --!!!
                                if not enemy then
                                    add_move(self_board, moves, i, square, BITS.NORMAL)
                                else
                                    if enemy.color == us then break end
                                    add_move(self_board, moves, i, square, BITS.CAPTURE)
                                    break
                                end
                                -- break, if knight or king 
                                if piece.type == 'n' or piece.type == 'k' then break end
                            end
                        end
                    end
                end
                -------------
                i = i + 1
            end
        until i > last_sq

        -- check for castling if: a) we're generating all moves, or b) we're doing
        -- single square move generation on the king's square
        if not single_square or last_sq == self_kings[us] then
            -- king-side castling 
            if bit.band(self_castling[us], BITS.KSIDE_CASTLE) ~= 0 then
                local castling_from = self_kings[us]
                local castling_to = castling_from + 2

                --!!!
                if
                not self_board[castling_from + 2] and
                not self_board[castling_to + 1] and
                not attacked(them, self_kings[us]) and
                not attacked(them, castling_from + 1) and
                not attacked(them, castling_to)
                then
                    add_move(self_board, moves, self_kings[us], castling_to, BITS.KSIDE_CASTLE);
                end
            end

            -- queen-side castling
            if bit.band(self_castling[us], BITS.QSIDE_CASTLE) ~= 0 then
                local castling_from = self_kings[us]
                local castling_to = castling_from - 2
                --!!!
                if
                not self_board[castling_from] and
                not self_board[castling_from - 1] and
                not self_board[castling_from - 2] and
                not attacked(them, self_kings[us]) and
                not attacked(them, castling_from - 1) and
                not attacked(them, castling_to)
                then
                    add_move(self_board, moves, self_kings[us], castling_to, BITS.QSIDE_CASTLE)
                end
            end
        end

        -- return all pseudo-legal moves (this includes moves that allow the king
        -- to be captured)
        if not legal then
            return moves
        end

        -- filter out illegal moves
        local legal_moves = {} --array
        for _, m in ipairs(moves) do
            make_move(m);
            if not king_attacked(us) then
                table.insert(legal_moves, m)
            end
            undo_move()
        end

        return legal_moves
    end

    local function in_checkmate()
        local is_in_check = in_check()
        if is_in_check then
            local moves = generate_moves()
            return #moves == 0
        end
        return false
    end

    local function in_stalemate()
        local is_in_check = in_check()
        if not is_in_check then
            local moves = generate_moves()
            return #moves == 0
        end
        return false
    end

    -- convert a move from 0x88 coordinates to Standard Algebraic Notation
    -- (SAN)
    --
    -- @param {boolean} sloppy Use the sloppy SAN generator to work around over
    -- disambiguation bugs in Fritz and Chessbase.  See below:
    --
    -- r1bqkbnr/ppp2ppp/2n5/1B1pP3/4P3/8/PPPP2PP/RNBQK1NR b KQkq - 2 4
    -- 4. ... Nge7 is overly disambiguated because the knight on c6 is pinned
    -- 4. ... Ne7 is technically the valid SAN
    local function move_to_san(move, sloppy)
        local output = ''

        local move_flags = move.flags -- or 0 --???
        if bit.band(move_flags, BITS.KSIDE_CASTLE) ~= 0 then
            output = 'O-O'
        elseif bit.band(move_flags, BITS.QSIDE_CASTLE) ~= 0 then
            output = 'O-O-O'
        else
            local disambiguator = get_disambiguator(move, sloppy)
            local move_piece = move.piece
            if move_piece ~= PAWN then
                output = output .. move_piece:upper() .. disambiguator
            end

            if bit.band(move_flags, bit.bor(BITS.CAPTURE, BITS.EP_CAPTURE)) ~= 0 then
                if move_piece == PAWN then
                    output = output .. algebraic(move.from):sub(1, 1) --!!!
                end
                output = output .. 'x'
            end

            output = output .. algebraic(move.to);

            if bit.band(move_flags, BITS.PROMOTION) ~= 0 then
                output = output .. '=' + move.promotion.upper()
            end
        end

        make_move(move)
        if in_check() then
            if in_checkmate() then
                output = output .. '#'
            else
                output = output .. '+'
            end
        end
        undo_move();

        return output;
    end

    -------------------------------------------------
    -- convert a move from Standard Algebraic Notation (SAN) to 0x88 coordinates
    local function move_from_san(move, sloppy)
        -- strip off any move decorations: e.g Nf3+?!
        local clean_move = stripped_san(move)

        -- if we're using the sloppy parser run a regex to grab piece, to, and from
        -- this should parse invalid SAN like: Pe2-e4, Rc1c4, Qf3xf7
        local piece, from, to, promotion
        if sloppy then
            piece, from, to, promotion = clean_move:match("([pnbrqkPNBRQK]?)([a-h][1-8])x?%-?([a-h][1-8])([qrbnQRBN]?)")
        end

        local moves = generate_moves()
        -- local i = 0
        --moves : array
        for _, v in ipairs(moves) do
            -- try the strict parser first, then the sloppy parser if requested
            -- by the user
            if (clean_move == stripped_san(move_to_san(v))) or (sloppy and clean_move == stripped_san(move_to_san(v, true)))
            then
                return v
            else
                if (not piece or piece:lower() == v.piece)
                and SQUARES[from] == v.from and SQUARES[to] == v.to
                and (not promotion or promotion:lower() == v.promotion) then
                    return v
                end
            end
        end

        return
    end
    -----------------------------------------------------------------------------
    -- UTILITY FUNCTIONS
    -----------------------------------------------------------------------------
    --- pretty = external move object
    local function make_pretty(ugly_move)
        local move = clone(ugly_move)
        move.san = move_to_san(move, false)
        move.to = algebraic(move.to)
        move.from = algebraic(move.from)

        local flags = ''

        for flag, v in pairs(BITS) do
            if bit.band(v, move.flags) ~= 0 then
                flags = flags + FLAGS[flag]
            end
        end
        move.flags = flags

        return move
    end


    -----------------------------------------------------------------------------
    -- DEBUGGING UTILITIES
    -----------------------------------------------------------------------------
    local function perft(depth)
        local moves = generate_moves({ legal = false })
        local nodes = 0
        local color = turn

        --moves : array
        for k, v in ipairs(moves) do
            make_move(v)
            if not king_attacked(color) then
                if depth - 1 > 0 then
                    local child_nodes = perft(depth - 1)
                    nodes = nodes + child_nodes
                else
                    nodes = nodes + 1
                end
            end
            undo_move()
        end

        return nodes
    end
    -------------------------------------------
    --- if the user passes in a fen string, load it, else default to
    ---  starting position
    load(start_fen or DEFAULT_POSITION)
    -------------------------------------------
    --- PUBLIC API
    -------------------------------------------
    return obj
end

local _M = {}
setmetatable(_M, { __index = Chess, __call = function(self, ...)
    return self:create(...)
end
})
-- return _M-- for k,v in pairs(gen_squares()) do print(k,rank(k),file(k),algebraic(k),v,type(v)) end-- print(#gen_squares())-- for k=0,SQUARES.h1 do print(k,rank(k),file(k),algebraic(k)) end        