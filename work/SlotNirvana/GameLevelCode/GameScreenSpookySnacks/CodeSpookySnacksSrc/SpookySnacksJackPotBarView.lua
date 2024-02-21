---
--xcyy
--2018年5月23日
--SpookySnacksJackPotBarView.lua
local PublicConfig = require "SpookySnacksPublicConfig"
local SpookySnacksJackPotBarView = class("SpookySnacksJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_num_grand"
local MajorName = "m_lb_num_major"
local MinorName = "m_lb_num_minor"
local MiniName = "m_lb_num_mini"

local WinningName = {
    "grand",
    "major",
    "minor",
    "mini"
}

function SpookySnacksJackPotBarView:initUI()
    self:createCsbNode("SpookySnacks_jackpot.csb")
    self:runCsbAction("idle",true)
    self:addLockEffect()

    self.m_lockStatus = false

    --创建点击区域
    local layout = ccui.Layout:create() 
    self:findChild("Node_1"):addChild(layout)    
    layout:setAnchorPoint(0.5,0.5)
    local pos = util_convertToNodeSpace(self:findChild("SpookySnacks_reel_16_3"),self:findChild("Node_1"))
    layout:setPosition(pos)
    layout:setContentSize(CCSizeMake(347,83))
    layout:setTouchEnabled(true)
    self:addClick(layout,1000)

    self.actNode = cc.Node:create()
    self:addChild(self.actNode)
end

function SpookySnacksJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function SpookySnacksJackPotBarView:onEnter()
    SpookySnacksJackPotBarView.super.onEnter(self)
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
function SpookySnacksJackPotBarView:updateJackpotInfo()
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

function SpookySnacksJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MajorName]
    local info1 = {label = label1, sx = 1, sy = 1}
    local info2 = {label = label2, sx = 1, sy = 1}
    local label3 = self.m_csbOwner[MinorName]
    local info3 = {label = label3, sx = 1, sy = 1}
    local label4 = self.m_csbOwner[MiniName]
    local info4 = {label = label4, sx = 1, sy = 1}
    self:updateLabelSize(info1, 278)
    self:updateLabelSize(info2, 278)
    self:updateLabelSize(info3, 236)
    self:updateLabelSize(info4, 236)
end

function SpookySnacksJackPotBarView:changeNode(label, index, isJump)
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local m_runSpinResultData = self.m_machine.m_runSpinResultData or {}
    local selfData = m_runSpinResultData.p_selfMakeData or {}
    local avgBet = selfData.avgBet or nil
    if self.m_machine.m_isSuperFree and avgBet then
        lineBet = self.m_machine.m_runSpinResultData.p_selfMakeData.avgBet
    end
    local value = self.m_machine:BaseMania_updateJackpotScore(index,lineBet)
    label:setString(util_formatCoins(value, 20, nil, nil, true))
end

--中奖框
-- function SpookySnacksJackPotBarView:addWinningEffect()
--     self.winList = {}
--     for i,v in ipairs(WinningName) do
--         local item = util_createAnimation("SpookySnacks_respin_jackpot_zhongjiang.csb")
--         self:findChild(v.."_win"):addChild(item)
--         item.name = v
--         item:setVisible(false)
--         self.winList[v] = item
--     end
-- end

-- --展示中奖框
-- function SpookySnacksJackPotBarView:showWinningEffect(jackpotType)
--     local type = string.lower(jackpotType)
--     local item = self.winList[tostring(type)]
--     if not tolua.isnull(item) then
--         item:runCsbAction("actionframe")
--     end
-- end

--lock
function SpookySnacksJackPotBarView:addLockEffect()
    self.lockEffect = util_createAnimation("SpookySnacks_jackpot_lock.csb")
    self:findChild("Node_lock"):addChild(self.lockEffect)
    -- self.lockEffect:setVisible(false)
end

--锁定
function SpookySnacksJackPotBarView:showJackpotLock()
    self.actNode:stopAllActions()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_betSuoDing_show)
    self.lockEffect:runCsbAction("over")
    self.m_lockStatus = true
    performWithDelay(self.actNode,function ()
        self.lockEffect:runCsbAction("idle")
    end,62/60)
end

--解锁
function SpookySnacksJackPotBarView:showJackpotUnLock()
    self.actNode:stopAllActions()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_betSuoDing_hide)
    self.lockEffect:runCsbAction("start")
    self.m_lockStatus = false
    performWithDelay(self.actNode,function ()
        self.lockEffect:runCsbAction("idle2")
    end,28/60)
end

--默认按钮监听回调
function SpookySnacksJackPotBarView:clickFunc(sender)
    if self.m_lockStatus then
        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")
    end
end

-- 判断 是否解锁了
function SpookySnacksJackPotBarView:checkIsJieSuo( )
    return self.m_lockStatus
end

return SpookySnacksJackPotBarView
