---
--xcyy
--2018年5月23日
--TheHonorOfZorroJackPotBarView.lua
local PublicConfig = require "TheHonorOfZorroPublicConfig"
local TheHonorOfZorroJackPotBarView = class("TheHonorOfZorroJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins1"
local MajorName = "m_lb_coins2"
local MinorName = "m_lb_coins3"
local MiniName = "m_lb_coins4" 

function TheHonorOfZorroJackPotBarView:initUI(params)
    self:initMachine(params.machine)
    self:createCsbNode("TheHonorOfZorro_base_jackpot.csb")

    self:runCsbAction("idleframe",true)

    --锁定动效
    self.m_lockNode = util_spineCreate("TheHonorOfZorro_jackpot",true,true)
    self:findChild("Node_lock"):addChild(self.m_lockNode)
    self.m_lockNode:setVisible(false)
    self.m_lockStatus = false

    --创建点击区域
    local layout = ccui.Layout:create() 
    self:findChild("Node_lock"):addChild(layout)    
    layout:setAnchorPoint(0.5,0.5)
    layout:setContentSize(CCSizeMake(480,100))
    layout:setTouchEnabled(true)
    self:addClick(layout)

    self.m_lockTip = util_createAnimation("TheHonorOfZorro_grand_tips.csb")
    self.m_lockTip:setVisible(false)
    self:findChild("Node_tips"):addChild(self.m_lockTip)

end

function TheHonorOfZorroJackPotBarView:onEnter()

    TheHonorOfZorroJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function TheHonorOfZorroJackPotBarView:onExit()
    TheHonorOfZorroJackPotBarView.super.onExit(self)
end

function TheHonorOfZorroJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function TheHonorOfZorroJackPotBarView:updateJackpotInfo()
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

function TheHonorOfZorroJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=0.9,sy=0.9}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.8,sy=0.8}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.72,sy=0.72}
    self:updateLabelSize(info1,388)
    self:updateLabelSize(info2,388)
    self:updateLabelSize(info3,388)
    self:updateLabelSize(info4,388)
end

function TheHonorOfZorroJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index,self.m_machine:getTotalBet())
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

--[[
    初始化锁定状态
]]
function TheHonorOfZorroJackPotBarView:initLockStatus(isLock)
    self.m_lockStatus = isLock
    util_spinePlay(self.m_lockNode,"idle")
    self.m_lockNode:setVisible(isLock)
end

--[[
    设置锁定状态
]]
function TheHonorOfZorroJackPotBarView:setLockStatus(isLock)
    if self.m_lockStatus == isLock then
        return
    end

    self.m_lockNode:stopAllActions()
    if isLock then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_lock_bet)
        self.m_lockNode:setVisible(true)
        util_spinePlay(self.m_lockNode,"suoding")
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TheHonorOfZorro_unlock_bet)
        self:hideLockTip()
        util_spinePlay(self.m_lockNode,"jiesuo")
        performWithDelay(self.m_lockNode,function()
            self.m_lockNode:setVisible(false)
        end,20 / 30)
    end
    self.m_lockStatus = isLock
end

--[[
    显示锁定提示
]]
function TheHonorOfZorroJackPotBarView:showLockTip()
    if self.m_isHideTip then
        return
    end
    self.m_lockTip:setVisible(true)
    self.m_lockTip:runCsbAction("suoding")
    performWithDelay(self.m_lockTip,function()
        self:hideLockTip()
    end,2.5)
end

--[[
    隐藏锁定提示
]]
function TheHonorOfZorroJackPotBarView:hideLockTip()
    if self.m_isHideTip then
        return
    end
    --只有进关卡时显示,一次性的
    self.m_isHideTip = true
    self.m_lockTip:stopAllActions()
    self.m_lockTip:runCsbAction("jiesuo",false,function()
        self.m_lockTip:setVisible(false)
    end)
end

--默认按钮监听回调
function TheHonorOfZorroJackPotBarView:clickFunc(sender)
    if self.m_lockStatus and self.m_machine:collectBarClickEnabled() then
        self.m_machine.m_bottomUI:changeBetCoinNumToHight()
    end
end


return TheHonorOfZorroJackPotBarView