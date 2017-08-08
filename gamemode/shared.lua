GM.Name 	= "Murder Maze"
GM.Author 	= "Fantym420 (Malcolm Greene)"
GM.Email 	= "Fantym420@GMail.Com"
GM.Website 	= ""

DEFINE_BASECLASS( "gamemode_base")



mmGlobals.countDownSounds = {}
mmGlobals.countDownSounds[0] = "npc/overwatch/radiovoice/zero.wav"
mmGlobals.countDownSounds[1] = "npc/overwatch/radiovoice/one.wav"
mmGlobals.countDownSounds[2] = "npc/overwatch/radiovoice/two.wav"
mmGlobals.countDownSounds[3] = "npc/overwatch/radiovoice/three.wav"
mmGlobals.countDownSounds[4] = "npc/overwatch/radiovoice/four.wav"
mmGlobals.countDownSounds[5] = "npc/overwatch/radiovoice/five.wav"
mmGlobals.countDownSounds[6] = "npc/overwatch/radiovoice/six.wav"
mmGlobals.countDownSounds[7] = "npc/overwatch/radiovoice/seven.wav"
mmGlobals.countDownSounds[8] = "npc/overwatch/radiovoice/eight.wav"
mmGlobals.countDownSounds[9] = "npc/overwatch/radiovoice/nine.wav"

-- npc/overwatch/radiovoice/citizen.wav
-- npc/overwatch/radiovoice/quick.wav
-- npc/overwatch/radiovoice/inprogress.wav
-- npc/overwatch/radiovoice/interlock.wav
-- npc/overwatch/radiovoice/apply.wav
-- npc/overwatch/radiovoice/victor.wav
-- npc/overwatch/radiovoice/zone.wav

mmGlobals.items = mmGlobals.items or include("items.lua")

mmGlobals.females  =  { "models/player/group01/female_01.mdl", 
			  "models/player/group01/female_02.mdl",
			  "models/player/group01/female_03.mdl",
			  "models/player/group01/female_04.mdl",
			  "models/player/group01/female_05.mdl",
			  "models/player/group01/female_06.mdl" }
	
mmGlobals.males   =  {  "models/player/group01/male_01.mdl", 
			  "models/player/group01/male_02.mdl",
			  "models/player/group01/male_03.mdl",
			  "models/player/group01/male_04.mdl",
			  "models/player/group01/male_05.mdl",
			  "models/player/group01/male_06.mdl",
			  "models/player/group01/male_07.mdl",
			  "models/player/group01/male_08.mdl",
			  "models/player/group01/male_09.mdl" }
			  
mmGlobals.blockSizes = Vector(528, -528, 216)

mmGlobals.mazeMaxSize = Vector(6,6,0)
mmGlobals.mazeMinSize = Vector(3,3,0)
mmGlobals.mazeCurSize = Vector(0,0,0)

mmGlobals.dirPairs = {}
mmGlobals.dirPairs["d"] = "u"
mmGlobals.dirPairs["u"] = "d"
mmGlobals.dirPairs["e"] = "w"
mmGlobals.dirPairs["w"] = "e"
mmGlobals.dirPairs["n"] = "s"
mmGlobals.dirPairs["s"] = "n"
	
mmGlobals.curMaze = mmGlobals.curMaze or {}
	
function GM:PlayerNoClip( pl, on )
	
	return false --!pl:IsBot() || pl:IsAdmin()
	
end

function getSign(what)
	
	local sign = 1
	
	if what < 0 then
		sign = -1
	end
	
	return sign

end

function makeValueSmoother(startVal, endVal, arriveTime, smoothFunc) 
	
	local nSmoother = {}	
	
	nSmoother.isSmoother = true
	nSmoother.startTime = CurTime()
	nSmoother.endTime = CurTime() + arriveTime
	nSmoother.curDelta = 0.001
	nSmoother.sVal = startVal or 0
	nSmoother.eVal = endVal or 1
	nSmoother.aTime = arriveTime or 1
	nSmoother.lastVal = nSmoother.sVal
	nSmoother.sFunc = smoothFunc or Lerp
	nSmoother.sDir = getSign(startVal - endVal)
	
	function nSmoother:GetValue()
		
		self.curDelta = CurTime() - self.startTime
		self.curPerc = self.curDelta / self.aTime
		self.lastVal = (( 1 - self.curPerc ) * self.sVal) + (self.curPerc * self.eVal)
		
		if self.sDir > 0 then
			
			self.lastVal = math.min(math.max(self.sVal, self.lastVal), self.eVal)
			
		else 
		
			self.lastVal = math.max(math.min(self.eVal, self.lastVal), self.sVal)
		
		end
		
		return self.lastVal
		
	end

	return nSmoother

end

function getMapPos( pos )
	
	
	--plyPos = ply:GetPos() + Vector(0,0,64)
	
	local result = Vector( math.floor((pos.x / mmGlobals.blockSizes.x) + 15), 
						   math.floor((pos.y / mmGlobals.blockSizes.y) + 15), 
						   math.abs(math.floor( pos.z / mmGlobals.blockSizes.z)) )
		
	return result
						   
end

function getWorldPos( pos )
			
	return Vector( (pos.x - 15) * mmGlobals.blockSizes.x,
				   (pos.y - 15) * mmGlobals.blockSizes.y,
				   (pos.z) * mmGlobals.blockSizes.z )
		   
end

