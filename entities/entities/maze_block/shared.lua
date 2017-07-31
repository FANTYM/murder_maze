ENT.Base = "base_entity"
ENT.Type = "anim"

ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.dirEnum = {}
ENT.dirEnum.NORTH = 1
ENT.dirEnum.SOUTH = 2
ENT.dirEnum.EAST  = 4
ENT.dirEnum.WEST  = 8

ENT.roomColors = { Vector( 255, 128, 128),
				   Vector( 128, 255, 128),
				   Vector( 128, 128, 255),
				   Vector( 255, 255, 128),
				   Vector( 255, 255, 255)
				 }

function ENT:SetupDataTables()

	self:NetworkVar( "String", 1, "BlockType" )
	self:NetworkVar( "Bool", 2, "HasExit" )
	self:NetworkVar( "Entity", 3, "ExitDoor" )	
	
end

function ENT:Think()

	self:NextThink(CurTime() + 9000)
	
end