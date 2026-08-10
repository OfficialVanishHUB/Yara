local a = game:GetService("HttpService")

local function b(inviteCode)
    local c = {
        cmd = "INVITE_BROWSER",
        nonce = a:GenerateGUID(false),
        args = {code = inviteCode}
    }
    
    local d = {
        Url = "http://127.0.0.1:6463/rpc?v=1",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Origin"] = "https://discord.com"
        },
        Body = a:JSONEncode(c)
    }
    
    local e, result = pcall(function()
        if syn and syn.request then
            return syn.request(d)
        elseif http and http.request then
            return http.request(d)
        elseif request then
            return request(d)
        else
            if setclipboard then
                setclipboard("https://discord.gg/" .. inviteCode)
                print("Invite copied: https://discord.gg/" .. inviteCode)
            end
            return nil
        end
    end)
    
    if not e then
        print("Failed to send request: " .. tostring(result))
    end
    
    return e, result
end

b("B53jMmSqwR")

task.wait(1)

local supportedgames = {
	[11379739543] = function()
        print("JNKIE - Timebomb Duels Script")
		loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/0af7a426cb44769b1784cf7cbd7d3c685f467c9108de6d0dfa3a4a24dc180ca6/download"))()
	end,

	[15784744207] = function()
        print("JNKIE - Valley Prison Script")
		loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/8534fca05bc6cc0d25df52c0662dcbc4db15f1c0239be3a4f9133afff79c1ba7/download"))()
	end,

	[12355337193] = function()
        print("JNKIE - MVSD Script")
		loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/b3c33916426c9176875a477fc3f05d48b18daa23d431d1f125c4721df7644eeb/download"))()	
	end,
}
local game = game.PlaceId
local lasionisbad = supportedgames[game]
if lasionisbad then
	lasionisbad()
end
