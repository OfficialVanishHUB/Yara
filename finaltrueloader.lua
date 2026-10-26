--[[
	Vanish HUB loader — Arqel ("Junkie-style") edition.

	Ported to the same Arqel UI + delivery-endpoint pattern as the Junkie loader:
	  1. Wait for the game to load; kick with a clean message on unsupported places.
	  2. Load the Arqel UI from cdn.jnkie.com, themed for Vanish HUB
	     (key screen, user info panel, premium shop footer).
	  3. After LaunchJunkie resolves a key, POST it to the delivery endpoint,
	     GET the returned script URL and execute it.
]]

if not game:IsLoaded() then
	game.Loaded:Wait()
end

--==================================================================--
-- Config
--==================================================================--

-- public script hashes, index-matched to PLACE_MAP
local SCRIPTS = {
	"527d32d0445fbd834480d1db8051b64a9e7f9af993b5139a5658f9931e5e7c57", -- 1: Driving Empire
	"0af7a426cb44769b1784cf7cbd7d3c685f467c9108de6d0dfa3a4a24dc180ca6", -- 2: Timebomb Duels
	"74382b9df345339e2ac5f877eef1c08a3beb8d70a04b038ea131a46d1a2dc27f" -- 3: Break and Steal an Egg
}

local PLACE_MAP = {
	[3351674303] = 1, -- Driving Empire
	[11379739543] = 2, -- Timebomb Duels
	[114326934417838] = 3 -- Break and Steal an Egg
}

-- premium beta hash appended to the delivery URL per script index
local PREMIUM_PARAM = {
	[1] = "&premium=7905ab304ce13a586053a9ef1f069431b26188e19de457d2bc77ca99b6feaea2",
	[2] = "&premium=7905ab304ce13a586053a9ef1f069431b26188e19de457d2bc77ca99b6feaea2"
}

--==================================================================--
-- Unsupported game -> kick with a styled message
--==================================================================--

local scriptIndex = PLACE_MAP[game.PlaceId]
if not scriptIndex then
	local message = "Unsupported game"
	warn(message)
	task.spawn(function()
		pcall(function()
			game:GetService("Players").LocalPlayer:Kick(message)
		end)
		task.wait()
		pcall(function()
			local prompt = game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ErrorPrompt
			prompt.TitleFrame.ErrorTitle.Text = "Vanish HUB"
			prompt.MessageArea.ErrorFrame.ErrorMessage.Text = message
		end)
	end)
	return
end

--==================================================================--
-- Arqel UI (Junkie-style key system)
--==================================================================--

-- https://github.com/Cobruhehe/expert-octo-doodle
local Arqel = loadstring(game:HttpGet("https://cdn.jnkie.com/arquelui.lua"))()

Arqel.Appearance.Title = "Vanish"
Arqel.Appearance.Icon = "rbxassetid://134697043118282"
Arqel.Links.Discord = "Discord.gg/jnkie"
Arqel.Storage.FileName = "Vanish_key"
-- Arqel.Options.KeylessUI = true

Arqel.Theme.Accent = Color3.fromRGB(139, 92, 246)
Arqel.Theme.AccentHover = Color3.fromRGB(167, 139, 250)
Arqel.Theme.Background = Color3.fromRGB(10, 10, 20)
Arqel.Theme.Header = Color3.fromRGB(15, 15, 30)
Arqel.Theme.Input = Color3.fromRGB(20, 20, 40)
Arqel.Theme.Text = Color3.fromRGB(255, 255, 255)
Arqel.Theme.TextDim = Color3.fromRGB(160, 160, 200)
Arqel.Theme.Success = Color3.fromRGB(0, 220, 180)
Arqel.Theme.Error = Color3.fromRGB(255, 70, 90)
Arqel.Theme.StatusIdle = Color3.fromRGB(120, 100, 200)

Arqel.Shop = {
	Enabled = true,
	Icon = "",
	Title = "Get Premium",
	Subtitle = "Instant delivery • 24/7 support",
	ButtonText = "Buy",
	Link = "vanish.nyc"
}

Arqel:LaunchJunkie({
	Service = "Vanish HUB",
	Identifier = "1167505",
	Provider = "Vanish HUB"
})

--==================================================================--
-- Delivery: POST the key, GET the returned script URL, execute
--==================================================================--

do
	local key = getgenv().SCRIPT_KEY or SCRIPT_KEY or ""
	if type(key) ~= "string" then
		key = ""
	end

	local genericError = "Could not load the script. Check your internet connection and try again later."

	local function fail(message)
		warn(message)
		task.spawn(function()
			pcall(function()
				game:GetService("Players").LocalPlayer:Kick(message)
			end)
			task.wait()
			pcall(function()
				local prompt = game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ErrorPrompt
				prompt.TitleFrame.ErrorTitle.Text = "Vanish HUB"
				prompt.MessageArea.ErrorFrame.ErrorMessage.Text = message
			end)
		end)
	end

	-- normalize the request function across executors
	local httpRequest = (type(syn) == "table" and type(syn.request) == "function" and syn.request)
		or (type(request) == "function" and request)
		or (type(http_request) == "function" and http_request)
		or (type(http) == "table" and type(http.request) == "function" and http.request)
	if type(httpRequest) ~= "function" then
		warn(genericError)
		return
	end

	-- request wrapper with a 15s timeout
	local function request(opts)
		local done, ok, response
		task.spawn(function()
			ok, response = pcall(httpRequest, opts)
			done = true
		end)
		local start = os.clock()
		repeat
			task.wait()
		until done or os.clock() - start > 15
		if not done then
			return false, nil
		end
		return ok, response
	end

	-- 1) POST the key to the delivery endpoint
	local ok, response = request({
		Url = "https://api.jnkie.com/api/v1/luascripts/delivery/" .. SCRIPTS[scriptIndex] .. "?v=2&errors=text" .. (PREMIUM_PARAM[scriptIndex] or ""),
		Method = "POST",
		Headers = { ["Content-Type"] = "text/plain" },
		Body = key
	})

	-- structured denial (LDR-DENIED[...]) -> show the server's message
	local denial = ok and type(response) == "table" and type(response.Body) == "string"
		and (response.StatusCode == 400 or response.StatusCode == 401 or response.StatusCode == 403)
		and response.Body
	if denial then
		local code, detail = denial:match("^([^\r\n]+)\n([^\r\n]+)$")
		code = code or denial
		if #code <= 75 and (code == "LDR-DENIED" or code:match("^LDR%-DENIED:[A-Z_]+$")) then
			if not detail or #detail > 512 then
				detail = genericError
				if key == "" or key:match("^%s*$") then
					detail = "No key provided. Get a key from the script provider, enter it, then try again."
				end
			end
			fail(detail .. " (" .. code .. ")")
			return
		end
	end

	if not ok or type(response) ~= "table" or response.StatusCode ~= 200 or type(response.Body) ~= "string" then
		warn(genericError)
		return
	end
	if not (string.sub(response.Body, 1, 8) == "https://") then
		warn(genericError)
		return
	end

	-- 2) fetch the script from the returned URL
	ok, response = request({ Url = response.Body, Method = "GET" })
	if not ok or type(response) ~= "table" or response.StatusCode ~= 200 or type(response.Body) ~= "string" or #response.Body == 0 then
		warn(genericError)
		return
	end

	local source = response.Body
	response = nil
	local chunk = loadstring(source)
	source = nil
	if type(chunk) ~= "function" then
		warn(genericError)
		return
	end
	chunk()
end
