---
--xcyy
--2018年5月23日
--CoinConiferSuperColofulJackPotBar.lua
local PublicConfig = require "CoinConiferPublicConfig"
local CoinConiferSuperColofulJackPotBar = class("CoinConiferSuperColofulJackPotBar",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 

local JACKPOT_INDEX = {
    grand = 1,
    major = 2,
    minor = 3,
    mini = 4
}

function CoinConiferSuperColofulJackPotBar:initUI()
    self:createCsbNode("CoinConifer_super_jackpotbar.csb")
    self:runIdleAni()

    self.m_collectItems = {}    --所有的收集点
    self.m_collectProcess = {}  --所有的收集进度
    for jackpotType,jackpotIndex in pairs(JACKPOT_INDEX) do
        self.m_collectItems[jackpotType] = {}
        self.m_collectProcess[jackpotType] = 0
        if jackpotType == "mini" then
            for index = 1,4 do
                local item = util_createAnimation("CoinConifer_super_jackpotbar_collect.csb")
                self.m_collectItems[jackpotType][index] = item
                item:runCsbAction("idle")
                item.m_runActName = "idle"
                local parentNode = self:findChild(jackpotType.."_collect_"..index)
                if parentNode then
                    parentNode:addChild(item)
                end
                self:changeShowItem(item,jackpotType)
            end
        else
            for index = 1,5 do
                local item = util_createAnimation("CoinConifer_super_jackpotbar_collect.csb")
                self.m_collectItems[jackpotType][index] = item
                item:runCsbAction("idle")
                item.m_runActName = "idle"
                local parentNode = self:findChild(jackpotType.."_collect_"..index)
                if parentNode then
                    parentNode:addChild(item)
                end
                self:changeShowItem(item,jackpotType)
            end
        end
        
    end

    self.m_jackpotLightList = {}
    for jackpotType,jackpotIndex in pairs(JACKPOT_INDEX) do
        local item = util_createAnimation("CoinConifer_Jackpot.csb")
        local parentNode = self:findChild("jackpot"..jackpotIndex)
        if parentNode then
            parentNode:addChild(item)
            self.m_jackpotLightList[jackpotType] = item
            item:runCsbAction("idle",true)
        end
    end

    self.dianjiList = {}
    self:adddianjiEffect()
end

function CoinConiferSuperColofulJackPotBar:onEnter()

    CoinConiferSuperColofulJackPotBar.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function CoinConiferSuperColofulJackPotBar:onExit()
    CoinConiferSuperColofulJackPotBar.super.onExit(self)
end

function CoinConiferSuperColofulJackPotBar:initMachine(machine)
    self.m_machine = machine
end

function CoinConiferSuperColofulJackPotBar:adddianjiEffect()
    self.dianjiList = {}
    for jackpotType,jackpotIndex in pairs(JACKPOT_INDEX) do
        local item = util_createAnimation("CoinConifer_super_jackpotbar_collect_daiji.csb")
        self:findChild("daiji"..jackpotIndex):addChild(item)
        self.dianjiList[jackpotType] = item
        item:setVisible(false)
    end
end

--重置某一个jackpot
function CoinConiferSuperColofulJackPotBar:resetViewForJackpot(jackpotType)
    local itemList = self.m_collectItems[jackpotType]
    self.m_collectProcess[jackpotType] = 0
    for index,item in ipairs(itemList) do
        if not tolua.isnull(item) then
            item:runCsbAction("xiaoshi",false,function ()
                item:runCsbAction("idle1")
                item.m_runActName = "idle1"
            end)
        end
    end
    local lightItem = self.m_jackpotLightList[jackpotType]
    if not tolua.isnull(lightItem) then
        lightItem:runCsbAction("idle",true)
    end
end

--[[
    重置界面显示
]]
function CoinConiferSuperColofulJackPotBar:resetView(isDisconnection)
    
    local freespinExtra = self.m_machine.m_runSpinResultData.p_fsExtraData or {}
    local jackpotnum = clone(freespinExtra.jackpotnum or {})
    jackpotnum = self:changejiManInfo()
    if table_length(jackpotnum) > 0 then
        for jackpotType,itemList in pairs(self.m_collectItems) do
            self.m_collectProcess[jackpotType] = jackpotnum[jackpotType]
            for index,item in ipairs(itemList) do
                if not tolua.isnull(item) then
                    if index <= jackpotnum[jackpotType] then
                        item:runCsbAction("idle2")
                        item.m_runActName = "idle2"
                    else
                        item:runCsbAction("idle1")
                        item.m_runActName = "idle1"
                    end
                end
                
            end
            local lightItem = self.m_jackpotLightList[jackpotType]
            if not tolua.isnull(lightItem) then
                if jackpotnum[jackpotType] == #itemList - 1 then
                    lightItem:runCsbAction("actionframe2",true)
                    local dianjiItem = self.dianjiList[jackpotType]
                    if not tolua.isnull(dianjiItem) then
                        dianjiItem:setVisible(true)
                        dianjiItem:runCsbAction("daiji",true)
                    end
                else
                    lightItem:runCsbAction("idle",true)
                    local dianjiItem = self.dianjiList[jackpotType]
                    if not tolua.isnull(dianjiItem) then
                        dianjiItem:setVisible(false)
                    end
                end
                
            end
        end
    else
        for jackpotType,itemList in pairs(self.m_collectItems) do
            self.m_collectProcess[jackpotType] = 0
            for index,item in ipairs(itemList) do
                if not tolua.isnull(item) then
                    item:runCsbAction("idle1")
                    item.m_runActName = "idle1"
                end
                
            end
            local lightItem = self.m_jackpotLightList[jackpotType]
            if not tolua.isnull(lightItem) then
                lightItem:runCsbAction("idle",true)
            end
            local dianjiItem = self.dianjiList[jackpotType]
            if not tolua.isnull(dianjiItem) then
                dianjiItem:setVisible(false)
            end
        end
    end
    
    self:runIdleAni()
end

function CoinConiferSuperColofulJackPotBar:changejiManInfo()
    local freespinExtra = self.m_machine.m_runSpinResultData.p_fsExtraData or {}
    local jackpotnum = clone(freespinExtra.jackpotnum or {})
    if table_length(jackpotnum) > 0 then
        if jackpotnum["grand"] == 5 then
            jackpotnum["grand"] = 0
        end
        if jackpotnum["major"] == 5 then
            jackpotnum["major"] = 0
        end
        if jackpotnum["minor"] == 5 then
            jackpotnum["minor"] = 0
        end
        if jackpotnum["mini"] == 4 then  
            jackpotnum["mini"] = 0  
        end
    end
    return jackpotnum
end

--[[
    收集反馈动效
]]
function CoinConiferSuperColofulJackPotBar:collectFeedBackAni(jackpotType,pointItem)
    if pointItem then
        -- pointItem:setVisible(true)
        pointItem.m_runActName = "fankui"
        pointItem:runCsbAction("fankui",false,function ()
            pointItem.m_runActName = "idle2"
            pointItem:runCsbAction("idle2",true)
        end)
    end
    local process = self.m_collectProcess[jackpotType]
    local nextNum = 5
    if jackpotType == "mini" then
        nextNum = 4
    end
    if process == nextNum then
        local dianjiItem = self.dianjiList[jackpotType]
        if not tolua.isnull(dianjiItem) then
            dianjiItem:setVisible(false)
        end
    end
    self:nextTriggerAni(jackpotType)        --待触发动效
end

--待触发动效
function CoinConiferSuperColofulJackPotBar:nextTriggerAni(jackpotType)
    local process = self.m_collectProcess[jackpotType]
    local nextNum = 4
    if jackpotType == "mini" then
        nextNum = 3
    end
    if process == nextNum then
        local item = self:getFeedBackPoint(jackpotType,process + 1)
        local lightItem = self.m_jackpotLightList[jackpotType]
        if not tolua.isnull(item) then
            -- item.m_runActName = "actionframe2"
            -- item:runCsbAction("actionframe2",true)
        end
        if not tolua.isnull(lightItem) then
            lightItem:runCsbAction("actionframe2",true)
        end
        local dianjiItem = self.dianjiList[jackpotType]
        if not tolua.isnull(dianjiItem) then
            dianjiItem:setVisible(true)
            dianjiItem:runCsbAction("daiji",true)
        end
    end
end

function CoinConiferSuperColofulJackPotBar:resetNextTriggerItemAct()
    for jackpotType,itemList in pairs(self.m_collectItems) do
        self.m_collectProcess[jackpotType] = 0
        for index,item in ipairs(itemList) do
            if not tolua.isnull(item) and item.m_runActName == "idle3" then
                item:runCsbAction("idle1")
                item.m_runActName = "idle1"
            end
        end
    end
end

--[[
    获取收集反馈点
]]
function CoinConiferSuperColofulJackPotBar:getFeedBackPoint(jackpotType,index)
    local itemList = self.m_collectItems[jackpotType]
    return itemList[index]
end

--[[
    获取收集进度
]]
function CoinConiferSuperColofulJackPotBar:getProcessByType(jackpotType)
    self.m_collectProcess[jackpotType] = self.m_collectProcess[jackpotType] + 1
    --检测进度是否集满
    local toatlNum = 5
    if jackpotType == "mini" then
        toatlNum = 4
    end
    if self.m_collectProcess[jackpotType] >= toatlNum then
        self.m_collectProcess[jackpotType] = toatlNum
    end
    return self.m_collectProcess[jackpotType]
end

function CoinConiferSuperColofulJackPotBar:getProcessByType2(jackpotType)
    return self.m_collectProcess[jackpotType]
end

--[[
    显示中奖光效
]]
function CoinConiferSuperColofulJackPotBar:showHitLight(jackpotType)
    local jackpotIndex = JACKPOT_INDEX[jackpotType]
    local lightItem = self.m_jackpotLightList[jackpotType]
    if not tolua.isnull(lightItem) then
        lightItem:runCsbAction("actionframe",true)
    end
    
end

function CoinConiferSuperColofulJackPotBar:changeShowItem(item,jackpotType)
    item:findChild("grand"):setVisible(jackpotType == "grand")
    item:findChild("major"):setVisible(jackpotType == "major")
    item:findChild("minor"):setVisible(jackpotType == "minor")
    item:findChild("mini"):setVisible(jackpotType == "mini")
end

--[[
    idle
]]
function CoinConiferSuperColofulJackPotBar:runIdleAni()
    self:runCsbAction("idle",true)
end

-- 更新jackpot 数值信息
--
function CoinConiferSuperColofulJackPotBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName), 1, true)
    self:changeNode(self:findChild(MajorName), 2, true)
    self:changeNode(self:findChild(MinorName), 3)
    self:changeNode(self:findChild(MiniName), 4)

    self:updateSize()
end

function CoinConiferSuperColofulJackPotBar:updateSize()

    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MajorName]
    local label3 = self.m_csbOwner[MinorName]
    local label4 = self.m_csbOwner[MiniName]

    local info1 = {label = label1, sx = 0.6, sy = 0.6}
    local info2 = {label = label2, sx = 0.6, sy = 0.6}
    local info3 = {label = label3, sx = 0.62, sy = 0.62}
    local info4 = {label = label4, sx = 0.62, sy = 0.62}

    self:updateLabelSize(info1, 534)
    self:updateLabelSize(info2, 534)
    self:updateLabelSize(info3, 396)
    self:updateLabelSize(info4, 395)
end

function CoinConiferSuperColofulJackPotBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoinsLN(value,12,nil,nil,true))
end

return CoinConiferSuperColofulJackPotBar