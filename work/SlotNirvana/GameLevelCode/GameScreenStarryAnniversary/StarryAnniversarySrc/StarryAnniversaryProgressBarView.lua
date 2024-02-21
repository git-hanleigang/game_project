---
--xcyy
--2018年5月23日
--StarryAnniversaryProgressBarView.lua
local PublicConfig = require "StarryAnniversaryPublicConfig"
local StarryAnniversaryProgressBarView = class("StarryAnniversaryProgressBarView", util_require("base.BaseView"))

local PROGRESS_WIDTH = 710
function StarryAnniversaryProgressBarView:initUI()
    self:createCsbNode("StarryAnniversary_base_Collection.csb")

    --星星
    self.m_starNode = util_createAnimation("StarryAnniversary_Collection_star.csb")
    self:findChild("Node_star"):addChild(self.m_starNode)

    -- 进度条
    self.m_progressNode = util_createAnimation("StarryAnniversary_Collection_Progress.csb")
    self:findChild("Node_progress"):addChild(self.m_progressNode)
    self.m_progressSpine = util_spineCreate("StarryAnniversary_Collection_Progress",true,true)
    self.m_progressNode:findChild("Node_spine"):addChild(self.m_progressSpine)
    util_spinePlay(self.m_progressSpine, "idle", true)
    self.m_progressAddNode = util_createAnimation("StarryAnniversary_Collection_Progress_shangzhang.csb")
    self.m_progressNode:findChild("Node_add"):addChild(self.m_progressAddNode)

    -- 进度条锁定
    self.m_progressLockNode = util_createAnimation("StarryAnniversary_Collection_Progress_lock.csb")
    self.m_progressNode:findChild("Node_lock"):addChild(self.m_progressLockNode)
    self:addClick(self.m_progressLockNode:findChild("click_layout"))

    self.m_eggNode = util_createAnimation("StarryAnniversary_Collection_egg.csb")
    self:findChild("Node_egg"):addChild(self.m_eggNode)
    self.m_eggGuangNode = util_createAnimation("StarryAnniversary_tanban_guang.csb")
    self.m_eggNode:findChild("Node_guang"):addChild(self.m_eggGuangNode)
    self.m_eggGuangNode:setVisible(false)

    -- 按钮
    self.m_tipsBtnNode = util_createAnimation("StarryAnniversary_Collection_BtnInfo.csb")
    self:findChild("Node_BtnInfo"):addChild(self.m_tipsBtnNode)
    self:addClick(self.m_tipsBtnNode:findChild("Button_info"))

    -- tips
    self.m_tipsNode = util_createAnimation("StarryAnniversary_Collection_BtnTips.csb")
    self.m_tipsBtnNode:findChild("Node_tips"):addChild(self.m_tipsNode)

    self.actNode = cc.Node:create()
    self:addChild(self.actNode)
end

--默认按钮监听回调
function StarryAnniversaryProgressBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click_layout" then 
        gLobalNoticManager:postNotification("SHOW_UNLOCK_PROGRESS")
    end

    if name == "Button_info" then 
        gLobalNoticManager:postNotification("SHOW_TIPS")
    end
end

function StarryAnniversaryProgressBarView:initLoadingbar(_percent)
    self.m_progressNode:findChild("Node_move"):setPositionX(_percent * 0.01 * PROGRESS_WIDTH)
end

function StarryAnniversaryProgressBarView:updateLoadingbar(_collectCount, _needCount, _update, _func)
    local percent = self:getPercent(_collectCount, _needCount)
    if _update then
        self:initLoadingbar(percent)
    else
        self:updateLoadingAct(percent, _func)
    end
end

function StarryAnniversaryProgressBarView:updateLoadingAct(_percent, _func)
    self.m_starNode:runCsbAction("actionframe", false)

    self.m_progressAddNode:runCsbAction("actionframe", false)
    self.actNode:stopAllActions() 
    local oldPercent = self.m_progressNode:findChild("Node_move"):getPositionX() / PROGRESS_WIDTH * 100
    local curOldPercent = self.m_progressNode:findChild("Node_move"):getPositionX() / PROGRESS_WIDTH * 100
    util_schedule(self.actNode,function( )
        oldPercent = oldPercent + (_percent-curOldPercent)/16
        if oldPercent >= _percent then
            oldPercent = _percent
            self.m_progressNode:findChild("Node_move"):setPositionX(oldPercent * 0.01 * PROGRESS_WIDTH)
            self.actNode:stopAllActions() 
            if _func then
                _func()
            end
        else
            self.m_progressNode:findChild("Node_move"):setPositionX(oldPercent * 0.01 * PROGRESS_WIDTH)
        end
    end,0.05)
end


function StarryAnniversaryProgressBarView:getPercent(_collectCount, _needCount)
    local percent = 0
    if _collectCount and _needCount  then
        if _collectCount >= _needCount and _needCount ~= 0 then
            percent = 100
        elseif _collectCount == 0 and _needCount == 0 then
            percent = 0
        else
            percent = (_collectCount / _needCount) * 100
        end
    end
    return percent
end

--锁定进度条
function StarryAnniversaryProgressBarView:lock(_isComeIn)
    if _isComeIn then
        self.m_progressLockNode:setVisible(true)
        self.m_progressLockNode:runCsbAction("idle", true)
    else
        util_resetCsbAction(self.m_progressLockNode.m_csbAct)
        self.m_progressLockNode:setVisible(true)
        self.m_progressLockNode:runCsbAction("start", false, function (  )
            self.m_progressLockNode:runCsbAction("idle", true)
        end)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_bet_lock)
    end
end

--解锁进度条
function StarryAnniversaryProgressBarView:unLock(_isComeIn)
    if _isComeIn then
        self.m_progressLockNode:setVisible(false)
    else
        for index = 1, 4 do
            local particle = self.m_progressLockNode:findChild("Particle_"..index)
            if particle then
                particle:resetSystem()
            end
        end
        util_resetCsbAction(self.m_progressLockNode.m_csbAct)
        self.m_progressLockNode:runCsbAction("over", false, function (  )
            -- self.m_progressLockNode:setVisible(false)
        end)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_bet_unlock)
    end
end

--[[
    进度条触发
]]
function StarryAnniversaryProgressBarView:playTriggerEffect(_func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_bet_trigger)

    self.m_starNode:runCsbAction("actionframe2", false)
    self.m_progressNode:runCsbAction("actionframe", false, function()
        self.m_progressNode:runCsbAction("idle", false)
    end)
    self.m_eggNode:runCsbAction("actionframe2", false, function()
        self.m_eggNode:runCsbAction("idle2", true)
        performWithDelay(self, function()
            if _func then
                _func()
            end
        end, 0.5)
    end)
    performWithDelay(self, function()
        util_setCascadeOpacityEnabledRescursion(self.m_eggNode:findChild("Node_guang"), true)
        util_setCascadeColorEnabledRescursion(self.m_eggNode:findChild("Node_guang"), true)
        self.m_eggGuangNode:setVisible(true)
        self.m_eggGuangNode:runCsbAction("idle2", true)
    end, 45/60)
end

--[[
    蛋 触发之后 恢复
]]
function StarryAnniversaryProgressBarView:playEggsIdleEffect( )
    self.m_eggNode:runCsbAction("idle", true)
    self.m_eggGuangNode:setVisible(false)
end

return StarryAnniversaryProgressBarView
