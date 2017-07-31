
include( "shared.lua" )

--[[---------------------------------------------------------
	Name: Initialize
	Desc: First function called. Use to set up your entity
-----------------------------------------------------------]]
function ENT:Initialize()

	self.lightLevel = 0.9
	
	----PrintTable(self:GetAttachments())
	self.lightPos = self:GetAttachment(self:LookupAttachment("room_light")).Pos
	--self.lightColor = self.roomColors[math.ceil(math.random() * #self.roomColors)] --Vector( math.floor(math.random() * 256),
							  --math.floor(math.random() * 256),
						      --math.floor(math.random() * 256) )
	--*self.lightColor = self:GetColor()
	self.lightFlux = 0.4
	self.osc = -180
	
	self:makeCSModel()
	
	timer.Simple(1, function() if IsValid(self) then self:doFlux() end end)
	
	
end


function ENT:makeCSModel()

	self.csModel = ClientsideModel(self:GetModel())
	self.csModel.owner = self
	self.csModel:SetNoDraw(true)

	
end

function ENT:KillCSModelOnRemove(csModel)
	
	if !IsValid(self) then
		if csModel then
			if csModel.Remove then
				csModel:Remove()
				return
			end
		end
	end
	
	timer.Simple(1, function() self:KillCSModelOnRemove(self.csModel) end)

end

function ENT:OnRemove()
	
	if self.csModel then
		self.csModel:Remove()
	end

end

function ENT:doFlux()

	if !IsValid(self) then return end

	self.lightFlux = ( -0.5 + ( math.random() * 1 ) )
	
	if !self.osc then self.osc = -180 end
	
	self.osc = self.osc + 1
	
	if self.osc > 179 then
		self.osc = -180
	end
	
	local timeInt = 0.75 + ( 3 * (self.osc / 180))
	
	
	timer.Simple(timeInt, function() if IsValid(self) then self:doFlux() end end)
	
end

--[[---------------------------------------------------------
	Name: OnRestore
	Desc: Called immediately after a "load"
-----------------------------------------------------------]]
function ENT:OnRestore()

end



function ENT:Draw() --Translucent()
	
	local entDist = (LocalPlayer():GetPos() - self:GetPos()):Length()
	
	if ( entDist > 1584) then return end
	
	----print(tostring(self) .. " dist to player: " .. tostring(entDist) .. " - Drawing...")
	
	self.lightLevel = 1 + self.lightFlux
	
	render.SuppressEngineLighting(true)
	
		render.SetLightingOrigin(self.lightPos)
		
		render.ResetModelLighting( 0.0, 0.0, 0.0 )
		
		lightInfo = {}
		lightInfo.type = MATERIAL_LIGHT_POINT
		lightInfo.color = (self:colorToVector(self:GetColor()) * self.lightLevel) * 0.25
		lightInfo.pos = self.lightPos

		lightInfo.fiftyPercentDistance = 13.5
		lightInfo.zeroPercentDistance = 27
		lightInfo.quadraticFalloff = 1
		lightInfo.linearFalloff = 1
		lightInfo.constantFalloff = 0
		
		render.SetLocalModelLights({lightInfo})
		render.SetModelLighting( BOX_TOP,  lightInfo.color.x * 0.0025, lightInfo.color.y * 0.0025 , lightInfo.color.z * 0.0025 )
		render.SetModelLighting( BOX_BOTTOM, lightInfo.color.x * 0.0025, lightInfo.color.y * 0.0025 , lightInfo.color.z * 0.0025 )
		
		self:DrawModel()
	
	render.SuppressEngineLighting(false)
	
end

function ENT:colorToVector(clr)

	
	return Vector(clr.r, clr.g, clr.b)

end