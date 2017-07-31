ENT.Base = "base_entity"
ENT.Type = "anim"

ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_NONE

function ENT:SetupDataTables()

	self:NetworkVar( "Int", 0, "RoundStart" )
	self:NetworkVar( "Int", 1, "RoundLength" )
	self:NetworkVar( "Int", 2, "TimeLeft" )
	self:NetworkVar( "String", 3, "CurrentTitle")

end

function ENT:GetFormattedTime(differenceThis)

	if differenceThis then
		return string.FormattedTime(differenceThis - self:GetTimeLeft(), "%02i:%02i")
	else
		return string.FormattedTime(self:GetTimeLeft(), "%02i:%02i")
	end
	
end