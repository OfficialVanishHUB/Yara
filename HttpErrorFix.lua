--vonalia
--httpt error fix

local supportedgames = {
	[11379739543] = function()
    --timebomb duels
    loadstring(game:HttpGet("https://vonalia.com/api/v1/scripts/1785767829811"))()
	end,

	[15784744207] = function()
    --valley prison
    loadstring(game:HttpGet("https://vonalia.com/api/v1/scripts/1785767770019"))()
	end,
}
local game = game.PlaceId
local lasionisbad = supportedgames[game]
if lasionisbad then
	lasionisbad()
end
