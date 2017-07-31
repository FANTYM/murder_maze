
ENT.Base = "base_entity"
ENT.Type = "anim"

ENT.Spawnable = true
ENT.AdminOnly = false
ENT.RenderGroup = RENDERGROUP_NONE

ENT.roundTypes = {}
ENT.roundTypes["pre_round"] = 0
ENT.roundTypes["in_round"] = 1
ENT.roundTypes["open_round"] = 2
ENT.roundTypes["between_round"] = 3


function ENT:SetupDataTables()

	self:NetworkVar( "Int", 0, "RoundStart" )
	self:NetworkVar( "Int", 1, "RoundLength" )
	self:NetworkVar( "Int", 2, "TimeLeft" )
	self:NetworkVar( "String", 3, "CurrentTitle")
	self:NetworkVar( "String", 4, "RoundID")

end

function ENT:GetFormattedTime(differenceThis)

	if differenceThis then
		return string.FormattedTime(differenceThis - self:GetTimeLeft(), "%02i:%02i")
	else
		return string.FormattedTime(self:GetTimeLeft(), "%02i:%02i")
	end
	
end