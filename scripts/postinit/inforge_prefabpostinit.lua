local STRINGS = _G.STRINGS

--MELEE--
AddPrefabPostInit("blacksmithsedge", function(inst)
    inst._HP = _G.net_int(inst.GUID, "_HP")

    inst._HP:set_local(0)

    inst.displaynamefn = function()
        local name = (inst.nameoverride ~= nil and STRINGS.NAMES[string.upper(inst.nameoverride)]) or inst.name
        local randomhp = inst._HP:value()

        return name .. (randomhp > 0 and ("\n+" .. tostring(randomhp) .. " Max Health" .. "\nParry Heal") or "")
    end
end)

AddPrefabPostInit("forginghammer", function(inst)
    inst._HP = _G.net_int(inst.GUID, "_HP")
    inst._electricattack = _G.net_int(inst.GUID, "_electricattack")

    inst._HP:set_local(0)
    inst._electricattack:set_local(0)

    inst.displaynamefn = function()
        local name = (inst.nameoverride ~= nil and STRINGS.NAMES[string.upper(inst.nameoverride)]) or inst.name
        local randomhp = inst._HP:value()
        local electricattack = inst._electricattack:value()

        if(randomhp > 0 and electricattack ~= 1) then
            return name .. ("\n+" .. tostring(randomhp) .. " Max Health" or "")
        elseif(randomhp > 0 and electricattack == 1) then
            return name .. ("\n+" .. tostring(randomhp) .. " Max Health" .. "\nElectrical Attack Every 15 hit" or "")
        end
    end
end)

AddPrefabPostInit("teleport_staff", function(inst)
    inst._damage = _G.net_int(inst.GUID, "_damage")
    inst._healrate = _G.net_int(inst.GUID, "_healrate")

    inst._damage:set_local(0)
    inst._healrate:set_local(0)

    inst.displaynamefn = function()
        local name = (inst.nameoverride ~= nil and STRINGS.NAMES[string.upper(inst.nameoverride)]) or inst.name
        local randomdamage = inst._damage:value()
        local healrate = inst._healrate:value()

        if(randomdamage > 0 and healrate ~= 1) then
            return name .. (("\n+" .. tostring(randomdamage) .. " Damage") or "")
        elseif(randomdamage > 0 and healrate == 1) then 
            return name .. (("\n+" .. tostring(randomdamage) .. " Damage" .. "\n+1 HP/s") or "")
        end
    end
end)

AddPrefabPostInit("riledlucy", function(inst)
    inst._speed = _G.net_int(inst.GUID, "_speed")
    inst._upspeed = _G.net_int(inst.GUID, "_upspeed")

    inst._speed:set_local(0)
    inst._upspeed:set_local(0)

    inst.displaynamefn = function()
        local name = (inst.nameoverride ~= nil and STRINGS.NAMES[string.upper(inst.nameoverride)]) or inst.name
        local randomdamage = inst._speed:value() * 10
        local upspeed = inst._upspeed:value() * 10

        if(randomdamage > 0 and upspeed ~= 50) then
            return name .. (("\n+" .. tostring(randomdamage) .. "% Move Speed") or "")
        elseif (randomdamage > 0 and upspeed == 50) then
            return name .. (("\n+" .. tostring(randomdamage) .. "% Move Speed" .. "\nFaster Speed When Throw Lucy") or "")
        end
    end
end)

AddPrefabPostInit("pithpike", function(inst)
    inst._damage = _G.net_int(inst.GUID, "_damage")
    inst._defensebuff = _G.net_int(inst.GUID, "_defensebuff")

    inst._damage:set_local(0)
    inst._defensebuff:set_local(0)

    inst.displaynamefn = function()
        local name = (inst.nameoverride ~= nil and STRINGS.NAMES[string.upper(inst.nameoverride)]) or inst.name
        local randomdamage = inst._damage:value()
        local defensebuff = inst._defensebuff:value()

        if(randomdamage > 0 and defensebuff ~= 1) then
            return name .. (("\n+" .. tostring(randomdamage) .. " Damage") or "")
        elseif(randomdamage > 0 and defensebuff == 1) then
            return name .. (("\n+" .. tostring(randomdamage) .. " Damage" .. "\nSkill give Knockback Resistanse") or "")
        end
    end
end)


