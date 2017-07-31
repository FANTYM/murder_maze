ENT.Base = "base_entity"
ENT.Type = "anim"

ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_OPAQUE

function ENT:SetupDataTables()

	self:NetworkVar( "Entity", 0, "Block" )
	self:NetworkVar( "Bool", 1, "IsExit")
	self:NetworkVar( "String", 2, "Level")
	self:NetworkVar( "String", 3, "Direction" )
	
	
	if SERVER then
		self:SetIsExit(false)
	end

end