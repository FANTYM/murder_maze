
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

--[[---------------------------------------------------------
	Name: Initialize
	Desc: First function called. Use to set up your entity
-----------------------------------------------------------]]
function ENT:Initialize()

	self:SetModel("models/mm/maze_door.mdl")
	--self:PhysicsInit(SOLID_VPHYSICS)
	--self:PhysicsInitStatic(SOLID_VPHYSICS)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:PhysicsInitShadow(false, false)
	--self:SetSolid(SOLID_VPHYSICS)
	--self:SetMoveType(MOVETYPE_NONE)
	self:SetCollisionGroup( COLLISION_GROUP_NONE )
	self:SetCustomCollisionCheck(true)

	self.attachments = self:GetAttachments()
	
	----print("------------------- Attachments ---------------------")
	----PrintTable(self.attachments)
	
	--for k, attach in pairs(attachments) do
		
		
	--end
	
	
	self:SetTrigger( true )
	
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

	if self:GetIsExit() then
		
		if ent && IsValid(ent) && ent:IsPlayer() then
		
			--PrintMessage(HUD_PRINTCENTER, ent:GetName() .. " has foud the exit in " .. GAMEMODE.roundEnt:GetFormattedTime(GAMEMODE.roundEnt:GetRoundLength()) .. " !! ")
			GAMEMODE:SendHudMessage( ent:GetName() .. " has foud the exit in " .. GAMEMODE.roundEnt:GetFormattedTime(GAMEMODE.roundEnt:GetRoundLength()) .. " !! ", 1)
			--print("Teleporting " .. tostring(ent) .. " out of the maze.")
			
			GAMEMODE:TeleportToExit(ent)
			GAMEMODE:RegisterPlayerFinished(ent)
	
			if GAMEMODE.roundEnt:GetTimeLeft() > 30 then
				GAMEMODE.roundEnt:createRound("ending", 30,"This maze has been solved, hurry up and finish before it closes!!!" , 0.25, false, function()  GAMEMODE:DestroyMaze() GAMEMODE:AwardPrizes() GAMEMODE:SaveAllPlayers()  end, true )
				GAMEMODE.roundEnt:ChangeRound(true)
			end
		
			----print("Destroying the maze in 10 seconds.")
			--GAMEMODE:DestroyMaze(10)
		end
		
	end
	
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

function ENT:openDoor()

	self:GetBlock():SetDoor(self.level, self.dir, false)

end

function ENT:Think()

	self:NextThink(CurTime() + 900)
end