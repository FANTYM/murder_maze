
ENT.Base = "base_entity"
ENT.Type = "anim"

ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT



function ENT:SetupDataTables()

	self:NetworkVar( "Bool", 0, "MazeExisits" )
	self:NetworkVar( "Bool", 1, "OpenMap" )
	self:NetworkVar( "Bool", 2, "CloseMap" )
	
	--self:NetworkVar( "Vector", 1, "OffsetPos")
	

end

