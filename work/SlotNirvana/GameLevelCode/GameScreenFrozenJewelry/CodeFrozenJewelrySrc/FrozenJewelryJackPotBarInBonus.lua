---
--xcyy
--2018年5月23日
--FrozenJewelryJackPotBarInBonus.lua

local FrozenJewelryJackPotBarInBonus = class("FrozenJewelryJackPotBarInBonus",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins_grand"
local MajorName = "m_lb_coins_major"
local MinorName = "m_lb_coins_minor"
local MiniName = "m_lb_coins_mini" 

function FrozenJewelryJackPotBarInBonus:initUI()

    self:createCsbNode("FrozenJewelry_Pick_Jackpot.csb")

    -- self:runCsbAction("idleframe",true)
    self.m_process = {}
    self.m_process["mini"] = 0
    self.m_process["minor"] = 0
    self.m_process["major"] = 0
    self.m_process["grand"] = 0

    self.m_collectItemMini = {}
    self.m_collectItemMinor = {}
    self.m_collectItemMajor = {}
    self.m_collectItemGrand = {}
    self.m_tips = {}
    for index = 1,12 do
        local item = util_createAnimation("FrozenJewelry_Pick_Jackpot_Jewelry.csb")
        if index <= 3 then
            local node = self:findChild("node_grand_"..(index - 1))
            node:addChild(item)
            self.m_collectItemGrand[#self.m_collectItemGrand + 1] = item
            if index == 3 then
                local tip = util_createAnimation("FrozenJewelry_Jackpot_Jewelry_tishi.csb")
                node:addChild(tip)
                self.m_tips["grand"] = tip
            end
        elseif index > 3 and index <= 6 then
            local node = self:findChild("node_major_"..(index - 4))
            node:addChild(item)
            self.m_collectItemMajor[#self.m_collectItemMajor + 1] = item
            if index == 6 then
                local tip = util_createAnimation("FrozenJewelry_Jackpot_Jewelry_tishi.csb")
                node:addChild(tip)
                self.m_tips["major"] = tip
            end
        elseif index > 6 and index <= 9 then
            local node = self:findChild("node_minor_"..(index - 7))
            node:addChild(item)
            self.m_collectItemMinor[#self.m_collectItemMinor + 1] = item
            if index == 9 then
                local tip = util_createAnimation("FrozenJewelry_Jackpot_Jewelry_tishi.csb")
                node:addChild(tip)
                self.m_tips["minor"] = tip
            end
        else
            local node = self:findChild("node_mini_"..(index - 10))
            node:addChild(item)
            self.m_collectItemMini[#self.m_collectItemMini + 1] = item
            if index == 12 then
                local tip = util_createAnimation("FrozenJewelry_Jackpot_Jewelry_tishi.csb")
                node:addChild(tip)
                self.m_tips["mini"] = tip
            end
        end

        item:findChild("jewelry_grand"):setVisible(index <= 3)
        item:findChild("jewelry_major"):setVisible(index > 3 and index <= 6)
        item:findChild("jewelry_minor"):setVisible(index > 6 and index <= 9)
        item:findChild("jewelry_mini"):setVisible(index > 9)
    end

    local nodes_name = {"Node_Grand_zj","Node_Major_zj","Node_Mainor_zj","Node_Mini_zj"}
    local jackpotName = {"grand","major","minor","mini"}
    self.m_lights = {}
    for index = 1,4 do
        local light = util_createAnimation("FrozenJewelry_Pick_Jackpot_zj.csb")
        self:findChild(nodes_name[index]):addChild(light)
        self.m_lights[jackpotName[index]] = light
        light:runCsbAction("actionframe",true)
        light:setVisible(false)
    end
end

function FrozenJewelryJackPotBarInBonus:onEnter()

    FrozenJewelryJackPotBarInBonus.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function FrozenJewelryJackPotBarInBonus:onExit()
    FrozenJewelryJackPotBarInBonus.super.onExit(self)
end

function FrozenJewelryJackPotBarInBonus:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function FrozenJewelryJackPotBarInBonus:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)

    self:updateSize()
end

function FrozenJewelryJackPotBarInBonus:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=1,sy=1}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=1,sy=1}
    self:updateLabelSize(info1,190)
    self:updateLabelSize(info2,190)
    self:updateLabelSize(info3,190)
    self:updateLabelSize(info4,190)
end

function FrozenJewelryJackPotBarInBonus:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

--[[
    刷新进度
]]
function FrozenJewelryJackPotBarInBonus:refreshCollect(jackpotType)
    self.m_process[jackpotType] = self.m_process[jackpotType] + 1
    local curIndex = self.m_process[jackpotType]
    local item
    if jackpotType == "mini" then
        item = self.m_collectItemMini[curIndex]
    elseif jackpotType == "minor" then
        item = self.m_collectItemMinor[curIndex]
    elseif jackpotType == "major" then
        item = self.m_collectItemMajor[curIndex]
    else
        item = self.m_collectItemGrand[curIndex]
    end

    local tip = self.m_tips[jackpotType]
    if curIndex == 2 then
        tip:setVisible(true)
        tip:runCsbAction("actionframe",true)
    elseif curIndex >= 3 then
        tip:setVisible(false)
        gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_jackpot_full.mp3")
        self.m_lights[jackpotType]:setVisible(true)
        self.m_lights[jackpotType]:findChild("Particle_1"):resetSystem()
        
    end

    item:setVisible(true)
    item:runCsbAction("actionframe")
end

--[[
    获取当前进度节点
]]
function FrozenJewelryJackPotBarInBonus:getCurProcessNode(jackpotType)
    local count = self.m_process[jackpotType]
    if count >= 2 then
        count = 2
    end
    if jackpotType == "mini" then
        return self.m_collectItemMini[count + 1]
    elseif jackpotType == "minor" then
        return self.m_collectItemMinor[count + 1]
    elseif jackpotType == "major" then
        return self.m_collectItemMajor[count + 1]
    else
        return self.m_collectItemGrand[count + 1]
    end
end

--[[
    重置界面
]]
function FrozenJewelryJackPotBarInBonus:resetView()
    for key,v in pairs(self.m_process) do
        self.m_process[key] = 0
        for index = 1,3 do
            self.m_collectItemMini[index]:setVisible(false)
            self.m_collectItemMinor[index]:setVisible(false)
            self.m_collectItemMajor[index]:setVisible(false)
            self.m_collectItemGrand[index]:setVisible(false)
        end
    end
    for k,tip in pairs(self.m_tips) do
        tip:setVisible(false)
    end

    for k,light in pairs(self.m_lights) do
        light:setVisible(false)
    end
end

return FrozenJewelryJackPotBarInBonus