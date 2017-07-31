
local items = {}

items.weaponsAmmo = {}
items.weaponsAmmo["weapon_pistol"] = "Pistol"
items.weaponsAmmo["weapon_357"] = "357"
items.weaponsAmmo["weapon_shotgun"] = "Buckshot"
items.weaponsAmmo["weapon_smg1"] = "SMG1"
items.weaponsAmmo["weapon_frag"] = "Grenade"
items.weaponsAmmo["weapon_slam"] = "SLAM"
items.weaponsAmmo["weapon_fists"] = " "
items.weaponsAmmo["class"] = "internal"

items.ammoWeapons = {}
items.ammoWeapons["Pistol"] = "weapon_pistol"
items.ammoWeapons["357"] = "weapon_357"
items.ammoWeapons["Buckshot"] = "weapon_shotgun"
items.ammoWeapons["SMG1"] = "weapon_smg1"
items.ammoWeapons["SMG1_Grenade"] = "weapon_smg1"
items.ammoWeapons["weapon_frag"] = "weapon_frag"
items.ammoWeapons["weapon_slam"] = "weapon_slam"
items.ammoWeapons[" "] = "weapon_fists"
items.ammoWeapons["class"] = "internal"

local function goodBuyer(itemBuyer)

	return IsValid(itemBuyer) && itemBuyer:IsPlayer()
	
end

local function hasCredits(item, itemBuyer)


		return itemBuyer.credits >= item.cost
			
			
end

local function canBuy(item, itemBuyer)
	
	if goodBuyer(itemBuyer) then
	
			if hasCredits(item, itemBuyer) then
			
			else
			
				return false, ".-=Insufficent Funds=-."
				
			end
	else
	
		return false, ".-=You're not valid=-."
		
	end
		
	return true, ".-=Purchase Approved=-."
	
end

local function canBuyWeapon(item, itemBuyer)
		
		if goodBuyer(itemBuyer) then
			if hasCredits(item, itemBuyer) then
		
				local weOwn = itemBuyer:HasWeapon(item.class)
				
				if weOwn then
				
					if item.class != "weapon_frag" && item.class != "weapon_slam" then
						return false, ".-=You already own this=-."
					else 
						if itemBuyer:GetAmmoCount(items.weaponsAmmo[item.class]) >= item.maxQuantity then 
							return false, ".-=This Ammo is full=-."
						end
					end
					
				end
			else
				return false, ".-=Insufficent Funds=-."
			end
		else
			return false, ".-=You're not valid=-."
		end
			
		return true, ".-=Purchase Approved=-."

end

local function canBuyAmmo(item, itemBuyer)

	if goodBuyer(itemBuyer) then
		if hasCredits(item, itemBuyer) then
			
			if itemBuyer:HasWeapon(items.ammoWeapons[item.class]) then
		
				if itemBuyer:GetAmmoCount(item.class) >= item.maxQuantity then 
					return false, ".-=This Ammo is full=-."
				end
			else
				return false, ".-=You don't have a weapon for this ammo=-."	
			end
			
		else
			return false, ".-=Insufficent Funds=-."
		end
	else
		return false, ".-=You're not valid=-."
	end
	
	return true, ".-=Purchase Approved=-."

end
	  
local function buyWeaponOrItem(itemClass, itemQuantity, itemOwner)
	
	if IsValid(itemOwner) && itemOwner:IsPlayer() then
		
		local newThing = itemOwner:Give(itemClass)
		
		if newThing:IsWeapon() then
			
			itemOwner:SetAmmo( 0, items.weaponsAmmo[itemClass] )
			newThing:SetClip1(0)
			newThing:SetClip2(0)
	
		end
		
	end
	
end

local function buyAmmo(itemClass, itemQuantity, itemOwner)

	if IsValid(itemOwner) && itemOwner:IsPlayer() then
		
		itemOwner:GiveAmmo(itemQuantity, itemClass, true)
	
	end
end

