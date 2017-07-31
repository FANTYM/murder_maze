
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

--[[---------------------------------------------------------
	Name: Initialize
	Desc: First function called. Use to set up your entity
-----------------------------------------------------------]]
function ENT:Initialize()

	self:SetMoveType(MOVETYPE_NONE)
	
	self:SetRoundStart(CurTime())
	self:SetRoundLength(30)
	
	self.currentRound = {}
	
	self.roundQueue = {}

	self:createRound( "between", 30, "Intermission", 2, true, function()GAMEMODE:GenerateMazeLive() end)
	self:createRound( "pre", 20, { "Maze Open, enter the teleport." }, 1, true, function() GAMEMODE:CloseEntrance()  end)
	self:createRound( "in", 30,  "Welcome to the Murder Maze!!!!", -1, true, function() GAMEMODE:DestroyMaze() GAMEMODE:AwardPrizes() GAMEMODE:SaveAllPlayers() end)
	
	self:ChangeRound()
	
end

function ENT:CreateRoundID()
	
	----print("CreateRoundID")
	local rndSeed = math.random()
	----print("rndSeed: " .. tostring(rndSeed))
	local rndStr = tostring(math.floor(rndSeed * 100000000))
	----print("rndStr: " .. tostring(rndStr))
	local rndStart = math.floor(math.random() * (string.len(rndStr) * 0.25))
	local subStr = rndStr:sub(	2 + rndStart, 
								rndStart + 4)
								
	----print("subStr: " .. tostring(subStr))
	
	local asNum = tonumber(subStr)
	
	asNum = ((asNum * 3) * ((string.len(rndStr) - string.len(subStr)) * (string.len(rndStr) - string.len(subStr))) * math.pi) * 1000000000
	
	----print("asNum: " .. tostring(asNum))
	
	local asHex = bit.tohex(asNum)
	
	----print("asHex: " .. tostring(asHex))
	
	return asHex
	
end

function ENT:createRound( roundTitle, roundLength, startText, textRepeatRate, reQueue, roundFunc, makeNext )

	local newRound = {}
	
	newRound.rTitle = roundTitle
	newRound.rLen = roundLength
	newRound.sText = startText
	newRound.rFunc = roundFunc
	newRound.rQueue = reQueue
	newRound.repRate = textRepeatRate
	newRound.lastText = CurTime()
	
	if makeNext then
		table.insert(self.roundQueue, 1, newRound)
	else
		table.insert(self.roundQueue, newRound)
	end

end

function ENT:SetRoundTimeByName(roundName, newTime)
	
	for k, round in pairs(self.roundQueue) do
	
		if round.rTitle == roundName then
			round.rLen = newTime
		end
	
	end
	

end

function ENT:SetNextRoundTime(newTime)
	
	if #self.roundQueue > 0 then
		self.roundQueue[1].rLen = newTime
	end

end

function ENT:SetCurrentRoundTime(newTime)
	
	self.currentRound.rLen = newTime
	self:GetRoundLength(newTime)

end

function ENT:ChangeRound(skipFuncAtEnd)
	
	
	local newID = self:CreateRoundID()
	
	if !skipFuncAtEnd then
		if self.currentRound.rFunc then
			self.currentRound.rFunc()
		end
	end
	
	local nextRound = self.roundQueue[1]
	
	if (nextRound != nil) then
		table.remove(self.roundQueue, 1)
		
		if nextRound.rQueue then
			table.insert(self.roundQueue, nextRound)
		end
		
		self.currentRound = nextRound
		
		self.currentRound.roundID = newID
		
		self:SetRoundID(newID)
		
		self:SetCurrentTitle(nextRound.rTitle)
		
		self:SetRoundStart(CurTime())
		self:SetRoundLength(nextRound.rLen)
		self:SetTimeLeft(nextRound.rLen)
		
		if type(nextRound.sText) == "table" then
			--PrintMessage(HUD_PRINTCENTER, self:ProcessTextTable(nextRound.sText))
			GAMEMODE:SendHudMessage( self:ProcessTextTable(nextRound.sText), 0.25)
		else
			--PrintMessage(HUD_PRINTCENTER, nextRound.sText)
			GAMEMODE:SendHudMessage( nextRound.sText, 0.25)
		end
		
		self.currentRound.lastText = CurTime()
		
	end
	
end

function ENT:ProcessTextTable(tTable)
	
	local outStr = ""
	
	for k, v in pairs(tTable) do
		
		if v == "#" then
			outStr = outStr .. self:GetFormattedTime()
		else
			outStr = outStr .. v
		end
	end
	
	return outStr
	
end

function ENT:Think()
	
	----PrintTable(self.currentRound)
	local changeRound = false
	
	GAMEMODE.roundEnt = self
	
	self:SetTimeLeft((self:GetRoundStart() + self:GetRoundLength()) - CurTime())
	----print(self:GetTimeLeft())
	if self:GetTimeLeft() <= 0 then
		changeRound = true
	end
	
	if CurTime() < (self.currentRound.lastText + self.currentRound.repRate) then
		
		--if (self:GetTimeLeft() % self.currentRound.repRate) == 0 then
			if type(self.currentRound.sText) == "table" then
				--PrintMessage(HUD_PRINTCENTER, self:ProcessTextTable(self.currentRound.sText))
				GAMEMODE:SendHudMessage( self:ProcessTextTable(self.currentRound.sText), 0.25)
			else
				--PrintMessage(HUD_PRINTCENTER, self.currentRound.sText)
				GAMEMODE:SendHudMessage( self.currentRound.sText, 0.25)
			end
		--end
		
		self.currentRound.lastText = CurTime()
		
	end
	
	if changeRound then self:ChangeRound() end
	
	self:NextThink(CurTime()) -- + 0.0125)
end

--[[---------------------------------------------------------
	Name: KeyValue
	Desc: Called when a keyvalue is added to us
-----------------------------------------------------------]]
function ENT:KeyValue( key, value )
	self[key] = value
end

--[[---------------------------------------------------------
	Name: OnRestore
	Desc: The game has just been reloaded. This is usually the right place
		to call the GetNW* functions to restore the script's values.
-----------------------------------------------------------]]
function ENT:OnRestore()
end

--[[---------------------------------------------------------
	Name: AcceptInput
	Desc: Accepts input, return true to override/accept input
-----------------------------------------------------------]]
function ENT:AcceptInput( name, activator, caller, data )
	

	
end


function ENT:StartTouch( ent )

	
end
--[[---------------------------------------------------------
	Name: UpdateTransmitState
	Desc: Set the transmit state
-----------------------------------------------------------]]
function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end


function ENT:PhysicsSimulate( phys, deltatime )

	
	return 0, 0, SIM_NOTHING

end