--DART--

AddPrefabPostInit("forgedarts", function(inst)
    inst._damage = _G.net_int(inst.GUID, "_damage")
    inst._infirange = _G.net_int(inst.GUID, "_infirange")


    inst._damage:set_local(0)
    inst._infirange:set_local(0)


    inst.displaynamefn = function()
        local name = (inst.nameoverride ~= nil and STRINGS.NAMES[string.upper(inst.nameoverride)]) or inst.name
        local randomdamage = inst._damage:value()
        local infirange = inst._infirange:value()

        if(randomdamage > 0 and infirange ~=  1) then
            return name .. (("\n+" .. tostring(randomdamage) .. " Damage") or "")
        elseif(randomdamage > 0 and infirange ==  1) then
            return name .. (("\n+" .. tostring(randomdamage) .. " Damage" .. "\nPoison Attack Every 20 Hit") or "")
        end
    end
end)

AddPrefabPostInit("moltendarts", function(inst)
    inst._damage = _G.net_int(inst.GUID, "_damage")
    inst._infirange = _G.net_int(inst.GUID, "_infirange")


    inst._damage:set_local(0)
    inst._infirange:set_local(0)


    inst.displaynamefn = function()
        local name = (inst.nameoverride ~= nil and STRINGS.NAMES[string.upper(inst.nameoverride)]) or inst.name
        local randomdamage = inst._damage:value()
        local infirange = inst._infirange:value()

        if(randomdamage > 0 and infirange ~=  1) then
            return name .. (("\n+" .. tostring(randomdamage) .. " Damage") or "")
        elseif(randomdamage > 0 and infirange ==  1) then
            return name .. (("\n+" .. tostring(randomdamage) .. " Damage" .. "\nPoison Bomb Attack Every 20 Hit") or "")
        end
    end
end)

AddPrefabPostInit("firebomb", function(inst)
    inst._damage = _G.net_int(inst.GUID, "_damage")
    inst._anotherbomb = _G.net_int(inst.GUID, "_anotherbomb")

    inst._damage:set_local(0)
    inst._anotherbomb:set_local(0)

    inst.displaynamefn = function()
        local name = (inst.nameoverride ~= nil and STRINGS.NAMES[string.upper(inst.nameoverride)]) or inst.name
        local randomdamage = inst._damage:value()
        local anotherbomb = inst._anotherbomb:value()

        if(randomdamage > 0 and anotherbomb ~= 1) then
            return name .. (("\n+" .. tostring(randomdamage) .. " Damage") or "")
        elseif(randomdamage > 0 and anotherbomb == 1) then
            return name .. (("\n+" .. tostring(randomdamage) .. " Damage" .. "\nThrow Another Bomb To You") or "")
        end
    end
end)

AddPrefabPostInit("lavaarena_seeddarts", function(inst)
    inst._damage = _G.net_int(inst.GUID, "_damage")

    inst._damage:set_local(0)

    inst.displaynamefn = function()
        local name = (inst.nameoverride ~= nil and STRINGS.NAMES[string.upper(inst.nameoverride)]) or inst.name
        local randomdamage = inst._damage:value()

        if(randomdamage > 0) then
            return name .. (("\n+" .. tostring(randomdamage) .. " Damage") or "")
        end
    end
end)



--STAFF--

AddPrefabPostInit("livingstaff", function(inst)
    inst._healrate = _G.net_int(inst.GUID, "_healrate")
    inst._target_heal = _G.net_int(inst.GUID, "_target_heal")
    inst._checkheal = _G.net_int(inst.GUID, "_checkheal")

    inst._healrate:set_local(0)
    inst._target_heal:set_local(0)
    inst._checkheal:set_local(0)

    inst.displaynamefn = function()
        local name = (inst.nameoverride ~= nil and STRINGS.NAMES[string.upper(inst.nameoverride)]) or inst.name
        local randomdamage = inst._healrate:value()
        local range = inst._target_heal:value()
        local checkheal = inst._checkheal:value()

        if(randomdamage > 0 and range ~= 1) then
            return name .. (("\n+" .. tostring(randomdamage) .. " Heal Rate") or "")
        elseif(randomdamage > 0 and range == 1 and checkheal ~= 1) then
            return name .. (("\n+" .. tostring(randomdamage) .. " Heal Rate" .. "\nTargeting Heal") or "")
        elseif(randomdamage > 0 and range == 1 and checkheal == 1) then
            return name .. (("\n+" .. tostring(randomdamage) .. " Heal Rate" .. "\nTargeting Heal (ctrl + attack to player)") or "")
        end
    end
end)

