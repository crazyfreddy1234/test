local function dunguen_center()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("CLASSIFIED")

    inst:Hide()

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    local function onload(inst, data)
		if data == nil then
			Debug:Print("dunguen_spawner has no properties in the map file. Defaulting centerid to 999.", "error")
			inst.centerid = 999
		else
			inst.centerid = data.centerid or 999
		end
	end
	inst.OnLoad = onload

    inst:DoTaskInTime(0, function(inst)
        if TheWorld.DungeonCenterPos == nil then TheWorld.DungeonCenterPos = {} end

        TheWorld.DungeonCenterPos[inst.centerid] = inst:GetPosition()
    end)

    return inst
end

return Prefab("dunguen_center", dunguen_center)
