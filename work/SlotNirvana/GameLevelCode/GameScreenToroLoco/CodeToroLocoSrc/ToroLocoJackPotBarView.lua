---
--xcyy
--2018年5月23日
--ToroLocoJackPotBarView.lua
local ToroLocoPublicConfig = require "ToroLocoPublicConfig"
local ToroLocoJackPotBarView = class("ToroLocoJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini"

local JACKPOT_INDEX = {
    Grand = 1,
    Major = 2,
    Minor = 3,
    Mini = 4
}

function ToroLocoJackPotBarView:initUI()
    self:createCsbNode("JackPotBarToroLoco.csb")

    -- 过场动画bonus
    self.m_jackpotLockSpine = util_spineCreate("ToroLoco_jackpot_lock", true, true)
    self:findChild("Node_suoding"):addChild(self.m_jackpotLockSpine)

    self:addClick(self:findChild("Panel_click"))

    self.m_winEffectNode = {}
    for index = 1, 4 do
        self.m_winEffectNode[index] = util_createAnimation("JackPotBarToroLoco_tx.csb")
        self:findChild("Node_tx"..index):addChild(self.m_winEffectNode[index])
        self.m_winEffectNode[index]:setVisible(false)
    end
end

function ToroLocoJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function ToroLocoJackPotBarView:onEnter()
    ToroLocoJackPotBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(
        self,
        function()
            self:updateJackpotInfo()
        end,
        0.08
    )
end

-- 更新jackpot 数值信息
--
function ToroLocoJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self:findChild(GrandName), 1, true)
    self:changeNode(self:findChild(MajorName), 2, true)
    self:changeNode(self:findChild(MinorName), 3)
    self:changeNode(self:findChild(MiniName), 4)

    self:updateSize()
end

function ToroLocoJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MajorName]
    local info1 = {label = label1, sx = 1, sy = 1}
    local info2 = {label = label2, sx = 0.97, sy = 0.97}
    local label3 = self.m_csbOwner[MinorName]
    local info3 = {label = label3, sx = 0.97, sy = 0.97}
    local label4 = self.m_csbOwner[MiniName]
    local info4 = {label = label4, sx = 0.97, sy = 0.97}
    self:updateLabelSize(info1, 239)
    self:updateLabelSize(info2, 203)
    self:updateLabelSize(info3, 203)
    self:updateLabelSize(info4, 203)
end

function ToroLocoJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 50, nil, nil, true))
end

--默认按钮监听回调
function ToroLocoJackPotBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Panel_click" then 
        gLobalNoticManager:postNotification("SHOW_UNLOCK_JACKPOT")
    end
end

--[[
    锁定grand
]]
function ToroLocoJackPotBarView:lockGrand()
    if not self.m_isUnLockClicking and self.m_jackpotLockSpine:isVisible() then
        return
    end

    -- 防止快速切换bet 显示出错
    if self.m_isLockClicking then
        return
    end

    self.m_isLockClicking = true
    self.m_isUnLockClicking = false

    gLobalSoundManager:playSound(ToroLocoPublicConfig.SoundConfig.sound_ToroLoco_bet_lock)

    self.m_jackpotLockSpine:setVisible(true)
    util_spinePlay(self.m_jackpotLockSpine, "darkstart", false)
    util_spineEndCallFunc(self.m_jackpotLockSpine, "darkstart" ,function ()
        util_spinePlay(self.m_jackpotLockSpine, "darkidle", true)
        self.m_isLockClicking = false
    end)

    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("darkstart", false, function()
        self:runCsbAction("darkidle", true)
    end)
    self.m_machine.m_respinJackPotBarView:lockGrand()
end

--[[
    解锁grand
]]
function ToroLocoJackPotBarView:unLockGrand(_isFirstComeIn)
    if _isFirstComeIn then
        self.m_jackpotLockSpine:setVisible(false)
        self.m_machine.m_respinJackPotBarView:unLockGrand()
        return
    end

    if not self.m_isLockClicking and not self.m_jackpotLockSpine:isVisible() then
        return
    end

    -- 防止快速切换bet 显示出错
    if self.m_isUnLockClicking then
        return
    end

    self.m_isLockClicking = false
    self.m_isUnLockClicking = true

    gLobalSoundManager:playSound(ToroLocoPublicConfig.SoundConfig.sound_ToroLoco_bet_unlock)

    self.m_jackpotLockSpine:setVisible(true)
    util_spinePlay(self.m_jackpotLockSpine, "darkover", false)
    util_spineEndCallFunc(self.m_jackpotLockSpine, "darkover" ,function ()
        self.m_jackpotLockSpine:setVisible(false)
        self.m_isUnLockClicking = false
    end)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("darkover", false)

    self.m_machine.m_respinJackPotBarView:unLockGrand()
end

--[[
    播放中奖效果
]]
function ToroLocoJackPotBarView:playWinEffect(_indexType)
    local jackpotIndex = JACKPOT_INDEX[_indexType]
    self.m_winEffectNode[jackpotIndex]:setVisible(true)
    if jackpotIndex == 1 then
        self.m_winEffectNode[jackpotIndex]:runCsbAction("actionframe3", true)
    else
        self.m_winEffectNode[jackpotIndex]:runCsbAction("actionframe4", true)
    end
end

--[[
    隐藏中奖效果
]]
function ToroLocoJackPotBarView:hideWinEffect(_indexType)
    local jackpotIndex = JACKPOT_INDEX[_indexType]
    self.m_winEffectNode[jackpotIndex]:setVisible(false)
end

return ToroLocoJackPotBarView
