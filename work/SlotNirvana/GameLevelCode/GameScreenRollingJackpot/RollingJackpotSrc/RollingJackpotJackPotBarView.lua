---
--xcyy
--2018年5月23日
--RollingJackpotJackPotBarView.lua

local RollingJackpotJackPotBarView = class("RollingJackpotJackPotBarView",util_require("Levels.BaseLevelDialog"))
local ConfigInstance  = require("RollingJackpotPublicConfig"):getInstance()
local SoundConfig = ConfigInstance.SoundConfig
function RollingJackpotJackPotBarView:initUI()
    self.m_lableNum = 8  --jackpot个数
    self:createCsbNode("RollingJackpot_Jackpot_base.csb")

    self:runCsbAction("idle",true)
    self:initLableInfo()
    self:createLockItem()

    self.m_waitNode = cc.Node:create()
    self:addChild(self.m_waitNode)
end

function RollingJackpotJackPotBarView:initLableInfo()
    self.m_lableInfo = {}
    for index = 1,self.m_lableNum do
        local labelName  = string.format("m_lb_coins_%d", 13 - index)
        if index == 1 then
            labelName = labelName.."+"
        end
        local labCoins = self:findChild(labelName)
        local labInfo = {}
        labInfo.label = labCoins
        local labSize = labCoins:getContentSize()
        labInfo.width = labSize.width
        labInfo.sx = labCoins:getScaleX()
        labInfo.sy = labCoins:getScaleY()
        table.insert(self.m_lableInfo, labInfo)
    end
end

function RollingJackpotJackPotBarView:onExit()
 
end

function RollingJackpotJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function RollingJackpotJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function RollingJackpotJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner
    for index = 1,self.m_lableNum do
        local labelName  = string.format("m_lb_coins_%d", 13 - index)
        if index == 1 then
            labelName = labelName.."+"
        end
        self:changeNode(self:findChild(labelName),index,index <= self.m_lableNum - 3)
    end
    self:updateSize()
end

function RollingJackpotJackPotBarView:updateSize()
    for index = 1,self.m_lableNum do
        local lableInfo = self.m_lableInfo[index]
        if lableInfo then
            self:updateLabelSize(lableInfo, lableInfo.width)
        end
    end
end

function RollingJackpotJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,30,nil,nil,true))
end

function RollingJackpotJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end

function RollingJackpotJackPotBarView:createLockItem()
    self.m_lockItem = util_createAnimation("RollingJackpot_Jackpot_lock.csb")
    self:findChild("lock"):addChild(self.m_lockItem)
    self:addClick(self.m_lockItem:findChild("click_Btn"))
end

function RollingJackpotJackPotBarView:setCriticalValue(coins)
    self.m_lockItem:findChild("m_lb_num"):setString(util_formatCoins(coins,3))
end

function RollingJackpotJackPotBarView:updateBetLevelUI(betLevel, isInit)
    if isInit then
        if betLevel == 1 then
            self.m_lockItem:runCsbAction("jiesuoidle", true)
        else
            self.m_lockItem:runCsbAction("darkidle", true)
        end
    else
        local csbAct = self.m_lockItem.m_csbAct
        self.m_waitNode:stopAllActions( )
        if betLevel == 1 then
            gLobalSoundManager:playSound(SoundConfig.sound_bet_unlock)
            local time=util_csbGetAnimTimes(csbAct,"jiesuo",60)
            self.m_lockItem:runCsbAction("jiesuo", false)
            local particle1 = self.m_lockItem:findChild("Particle_1")
            particle1:resetSystem()
            util_performWithDelay(self.m_waitNode, function()
                self.m_lockItem:runCsbAction("jiesuoidle", true)
            end, time)
        else
            gLobalSoundManager:playSound(SoundConfig.sound_bet_lock)
            local time=util_csbGetAnimTimes(csbAct,"dark",60)
            self.m_lockItem:runCsbAction("dark", false)
            util_performWithDelay(self.m_waitNode, function()
                self.m_lockItem:runCsbAction("darkidle", true)
            end, time)
        end
    end
end

--默认按钮监听回调
function RollingJackpotJackPotBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "click_Btn" then
        self.m_machine:unlockHigherBet()
    end
end

function RollingJackpotJackPotBarView:showJackpotWin(rapidTimes)
    local _rapidTimes = rapidTimes > 12 and 12 or rapidTimes
    local parent_str = "win_".._rapidTimes
    local effectWin = util_createAnimation("RollingJackpot_Jackpot_win.csb")
    self:findChild(parent_str):addChild(effectWin)
    effectWin:playAction("actionframe", true)
    local delayAct = cc.DelayTime:create(3)
    local removeSelf = cc.RemoveSelf:create()
    effectWin:runAction(cc.Sequence:create(delayAct, removeSelf))
end

return RollingJackpotJackPotBarView