---
--xcyy
--2018年5月23日
--BunnyBountyColofulJackPotBar.lua
local PublicConfig = require "BunnyBountyPublicConfig"
local BunnyBountyColofulJackPotBar = class("BunnyBountyColofulJackPotBar",util_require("Levels.BaseLevelDialog"))

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

function BunnyBountyColofulJackPotBar:initUI(params)
    self:initMachine(params.machine)
    self:createCsbNode("BunnyBounty_dfdc_jackpot.csb")
    self:runIdleAni()

    self.m_collectItems = {}    --所有的收集点
    self.m_collectProcess = {}  --所有的收集进度
    for jackpotType,jackpotIndex in pairs(JACKPOT_INDEX) do
        self.m_collectItems[jackpotType] = {}
        self.m_collectProcess[jackpotType] = 0
        for index = 1,3 do
            local item = util_createAnimation("BunnyBounty_dfdc_jackpot_shouji.csb")
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
    end

    --grand乘倍动效
    self.m_grandMultiAni = util_createAnimation("BunnyBounty_dfdc_grand_x2.csb")
    self:findChild("Node_X2"):addChild(self.m_grandMultiAni)
    self.m_grandMultiAni:setVisible(false)
end

function BunnyBountyColofulJackPotBar:onEnter()

    BunnyBountyColofulJackPotBar.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function BunnyBountyColofulJackPotBar:onExit()
    BunnyBountyColofulJackPotBar.super.onExit(self)
end

function BunnyBountyColofulJackPotBar:initMachine(machine)
    self.m_machine = machine
end

--[[
    重置界面显示
]]
function BunnyBountyColofulJackPotBar:resetView()
    for jackpotType,itemList in pairs(self.m_collectItems) do
        self.m_collectProcess[jackpotType] = 0
        for index,item in ipairs(itemList) do
            item:setVisible(false)
        end
    end
    self:runIdleAni()

    self.m_grandMultiAni:setVisible(false)
end

--[[
    收集反馈动效
]]
function BunnyBountyColofulJackPotBar:collectFeedBackAni(jackpotType,pointItem)
    if pointItem then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_collect_egg_to_jp_feed_back)
        pointItem:setVisible(true)
        pointItem:runCsbAction("actionframe")
    end
end

--[[
    获取收集反馈点
]]
function BunnyBountyColofulJackPotBar:getFeedBackPoint(jackpotType,index)
    local itemList = self.m_collectItems[jackpotType]
    return itemList[index]
end

--[[
    获取收集进度
]]
function BunnyBountyColofulJackPotBar:getProcessByType(jackpotType)
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
function BunnyBountyColofulJackPotBar:showHitLight(jackpotType)
    local jackpotIndex = JACKPOT_INDEX[jackpotType]
    self:runCsbAction("actionframe"..jackpotIndex,true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_jackpot_bar_light)
end

--[[
    显示grand乘倍动效
]]
function BunnyBountyColofulJackPotBar:showGrandMultiAni()
    self.m_grandMultiAni:setVisible(true)
    self.m_grandMultiAni:runCsbAction("start")
end

--[[
    idle
]]
function BunnyBountyColofulJackPotBar:runIdleAni()
    self:runCsbAction("idle",true)
end

-- 更新jackpot 数值信息
--
function BunnyBountyColofulJackPotBar:updateJackpotInfo()
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

function BunnyBountyColofulJackPotBar:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local label3=self.m_csbOwner[MinorName]
    local label4=self.m_csbOwner[MiniName]
    

    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local info3={label=label3,sx=1,sy=1}
    local info4={label=label4,sx=1,sy=1}
    self:updateLabelSize(info1,345)
    self:updateLabelSize(info2,345)
    self:updateLabelSize(info3,280)
    self:updateLabelSize(info4,280)
end

function BunnyBountyColofulJackPotBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end




return BunnyBountyColofulJackPotBar