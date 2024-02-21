---
--xcyy
--2018年5月23日
--RobinIsHoodColofulJackPotBar.lua
local PublicConfig = require "RobinIsHoodPublicConfig"
local RobinIsHoodColofulJackPotBar = class("RobinIsHoodColofulJackPotBar",util_require("base.BaseView"))

local GrandName = "m_lb_coins_grand"
local MajorName = "m_lb_coins_major"
local MinorName = "m_lb_coins_minor"
local MiniName = "m_lb_coins_mini" 

local JACKPOT_INDEX = {
    grand = 1,
    major = 2,
    minor = 3,
    mini = 4
}

function RobinIsHoodColofulJackPotBar:initUI(params)
    self:initMachine(params.machine)
    self:createCsbNode("RobinIsHood_dfdc_jackpotbar.csb")
    self:runIdleAni()

    self.m_collectItems = {}    --所有的收集点
    self.m_collectProcess = {}  --所有的收集进度
    self.m_collectEndProcess = {}  --所有的已经收集过的收集进度
    self.m_hitLightAnis = {}    --中奖光效
    for jackpotType,jackpotIndex in pairs(JACKPOT_INDEX) do
        self.m_collectItems[jackpotType] = {}
        self.m_collectProcess[jackpotType] = 0
        self.m_collectEndProcess[jackpotType] = 0
        for index = 1,3 do
            local item = util_createAnimation("RobinIsHood_dfdc_shouji.csb")
            --设置收集点的jackpot显示
            for tempType,tempIndex in pairs(JACKPOT_INDEX) do
                if item:findChild(tempType) then
                    item:findChild(tempType):setVisible(tempType == jackpotType)
                end
            end
            self.m_collectItems[jackpotType][index] = item
            local parentNode = self:findChild("Node_"..jackpotType.."_"..index)
            if parentNode then
                parentNode:addChild(item)
            end
        end

        local hitLight = util_createAnimation("RobinIsHood_jackpot_win.csb")
        self:findChild("Node_"..jackpotType.."win"):addChild(hitLight)
        self.m_hitLightAnis[jackpotType] = hitLight
        hitLight:setVisible(false)
    end
end

function RobinIsHoodColofulJackPotBar:onEnter()

    RobinIsHoodColofulJackPotBar.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function RobinIsHoodColofulJackPotBar:onExit()
    RobinIsHoodColofulJackPotBar.super.onExit(self)
end

function RobinIsHoodColofulJackPotBar:initMachine(machine)
    self.m_machine = machine
end

--[[
    重置界面显示
]]
function RobinIsHoodColofulJackPotBar:resetView()
    for jackpotType,itemList in pairs(self.m_collectItems) do
        self.m_collectProcess[jackpotType] = 0
        self.m_collectEndProcess[jackpotType] = 0
        for index,item in ipairs(itemList) do
            item:runCsbAction("idle1")
        end

        if self.m_hitLightAnis[jackpotType] then
            self.m_hitLightAnis[jackpotType]:setVisible(false)
        end
    end
    self:runIdleAni()
end

--[[
    收集反馈动效
]]
function RobinIsHoodColofulJackPotBar:collectFeedBackAni(jackpotType,pointItem)
    if pointItem then
        self.m_collectEndProcess[jackpotType]  = self.m_collectEndProcess[jackpotType] + 1
        pointItem:setVisible(true)
        pointItem:runCsbAction("actionframe",false,function()
            pointItem:runCsbAction("idle3")

            --已经集满,其他的预中奖特效隐藏
            if self.m_collectEndProcess[jackpotType] == 3 then
                for tempType,jackpotIndex in pairs(JACKPOT_INDEX) do
                    if tempType ~= jackpotType then
                        local item = self:getFeedBackPoint(tempType,3)
                        item:runCsbAction("idle1")
                    end
                end
            elseif self.m_collectEndProcess[jackpotType] == 2 then
                local lastItem = self:getFeedBackPoint(jackpotType,3)
                lastItem:runCsbAction("idle2",true)
            end
        end)
    end

    
end

--[[
    获取收集反馈点
]]
function RobinIsHoodColofulJackPotBar:getFeedBackPoint(jackpotType,index)
    local itemList = self.m_collectItems[jackpotType]
    return itemList[index]
end

--[[
    获取收集进度
]]
function RobinIsHoodColofulJackPotBar:getProcessByType(jackpotType)
    self.m_collectProcess[jackpotType] = self.m_collectProcess[jackpotType] + 1
    --检测进度是否集满
    if self.m_collectProcess[jackpotType] >= 3 then
        self.m_collectProcess[jackpotType] = 3
    end
    return self.m_collectProcess[jackpotType]
end

--[[
    显示中奖光效
]]
function RobinIsHoodColofulJackPotBar:showHitLight(jackpotType)
    -- local jackpotIndex = JACKPOT_INDEX[jackpotType]
    -- self:runCsbAction("actionframe"..jackpotIndex,true)

    local hitLight = self.m_hitLightAnis[jackpotType]
    if hitLight then
        hitLight:setVisible(true)
        hitLight:runCsbAction("actionframe",true)
    end
end

--[[
    idle
]]
function RobinIsHoodColofulJackPotBar:runIdleAni()
    self:runCsbAction("idle",true)
end

-- 更新jackpot 数值信息
--
function RobinIsHoodColofulJackPotBar:updateJackpotInfo()
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

function RobinIsHoodColofulJackPotBar:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local label3=self.m_csbOwner[MinorName]
    local label4=self.m_csbOwner[MiniName]
    

    local info1 = {label = label1, sx = 0.8, sy = 0.8}
    local info2 = {label = label2, sx = 0.8, sy = 0.8}
    local info3 = {label = label3, sx = 0.8, sy = 0.8}
    local info4 = {label = label4, sx = 0.8, sy = 0.8}
    self:updateLabelSize(info1, 397)
    self:updateLabelSize(info2, 397)
    self:updateLabelSize(info3, 339)
    self:updateLabelSize(info4, 339)
end

function RobinIsHoodColofulJackPotBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end




return RobinIsHoodColofulJackPotBar