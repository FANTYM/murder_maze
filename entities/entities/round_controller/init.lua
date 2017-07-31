AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()

	self:SetMoveType(MOVETYPE_NONE)
	
	self.currentRound = {}
	
	self.roundQueue = {}

	self:createRound( "between", 30, "Intermission", 2, true, function() GAMEMODE:GenerateMazeLive() end, false)
	self:createRound( "wait", -1, { "Generating Maze ..." }, 0.5, true, function() end, false, function() return !generatingMaze end)
	self:createRound( "pre", 10, { "Opening maze, hurry to the portal." }, 1, true, function() GAMEMODE:CloseEntrance()  end, false)
	self:createRound( "in", 3000,  "Welcome to the Murder Maze!!!!", -1, true, function() GAMEMODE:DestroyMaze() GAMEMODE:AwardPrizes() GAMEMODE:SaveAllPlayers() end, false)
	
	self:ChangeRound()
	
end

function ENT:createRound( roundTitle, roundLength, startText, textRepeatRate, reQueue, roundFunc, makeNext, lengthFunction )

	local newRound = {}
	
	newRound.rLen = roundLength
	newRound.lenFunc = lengthFunction
	newRound.rTitle = roundTitle
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
	self:SetRoundLength(newTime)

end

function ENT:ChangeRound(skipFuncAtEnd)
	
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
		
		self:SetCurrentTitle(nextRound.rTitle)
		
		self:SetRoundStart(CurTime())
		
		if nextRound.lenFunc then
			nextRound.rLen = math.ceil(math.random() * 9999)
		end
		
		self:SetRoundLength(nextRound.rLen)
		self:SetTimeLeft(self:GetRoundLength())
		
		if type(nextRound.sText) == "table" then
			GAMEMODE:SendHudMessage( self:ProcessTextTable(nextRound.sText), nextRound.repRate)
		else
			GAMEMODE:SendHudMessage( nextRound.sText, nextRound.repRate)
		end
		
		nextRound.lastText = CurTime()
		
		self.currentRound = nextRound
		
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
	
	local changeRound = false
	
	GAMEMODE.roundEnt = self
	
	if self.currentRound.lenFunc then
		if self.currentRound.lenFunc() then
			self:SetTimeLeft(0)
		else
			self:SetTimeLeft(2 + math.ceil(math.random() * 9999))
			self:SetRoundStart(CurTime() + 1)
		end
	else
		self:SetTimeLeft((self:GetRoundStart() + self:GetRoundLength()) - CurTime())
	end
	
	if self:GetTimeLeft() <= 0 then
		changeRound = true
	end
	
	if (self.currentRound.repRate >= 0) && 
	   (CurTime() >= (self.currentRound.lastText + self.currentRound.repRate)) then
		
		if type(self.currentRound.sText) == "table" then
			GAMEMODE:SendHudMessage( self:ProcessTextTable(self.currentRound.sText), self.currentRound.repRate)
		else
			GAMEMODE:SendHudMessage( self.currentRound.sText, self.currentRound.repRate)
		end
		
		self.currentRound.lastText = CurTime()
		
	end
	
	if changeRound then self:ChangeRound() end
	
	self:NextThink(CurTime() + (math.random() * 0.25))
	
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:PhysicsSimulate( phys, deltatime )

	return 0, 0, SIM_NOTHING

end