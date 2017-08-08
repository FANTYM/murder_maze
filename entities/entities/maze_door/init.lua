AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function ENT:Initialize()

	self:SetModel("models/mm/maze_door.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:PhysicsInitShadow(false, false)
	self:SetCollisionGroup( COLLISION_GROUP_NONE )
	self:SetCustomCollisionCheck(true)
	
	self:SetTrigger( true )
	
end

function ENT:StartTouch( ent )

	if self:GetIsExit() then
		
		if ent && IsValid(ent) && ent:IsPlayer() then
				
			GAMEMODE:TeleportToExit(ent)
			GAMEMODE:RegisterPlayerFinished(ent)
	
			if mmGlobals.roundEntity:GetTimeLeft() > 30 then
				mmGlobals.roundEntity:createRound("ending", 30,"This maze has been solved, hurry up and finish before it closes!!!" , 0.25, false, function()  GAMEMODE:DestroyMaze() GAMEMODE:AwardPrizes() GAMEMODE:SaveAllPlayers()  end, true )
				mmGlobals.roundEntity:ChangeRound(true)
			end
			
		end
		
	end
	
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:PhysicsSimulate( phys, deltatime )

	return 0, 0, SIM_NOTHING

end

function ENT:openDoor()

	self:GetBlock():SetDoor(self.level, self.dir, false)

end

function ENT:Think()

	self:NextThink(CurTime() + 900)
end