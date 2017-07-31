AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()

	self:SetMoveType(MOVETYPE_NONE)
	self.mazeEnts = {}
	self.haveOpened = false
	self.lastMazeState = false
	
end

function ENT:Think()
	
	GAMEMODE.mapEnt = self
	
	self:NextThink(CurTime() + 1.25)
	
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:PhysicsSimulate( phys, deltatime )
	
	return 0, 0, SIM_NOTHING

end