local mat = Material("color")
local white = Color(0, 119, 255, 30)
local point1, point2, height

if SERVER then
	util.AddNetworkString("nz_AntiCheatExclusionCreation")
	
	net.Receive("nz_AntiCheatExclusionCreation", function(len, ply)
		if !ply:IsInCreative() then return end
		local vec1 = net.ReadVector()
		local vec2 = net.ReadVector()
		
		if net.ReadBool() then
			nzMapping:CreateAntiCheatExclusion(vec1, vec2, ply)
		end
	end)
end

nzTools:CreateTool("anticheatexclude", {
	displayname = "Anti-Cheat Exclude",
	desc = "LMB: Set Corners, RMB: Remove Exclusion at spot, R: Reset corners. (Players can cheat in these)",
	condition = function(wep, ply)
		return nzTools.Advanced
	end,
	PrimaryAttack = function(wep, ply, tr, data)
		
	end,
	SecondaryAttack = function(wep, ply, tr, data)
		local walls = ents.FindInSphere(tr.HitPos, 5)
		for k,v in pairs(walls) do
			if v:GetClass() == "anticheat_exclude" then v:Remove() end
		end
	end,
	Reload = function(wep, ply, tr, data)

	end,
	OnEquip = function(wep, ply, data)

	end,
	OnHolster = function(wep, ply, data)

	end
}, {
	displayname = "Anti-Cheat Exclude",
	desc = "Place where you are OK with players cheating at.",
	icon = "icon16/shape_handles.png",
	weight = 16,
	condition = function(wep, ply)
		return nzTools.Advanced
	end,
	interface = function(frame, data)
	end,
	PrimaryAttack = function(wep, ply, tr, data)
		local pos = tr.HitPos
		if !pos then return end
		
		if !point1 then
			point1 = pos
		elseif !point2 then
			point2 = Vector(pos.x - point1.x, pos.y - point1.y, point1.z)
		elseif !height then
			height = pos.z - point1.z
			net.Start("nz_AntiCheatExclusionCreation")
				net.WriteVector(point1)
				net.WriteVector(Vector(point2.x, point2.y, height))
				net.WriteBool(true)
			net.SendToServer()
			point1 = nil
			point2 = nil
			height = nil
		end
	end,
	Reload = function()
		point1 = nil
		point2 = nil
		height = nil
	end,
	interface = function(frame, data)
		local pnl = vgui.Create("DPanel", frame)
		pnl:Dock(FILL)
		
		local chk = vgui.Create("DCheckBoxLabel", pnl)
		chk:SetPos( 200, 20 )
		chk:SetText( "Preview Config" )
		chk:SetTextColor( Color(50,50,50) )
		chk:SetConVar( "nz_creative_preview" )
		chk:SetValue( GetConVar("nz_creative_preview"):GetBool() )
		chk:SizeToContents()
		
		local textw = vgui.Create("DLabel", pnl)
		textw:SetText("Warning: Rotating Invis Walls does not work")
		textw:SetFont("Trebuchet18")
		textw:SetTextColor( Color(150, 50, 50) )
		textw:SizeToContents()
		textw:SetPos(120, 50)

		local textw2 = vgui.Create("DLabel", pnl)
		textw2:SetText("correctly at the moment and will not save!")
		textw2:SetFont("Trebuchet18")
		textw2:SetTextColor( Color(150, 50, 50) )
		textw2:SizeToContents()
		textw2:SetPos(120, 65)
		
		return pnl
	end,
	drawhud = function()
		cam.Start3D()
			render.SetMaterial(mat)
			local x = point1 or nil
			local y
			if x then
				if point2 then
					if height then
						y = Vector(point2.x, point2.y, height)
					else
						y = Vector(point2.x, point2.y, LocalPlayer():GetEyeTrace().HitPos.z - point1.z)
					end
				else
					y = Vector(LocalPlayer():GetEyeTrace().HitPos.x - point1.x, LocalPlayer():GetEyeTrace().HitPos.y - point1.y, 0)
				end
			end
			if x and y then
				render.DrawBox(x, Angle(0,0,0), Vector(0,0,0), y, white, true)
			end
		cam.End3D()
	end,
})