function IsInMaze( pos )
	
	if ( pos.x >= 0 && pos.x < mmGlobals.mazeCurSize.x ) &&
	   ( pos.y >= 0 && pos.y < mmGlobals.mazeCurSize.y ) &&
	   ( pos.z >= 0 && pos.z <= 1 ) then
	   
	   return true
	   
	end
	
	return false

end

function makeLen(whatStr, desLen, padChar, addBefore)

	local cLen = string.len(whatStr)
	
	for i = 1, desLen - cLen do
		
		if addBefore then
			whatStr = padChar .. whatStr
		else
			whatStr = whatStr .. padChar
		end
		
	end
	
	return whatStr


end

function GM:StartCommand(ply, cmd)
	
	if !mmGlobals.roundEntity then return end
	
	if ply.inMaze && mmGlobals.roundEntity:GetCurrentTitle() == "pre" then
		
		cmd:SetMouseX(0)
		cmd:SetMouseY(0)		
		cmd:SetViewAngles(Angle(0,0,0))
		cmd:ClearButtons()
		cmd:ClearMovement()
		
	end
	
end

function newMazeCell()

	local mCell = {}
	
		  mCell.isCell = true
		  mCell.u  = false
		  mCell.d  = false
		  mCell.n  = false
		  mCell.s  = false
		  mCell.e  = false
		  mCell.w  = false
		  mCell.visited = false
		  mCell.numVisits = 0
			
	return mCell
	
end

function GM:drawMapToString(level, ply, mazeData)
	
	local dirs = {"n", "w", "u", "d", "e", "s"}
	
	local z = 0
	local x = 0
	local y = 0
	
	mazeData = mazeData or mmGlobals.curMaze
	
	local plyPos = Vector(0,0,0)
	if ply && IsValid(ply) && ply:IsPlayer() then
		plyPos = getMapPos(ply:GetPos() + Vector(0,0,64))
	end
	
	local scanStage = -1
	
	local outStr = ""
	
	if level == "b" then
		z = 1
	end
	
	for y = 0, mmGlobals.mazeCurSize.y - 1 do
		
		while scanStage <= 2 do
			
			for x = -1, mmGlobals.mazeCurSize.x - 2 do
				
				if !mazeData then
					mazeData = {}
				end
				
				if !mazeData[z] then
					mazeData[z] = {}
				end
				
				if !mazeData[z][x + 1]  then
					mazeData[z][x + 1] = {}
				end
				
				if !mazeData[z][x + 1][y]  then
					mazeData[z][x + 1][y] = newMazeCell()
				end
								
				if scanStage == -1 then
					
					if SERVER then
						if x == -1 then 
							outStr = outStr .. "   "
							outStr = outStr .. makeLen(tostring(x + 1), 2, " ", true) .. " "
						else
							outStr = outStr .. makeLen(tostring(x + 1), 2, " ", true) .. " "
						end
					else
						outStr = outStr .. "   "
					end
					
					
				
				elseif scanStage == 0 then
				
					if x == -1 then
						outStr = outStr .. "   "
					end
					x = x + 1
					
					if mazeData[z][x][y].n then
						if mazeData[z][x][y].visited || SERVER then
							outStr = outStr .. "/ \\"
						else
							outStr = outStr .. "   "
						end
					else
						if mazeData[z][x][y].visited || SERVER then
							outStr = outStr .. "/-\\"
						else
							outStr = outStr .. "   "
						end
					end
					
				elseif scanStage == 1 then
					
					if SERVER then 
						if x == -1 then
							outStr = outStr .. makeLen(tostring(y), 2, " ", true) .. " "
						else
							outStr = outStr .. ""
						end
					else
						if x == -1 then
							outStr = outStr .. "   "
						end
					end
					x = x + 1
					if mazeData[z][x][y].w then
						if mazeData[z][x][y].visited || SERVER then
							outStr = outStr .. " "
						else
							outStr = outStr .. " "
						end
					else
						if mazeData[z][x][y].visited || SERVER then
							outStr = outStr .. "|"
						else
							outStr = outStr .. " "
						end
					end
					
					if plyPos == Vector(x,y,z) then
							outStr = outStr .. "P"
					else
						if mazeData[z][x][y].u || mazeData[z][x][y].d then
							if mazeData[z][x][y].visited || SERVER then
								outStr = outStr .. "@"
							else
								outStr = outStr .. " "
							end
						else
						
							if mazeData[z][x][y].visited || SERVER then
								outStr = outStr .. " "
							else
								outStr = outStr .. " "
							end
						end
					end
					
					if mazeData[z][x][y].e then
						if mazeData[z][x][y].visited || SERVER then
							outStr = outStr .. " "
						else
							outStr = outStr .. " "
						end
					else
						if mazeData[z][x][y].visited || SERVER then
							outStr = outStr .. "|"
						else
							outStr = outStr .. " "
						end
					end
					
				elseif scanStage == 2 then
				
					if x == -1 then
						outStr = outStr .. "   "
					end
					
					x = x + 1
				
					if mazeData[z][x][y].s then
						if mazeData[z][x][y].visited || SERVER then
							outStr = outStr .. "\\ /"
						else
							outStr = outStr .. "   "
						end
					else
						if mazeData[z][x][y].visited || SERVER then
							outStr = outStr .. "\\-/"
						else
							outStr = outStr .. "   "
						end
					end
					
				end
				
			end
		
			outStr = outStr .. "\n"
			
			scanStage = scanStage + 1
			
		end
		
		scanStage = 0
		
	end

	return outStr
	
end