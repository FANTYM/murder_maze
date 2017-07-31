GM.Name 	= "Murder Maze"
GM.Author 	= "Fantym420 (Malcolm Greene)"
GM.Email 	= "Fantym420@GMail.Com"
GM.Website 	= ""

DEFINE_BASECLASS( "gamemode_base")

countDownSounds = {}
countDownSounds[0] = "npc/overwatch/radiovoice/zero.wav"
countDownSounds[1] = "npc/overwatch/radiovoice/one.wav"
countDownSounds[2] = "npc/overwatch/radiovoice/two.wav"
countDownSounds[3] = "npc/overwatch/radiovoice/three.wav"
countDownSounds[4] = "npc/overwatch/radiovoice/four.wav"
countDownSounds[5] = "npc/overwatch/radiovoice/five.wav"
countDownSounds[6] = "npc/overwatch/radiovoice/six.wav"
countDownSounds[7] = "npc/overwatch/radiovoice/seven.wav"
countDownSounds[8] = "npc/overwatch/radiovoice/eight.wav"
countDownSounds[9] = "npc/overwatch/radiovoice/nine.wav"

-- npc/overwatch/radiovoice/citizen.wav
-- npc/overwatch/radiovoice/quick.wav
-- npc/overwatch/radiovoice/inprogress.wav
-- npc/overwatch/radiovoice/interlock.wav
-- npc/overwatch/radiovoice/apply.wav
-- npc/overwatch/radiovoice/victor.wav
-- npc/overwatch/radiovoice/zone.wav


items = include("items.lua")

females  =  { "models/player/group01/female_01.mdl", 
			  "models/player/group01/female_02.mdl",
			  "models/player/group01/female_03.mdl",
			  "models/player/group01/female_04.mdl",
			  "models/player/group01/female_05.mdl",
			  "models/player/group01/female_06.mdl" }
	
males   =  {  "models/player/group01/male_01.mdl", 
			  "models/player/group01/male_02.mdl",
			  "models/player/group01/male_03.mdl",
			  "models/player/group01/male_04.mdl",
			  "models/player/group01/male_05.mdl",
			  "models/player/group01/male_06.mdl",
			  "models/player/group01/male_07.mdl",
			  "models/player/group01/male_08.mdl",
			  "models/player/group01/male_09.mdl" }
			  
blockSizes = Vector(528, -528, 216)

maxX = 6
minY = 3

maxY = 6
minX = 3

curX = 0
curY = 0

dirPairs = {}
	dirPairs["d"] = "u"
	dirPairs["u"] = "d"
	dirPairs["e"] = "w"
	dirPairs["w"] = "e"
	dirPairs["n"] = "s"
	dirPairs["s"] = "n"
	
GM.curMaze = {}
	
function GM:PlayerNoClip( pl, on )
	
	return !pl:IsBot() || pl:IsAdmin()
	
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

function GetPlayerMapPos(ply)
	
	
	plyPos = ply:GetPos() + Vector(0,0,64)
	
	local result = Vector( math.floor((plyPos.x / blockSizes.x) + 15), 
						   math.floor((plyPos.y / blockSizes.y) + 15), 
						   math.abs(math.floor( plyPos.z / blockSizes.z)) )
		
	return result
						   
end

function GetBlockWorldPos( pos )
			
	return Vector( (pos.x - 15) * blockSizes.x,
				   (pos.y - 15) * blockSizes.y,
				   (pos.z) * blockSizes.z )
		   
end

function IsInMaze( pos )
	
	if ( pos.x >= 0 && pos.x < curX ) &&
	   ( pos.y >= 0 && pos.y < curY ) &&
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
	
	if !self.roundEnt then return end
	
	if ply.inMaze && self.roundEnt:GetCurrentTitle() == "pre" ||
	   ply.snared then
		
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
	
	mazeData = mazeData or self.curMaze
	
	local plyPos = Vector(0,0,0)
	if ply && IsValid(ply) && ply:IsPlayer() then
		plyPos = GetPlayerMapPos(ply)
	end
	
	local scanStage = -1
	
	local outStr = ""
	
	if level == "b" then
		z = 1
	end
	
	for y = 0, curY - 1 do
		
		while scanStage <= 2 do
			
			for x = -1, curX - 2 do
				
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