local function buyWeaponOrAmmo(itemClass, itemQuantity, itemOwner)
	
	if IsValid(itemOwner) && itemOwner:IsPlayer() then
		
		if itemClass == "weapon_frag" || itemClass == "weapon_slam" then
			if itemOwner:HasWeapon(itemClass) then
				itemOwner:GiveAmmo(itemQuantity, items.weaponsAmmo[itemClass], true)
			else
				local newThing = itemOwner:Give(itemClass)
				
				if itemClass == "weapon_frag" then
					itemOwner:GiveAmmo(itemQuantity - 1, items.weaponsAmmo[itemClass], true)
				elseif itemClass == "weapon_slam" then
					itemOwner:GiveAmmo(itemQuantity - 3, items.weaponsAmmo[itemClass], true)
				end
			end
		end
		
	end
	
end

local function addItem(itemTitle, itemClass, itemModel, itemCost, itemQuantity, itemMaxQuantity, buyFunction, canBuyFunction)
	
	local newItem = {}
	
	newItem.title = itemTitle
	newItem.class = itemClass
	newItem.model = itemModel
	newItem.cost = itemCost
	newItem.quantity = itemQuantity
	newItem.maxQuantity = itemMaxQuantity
	
	if SERVER then
		newItem.buyFunc = buyFunction or buyWeaponOrItem
		newItem.canBuy = canBuyFunction or canBuy
	end
	
	newItem.id = table.insert(items, newItem)
	
end
 

addItem("Pistol",			"weapon_pistol", 	"models/weapons/w_pistol.mdl", 				250, 	1, 	1, buyWeaponOrItem, canBuyWeapon)
addItem(".357 Magnum", 		"weapon_357", 		"models/weapons/w_357.mdl",  				500, 	1, 	1, buyWeaponOrItem, canBuyWeapon)
addItem("Shotgun", 			"weapon_shotgun", 	"models/weapons/w_shotgun.mdl", 			1500, 	1, 	1, buyWeaponOrItem, canBuyWeapon)
addItem("SMG", 				"weapon_smg1", 		"models/weapons/w_smg1.mdl",				2000, 	1, 	1, buyWeaponOrItem, canBuyWeapon)

addItem("Pistol Ammo", 		"Pistol", 			"models/items/ammocrate_pistol.mdl", 		25, 	18, 180,	buyAmmo, canBuyAmmo)
addItem(".357 Ammo", 		"357", 				"models/items/357ammo.mdl", 				100, 	6, 	60,		buyAmmo, canBuyAmmo)
addItem("Shotgun Ammo", 	"Buckshot", 		"models/items/ammocrate_buckshot.mdl", 		250, 	6, 	60,		buyAmmo, canBuyAmmo)
addItem("SMG Ammo", 		"SMG1", 			"models/items/ammocrate_smg1.mdl", 			500, 	45, 450,	buyAmmo, canBuyAmmo)
addItem("SMG Grenade Ammo", "SMG1_Grenade", 	"models/Items/AR2_Grenade.mdl",				1000, 	1, 	10,		buyAmmo, canBuyAmmo)

addItem("Frag Grenade", 	"weapon_frag", 		"models/items/grenadeammo.mdl", 			1000, 	6, 	60,		buyWeaponOrAmmo, canBuyWeapon)

addItem("Trip Mine",	 	"weapon_slam", 		"models/weapons/w_slam.mdl", 				2500, 	3, 	30,		buyWeaponOrAmmo, canBuyWeapon)

addItem("Increase Health", 	"item_healthkit", 	"models/Items/HealthKit.mdl", 				5000, 	10, 999,	function(itemClass, itemQuantity, itemOwner)
																													
																													if IsValid(itemOwner) && itemOwner:IsPlayer() then
																														
																														itemOwner:SetMaxHealth(math.min(itemOwner:Health() + itemQuantity, 999))
																														itemOwner:SetHealth(itemOwner:GetMaxHealth())
																														itemOwner:SetPData("mm_ply_max_health", itemOwner:GetMaxHealth())
																														
																													end
																													
																												end, 																												
																												function(item, itemBuyer)
																													
																													if IsValid(itemBuyer) && itemBuyer:IsPlayer() then
																														if itemBuyer.credits >= item.cost then
																															if item.class == "item_healthkit" then
							
																																if itemBuyer:GetMaxHealth() >= item.maxQuantity then
																																	return false, ".-=You are at maximum health=-."
																																else
																																	return true
																																end
																															
																															end
																														else 
																																return false, ".-=Insufficent Funds=-."
																														end
																													end
																													
																													return false, "Unexpected Result"
																													
																												end)
																													
return items