---
--xcyy
--2018年5月23日
--MayanMysteryColofulJackPotBar.lua
local PublicConfig = require "MayanMysteryPublicConfig"
local MayanMysteryColofulJackPotBar = class("MayanMysteryColofulJackPotBar",util_require("base.BaseView"))

local EpicName = "m_lb_epic"
local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 

local JACKPOT_INDEX = {
    epic = 1,
    grand = 2,
    major = 3,
    minor = 4,
    mini = 5
}

function MayanMysteryColofulJackPotBar:initUI(params)
    self:initMachine(params.machine)
    self:createCsbNode("MayanMystery_jackpot.csb")

    self.m_jackpotItem = {}
    for index = 1, 6 do
        local jackpotItem = util_createAnimation("MayanMystery_dfdc_jackpot_"..index..".csb")
        self:findChild("Node_1"):addChild(jackpotItem)
        self.m_jackpotItem[index] = jackpotItem
    end

    self:runIdleAni()

    self.m_collectItems = {}    --所有的收集点
    self.m_collectProcess = {}  --所有的收集进度
    for jackpotType, jackpotIndex in pairs(JACKPOT_INDEX) do
        self.m_collectItems[jackpotIndex] = {}
        self.m_collectProcess[jackpotIndex] = 0
        for index = 1,3 do
            local item = util_createAnimation("MayanMystery_dfdc_sj_jinbi_di.csb")
            self.m_collectItems[jackpotIndex][index] = item
            --收集挂点命名规则为Node_+jackpot类型+索引
            local parentNode = self.m_jackpotItem[jackpotIndex]:findChild("Node_"..jackpotType.."_sj_"..index)
            if parentNode then
                parentNode:addChild(item)
            end
        end
    end
end

function MayanMysteryColofulJackPotBar:onEnter()

    MayanMysteryColofulJackPotBar.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function MayanMysteryColofulJackPotBar:onExit()
    MayanMysteryColofulJackPotBar.super.onExit(self)
end

function MayanMysteryColofulJackPotBar:initMachine(machine)
    self.m_machine = machine
end

--[[
    重置界面显示
]]
function MayanMysteryColofulJackPotBar:resetView()
    for jackpotType, itemList in ipairs(self.m_collectItems) do
        for index, item in ipairs(itemList) do
            item:runCsbAction("idle", true)
        end
    end
    self:runIdleAni()
end

--[[
    idle
]]
function MayanMysteryColofulJackPotBar:runIdleAni()
    for index = 1, 6 do
        self.m_jackpotItem[index]:runCsbAction("idle",true)
    end
end

-- 更新jackpot 数值信息
--
function MayanMysteryColofulJackPotBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self.m_jackpotItem[1]:findChild(EpicName),1,true)
    self:changeNode(self.m_jackpotItem[2]:findChild(GrandName),2,true)
    self:changeNode(self.m_jackpotItem[3]:findChild(MajorName),3,true)
    self:changeNode(self.m_jackpotItem[4]:findChild(MinorName),4)
    self:changeNode(self.m_jackpotItem[5]:findChild(MiniName),5)
    self:changeNode(self.m_jackpotItem[6]:findChild(EpicName),1,true)

    self:updateSize()
end

function MayanMysteryColofulJackPotBar:updateSize()

    local label1=self.m_jackpotItem[1]:findChild(EpicName)
    local label2=self.m_jackpotItem[2]:findChild(GrandName)
    local label3=self.m_jackpotItem[3]:findChild(MajorName)
    local label4=self.m_jackpotItem[4]:findChild(MinorName)
    local label5=self.m_jackpotItem[5]:findChild(MiniName)
    local label6=self.m_jackpotItem[6]:findChild(EpicName)

    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local info3={label=label3,sx=1,sy=1}
    local info4={label=label4,sx=1,sy=1}
    local info5={label=label5,sx=1,sy=1}
    local info6={label=label6,sx=1,sy=1}

    self:updateLabelSize(info1,272)
    self:updateLabelSize(info2,226)
    self:updateLabelSize(info3,208)
    self:updateLabelSize(info4,185)
    self:updateLabelSize(info5,180)
    self:updateLabelSize(info6,272)
end

function MayanMysteryColofulJackPotBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,50,nil,nil,true))
end

--[[
    显示不同的jackpot
]]
function MayanMysteryColofulJackPotBar:showJackpot(_isHaveProcess)
    local isShow = true
    if _isHaveProcess then
        isShow = true
        self.m_jackpotItem[1]:setVisible(true)
        self.m_jackpotItem[6]:setVisible(false)
        self.m_jackpotItem[1]:runCsbAction("idle1", false)
    else
        isShow = false
        self.m_jackpotItem[1]:setVisible(false)
        self.m_jackpotItem[6]:setVisible(true)
    end

    for jackpotType,jackpotIndex in pairs(JACKPOT_INDEX) do
        for index = 1,3 do
            local item = self.m_collectItems[jackpotIndex][index]
            if item then
                item:setVisible(isShow)
            end
        end
    end
end

--[[
    remove mini
]]
function MayanMysteryColofulJackPotBar:playRemoveMiniEffect(_func)
    self.m_jackpotItem[5]:runCsbAction("remove", false, function()
        if _func then
            _func()
        end
    end)
end

--[[
    epic 出现
]]
function MayanMysteryColofulJackPotBar:playEpicStartEffect(_func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MayanMystery_colorFul_epic_start)
    self.m_jackpotItem[1]:runCsbAction("show", false, function()
        self.m_jackpotItem[1]:runCsbAction("idle", true)
        if _func then
            _func()
        end
    end)
end

--[[
    epic 显示
]]
function MayanMysteryColofulJackPotBar:playEpicShowEffect( )
    self.m_jackpotItem[6]:runCsbAction("idle",true)
end

--[[
    epic 消失
]]
function MayanMysteryColofulJackPotBar:playEpicOverEffect( )
    self.m_jackpotItem[6]:runCsbAction("over", false, function()
    end)
end

--[[
    epic 隐藏
]]
function MayanMysteryColofulJackPotBar:playEpicHideEffect( )
    self.m_jackpotItem[1]:runCsbAction("idle1", false)
end

--[[
    收集事件
]]
function MayanMysteryColofulJackPotBar:getProgressFlyEndPos(_jpIndex, _progressValue)
    _progressValue = math.min(3, _progressValue)

    local node = self.m_collectItems[_jpIndex][_progressValue]
    local worldPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))

    return worldPos
end

--[[
    飞行完毕
]]
function MayanMysteryColofulJackPotBar:playProgressFlyEndAnim(_jpIndex, _progressValue)
    local pointCsb = self.m_collectItems[_jpIndex][_progressValue]
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MayanMystery_bonusGame_collect_fankui)

    pointCsb:runCsbAction("actionframe", false, function()
        pointCsb:runCsbAction("idle2", true)
        if _progressValue == 2 then
            self.m_collectItems[_jpIndex][3]:runCsbAction("idle1", true)
        end
    end)
end

--[[
    jackpot中奖
]]
function MayanMysteryColofulJackPotBar:playJackpotWinEffect(_jackpotIndex)
    self.m_jackpotItem[_jackpotIndex]:runCsbAction("actionframe", true)
end

return MayanMysteryColofulJackPotBar