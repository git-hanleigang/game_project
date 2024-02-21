---
--xcyy
--2018年5月23日
--CashRushJackpotsJackPotBarView.lua

local CashRushJackpotsJackPotBarView = class("CashRushJackpotsJackPotBarView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "CashRushJackpotsPublicConfig"

local GrandName = "m_lb_coins_grand"
local MegaName = "m_lb_coins_mega"
local MajorName = "m_lb_coins_major"
local MinorName = "m_lb_coins_minor"
local MiniName = "m_lb_coins_mini" 
local m_totalCount = 5

function CashRushJackpotsJackPotBarView:initUI(machine)

    self:createCsbNode("CashRushJackpots_jackpot.csb")

    self.m_machine = machine

    self.m_lightTbl = {}
    self.m_tblClickPanel = {}
    self.m_lockJackpotTbl = {}
    for i=1, m_totalCount do
        -- jackpot栏
        local csbName = "CashRushJackpots_jackpot_"..i..".csb"
        self.m_lightTbl[i] = util_createAnimation(csbName)
        self:findChild("Node_lock"..i):addChild(self.m_lightTbl[i])
        self.m_tblClickPanel[i] = self.m_lightTbl[i]:findChild("click_Panel")

        -- jackpotLock栏
        self.m_lockJackpotTbl[i] = util_createView("CodeCashRushJackpotsSrc.CashRushJackpotsLockJackpotBar", i)
        self:findChild("Node_Tip"..i):addChild(self.m_lockJackpotTbl[i])
    end

    for i=1, m_totalCount do
        self.m_tblClickPanel[i]:setTag(i)
        self:addClick(self.m_tblClickPanel[i])
    end

    self.m_scWaitNodeAction = cc.Node:create()
    self:addChild(self.m_scWaitNodeAction)
end

--默认按钮监听回调
function CashRushJackpotsJackPotBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click_Panel" then
        self:chooseJackpotUnlock(tag)
    end
end

--解锁jackpot
function CashRushJackpotsJackPotBarView:chooseJackpotUnlock(_index)
    local index = _index
    self.m_machine.m_bottomUI:changeBetCoinNumToUnLock(index-1)
    -- self:jackpotLock(index)
end

-- 触发
function CashRushJackpotsJackPotBarView:triggerJackpotAction(_jackpotIndex)
    local jackpotLevel = 5 - _jackpotIndex + 1
    for i=1, m_totalCount do
        if i == jackpotLevel then
            self:findChild("zhongjiang_"..i):setVisible(true)
        else
            self:findChild("zhongjiang_"..i):setVisible(false)
        end
    end
    local idleName = "idle"..jackpotLevel
    self:runCsbAction("actionframe", true)
end

function CashRushJackpotsJackPotBarView:setJackpotIdle()
    local jackpotLevel = self.m_lastLevel
    if not jackpotLevel then
        jackpotLevel = self.m_machine:getCurJackpotLevel()
    end
    local idleName = "idle"..jackpotLevel
    self:runCsbAction(idleName, true)
end

-- 锁定
function CashRushJackpotsJackPotBarView:jackpotLock(_index)
    local index = _index
    local lastLevel = self.m_lastLevel
    for i=1, m_totalCount do
        if i <= index then
            self.m_tblClickPanel[i]:setVisible(false)
        else
            self.m_tblClickPanel[i]:setVisible(true)
        end
    end
    if not self:checkIndexExist(index) then
        return
    end
    util_resetCsbAction(self.m_csbAct)
    for i=1, m_totalCount do
        util_resetCsbAction(self.m_lightTbl[i].m_csbAct)
    end
    
    if not lastLevel then
        local idleName = "idle"..index
        self:runCsbAction(idleName, true)
        for i=1, m_totalCount do
            if i <= index then
                self.m_lightTbl[i]:runCsbAction("idle2", true)
            else
                self.m_lightTbl[i]:runCsbAction("idle", true)
                self:playLockTipsAction(i)
            end
        end
        self.m_lastLevel = index
    else
        if not self:checkIndexExist(index) then
            return
        end
        -- 解锁
        if index > lastLevel then
            gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Unlock)
            local idleName = "idle"..index
            local m_count = index
            for i=lastLevel+1, index do
                self.m_lightTbl[i]:runCsbAction("jiesuo", false, function()
                    self.m_lightTbl[i]:runCsbAction("idle2", true)
                    if i == m_count then
                        self:runCsbAction(idleName, true)
                    end
                end)
                self.m_lockJackpotTbl[i]:hideLockTips()
            end
        elseif index < lastLevel then
            -- 锁定
            gLobalSoundManager:playSound(PublicConfig.Music_Jackpot_Lock)
            local idleName = "idle"..index
            local m_count = lastLevel
            for i=index+1, lastLevel do
                self.m_lightTbl[i]:runCsbAction("suoding", false, function()
                    self.m_lightTbl[i]:runCsbAction("idle", true)
                    if i == m_count then
                        self:runCsbAction(idleName, true)
                    end
                end)
                self:playLockTipsAction(i)
            end
        else
            local idleName = "idle"..index
            self:runCsbAction(idleName, true)
            for i=1, m_totalCount do
                if i <= index then
                    self.m_lightTbl[i]:runCsbAction("idle2", true)
                else
                    self.m_lightTbl[i]:runCsbAction("idle", true)
                end
            end
        end
        self.m_lastLevel = index
    end
end

function CashRushJackpotsJackPotBarView:checkIndexExist(_index)
    local index = _index
    if index >= 1 and index <= m_totalCount then
        return true
    end
    return false
end

--延时关闭jackpot锁定tips
function CashRushJackpotsJackPotBarView:playLockTipsAction(_index)
    local index = _index
    self.m_lockJackpotTbl[index]:showLockTips()
    self.m_scWaitNodeAction:stopAllActions()
    util_schedule(self.m_scWaitNodeAction, function()
        for i=1, m_totalCount do
            self.m_lockJackpotTbl[i]:hideLockTips()
        end
        self.m_scWaitNodeAction:stopAllActions()
    end, 3.0)
end

function CashRushJackpotsJackPotBarView:onEnter()

    CashRushJackpotsJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function CashRushJackpotsJackPotBarView:onExit()
    CashRushJackpotsJackPotBarView.super.onExit(self)
end

function CashRushJackpotsJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

-- 更新jackpot 数值信息
--
function CashRushJackpotsJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MegaName),2,true)
    self:changeNode(self:findChild(MajorName),3,true)
    self:changeNode(self:findChild(MinorName),4)
    self:changeNode(self:findChild(MiniName),5)

    self:updateSize()
end

function CashRushJackpotsJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local info1={label=label1,sx=1.05,sy=1.05}

    local label2=self.m_csbOwner[MegaName]
    local info2={label=label2,sx=0.95,sy=0.95}

    local label3=self.m_csbOwner[MajorName]
    local info3={label=label3,sx=0.9,sy=0.9}
    
    local label4=self.m_csbOwner[MinorName]
    local info4={label=label4,sx=0.85,sy=0.85}

    local label5=self.m_csbOwner[MiniName]
    local info5={label=label5,sx=0.78,sy=0.78}

    self:updateLabelSize(info1,376)
    self:updateLabelSize(info2,376)
    self:updateLabelSize(info3,376)
    self:updateLabelSize(info4,376)
    self:updateLabelSize(info5,376)
end

function CashRushJackpotsJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end




return CashRushJackpotsJackPotBarView