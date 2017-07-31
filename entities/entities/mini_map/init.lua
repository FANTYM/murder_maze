
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

--[[---------------------------------------------------------
	Name: Initialize
	Desc: First function called. Use to set up your entity
-----------------------------------------------------------]]
function ENT:Initialize()

	self:SetMoveType(MOVETYPE_NONE)
	--self.shouldSendMazeInfo = true
	self.mazeEnts = {}
	self.haveOpened = false
	self.lastMazeState = false
	self:SetOpenMap(false)
	self:SetCloseMap(false)
	self:SetMazeExisits(false)
	
end

function ENT:Think()
	
	GAMEMODE.mapEnt = self
	
	----print("mazeExists?: " .. tostring((GAMEMODE.curMaze != nil)))
	
	local mazeExists = (GAMEMODE.curMaze != nil)
	
	self:SetMazeExisits(mazeExists)
	
	if !inMaze then
	
		local tempEnts = ents.FindByClass("maze_block")
		table.Add(tempEnts, ents.FindByClass("maze_door"))
		
		self.mazeEnts = tempEnts
		
		--self:sendMazeInfo()
		
	end
	
	
	
	if (hasMaze != nil) && (hasMaze != self.lastMazeState) then	
		
		----print("lastMazeState: " .. tostring(self.lastMazeState))
		if hasMaze then
			if GAMEMODE.roundEnt:GetCurrentTitle() == "in" then
				--print("Maze was created, opening map...")
				self:SetOpenMap(true)
				timer.Simple(0.01, function() self:SetOpenMap(false) end)
				self.lastMazeState = hasMaze
			end
		else
			if GAMEMODE.roundEnt:GetCurrentTitle() == "between" then
				--print("Maze was destroyed, closing map...")
				self:SetCloseMap(true)
				timer.Simple(0.01, function() self:SetCloseMap(false) end )
				self.lastMazeState = hasMaze
			end
		end
		
		----print("lastMazeState: " .. tostring(self.lastMazeState))
	end
	
	----print("OpenMap: " .. tostring(self:GetOpenMap()))
	----print("CloseMap: " .. tostring(self:GetCloseMap()))
	
	self:NextThink(CurTime() + 1.25)
	
end
--[[
function ENT:sendMazeInfo( reset , ply)

	if reset then
		
		if ply then
			net.Start("map_info")
				net.WriteInt(0, 32)
			net.Send(ply)
		else
			net.Start("map_info")
				net.WriteInt(0, 32)
			net.Broadcast()
		end
		
		return
		
	end
	
	if ply then
		if !ply.inMaze then
				
				net.Start("map_info")
				net.WriteInt(#self.mazeEnts, 32)
					for k, ent in pairs(self.mazeEnts) do
						
						net.WriteEntity(ent)
						
					end
				net.Send(ply)
			
			end
	else
	
		for pk, ply in pairs(player.GetAll()) do
			
			if !ply.inMaze then
				
				net.Start("map_info")
				net.WriteInt(#self.mazeEnts, 32)
					for k, ent in pairs(self.mazeEnts) do
						
						net.WriteEntity(ent)
						
					end
				net.Send(ply)
			
			end
			
		
		end
	end
	

end
--]]

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