AddPrefabPostInit("infernalstaff", function(inst)
    inst._damage = _G.net_int(inst.GUID, "_damage")
    inst._moremeteor = _G.net_int(inst.GUID, "_moremeteor")

    inst._damage:set_local(0)
    inst._moremeteor:set_local(0)

    inst.displaynamefn = function()
        local name = (inst.nameoverride ~= nil and STRINGS.NAMES[string.upper(inst.nameoverride)]) or inst.name
        local randomdamage = inst._damage:value()
        local moremeteor = inst._moremeteor:value()

        if(randomdamage > 0 and moremeteor ~= 1) then
            return name .. (("\n+" .. tostring(randomdamage) .. " Damage") or "")
        elseif(randomdamage > 0 and moremeteor == 1) then
            return name .. (("\n+" .. tostring(randomdamage) .. " Damage" .. "\nSummon 2 Meteor Around Caster") or "")
        end
    end
end)


--BOOK--

AddPrefabPostInit("bacontome", function(inst)
    inst._speed = _G.net_int(inst.GUID, "_speed")
    inst._golemappear = _G.net_int(inst.GUID, "_golemappear")

    inst._speed:set_local(0)
    inst._golemappear:set_local(0)

    inst.displaynamefn = function()
        local name = (inst.nameoverride ~= nil and STRINGS.NAMES[string.upper(inst.nameoverride)]) or inst.name
        local randomdamage = inst._speed:value() * 10
        local golemappear = inst._golemappear:value()

        if(randomdamage > 0 and golemappear ~= 1) then
            return name .. (("\n+" .. tostring(randomdamage) .. "% Move Speed") or "")
        elseif(randomdamage > 0 and golemappear == 1) then
            return name .. (("\n+" .. tostring(randomdamage) .. "% Move Speed" .. "\nSpawn Guardian") or "")
        end
    end
end)

AddPrefabPostInit("petrifyingtome", function(inst)
    inst._speed = _G.net_int(inst.GUID, "_speed")
    inst._petagain = _G.net_int(inst.GUID, "_petagain")

    inst._speed:set_local(0)
    inst._petagain:set_local(0)

    inst.displaynamefn = function()
        local name = (inst.nameoverride ~= nil and STRINGS.NAMES[string.upper(inst.nameoverride)]) or inst.name
        local randomdamage = inst._speed:value() * 10
        local petagain = inst._petagain:value()

        if(randomdamage > 0 and petagain ~= 1) then
            return name .. (("\n+" .. tostring(randomdamage) .. "% Move Speed") or "")
        elseif (randomdamage > 0 and petagain == 1) then
            return name .. (("\n+" .. tostring(randomdamage) .. "% Move Speed" .. "\nPetrify Again After 3 second") or "")
        end
    end
end)


local function DontRemoveCorpse(inst)
    if inst.components.health then
        inst.components.health.nofadeout = true
        inst:DoTaskInTime(1,function()
            inst.components.health:Kill()
            inst:AddTag("NOCLICK")
        end)
    end
end 

local function RemoveLoot(inst)
    _G.SetSharedLootTable(inst.prefab,{})

    if inst.components.lootdropper then
        inst.components.lootdropper.chanceloottable = nil
        inst.components.lootdropper.ifnotchanceloot = nil
    end
end

AddPrefabPostInit("slurtle", function(inst)
    if _G.INFORGE_COMMON_FNS.IsDungeon() then
        RemoveLoot(inst)
        DontRemoveCorpse(inst)
    end
end)