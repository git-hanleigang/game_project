---
--island
--2018年4月12日
--FiveDragonLowerBetDialog.lua
--
-- FiveDragonLowerBetDialog top bar

local FiveDragonLowerBetDialog = class("FiveDragonLowerBetDialog", util_require("base.BaseView"))
FiveDragonLowerBetDialog.m_canTouch = nil
-- 构造函数
function FiveDragonLowerBetDialog:initUI(machine, showTip)
    self.m_machine = machine
    self.m_showTip = showTip
    local resourceFilename="FiveDragon_lower_betchoose.csb"
    self:createCsbNode(resourceFilename)
    self.m_canTouch = true
end

function FiveDragonLowerBetDialog:onEnter()
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
    end)
end

function FiveDragonLowerBetDialog:onExit()
    
end

function FiveDragonLowerBetDialog:clickFunc(sender)
    if self.m_canTouch == false then
        return
    end
    self.m_canTouch = false
    local name = sender:getName()
    local tag = sender:getTag()
    self:closeUI(name)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
end

function FiveDragonLowerBetDialog:closeUI(btnName)
    local func = nil
    local extra = {}
    extra.actionType = 5
    if self.m_showTip == true then
        extra.betRemindSite = "ToGamePush"
    else
        extra.betRemindSite = "GameTap"
    end
    if btnName == "nudgeBtn" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)
        extra.betType = "NudgeMode"
    else
        func = function()
            if self.m_showTip == true then
                self.m_machine:showLowerBetIcon()
            end
        end
        extra.betType = "RegularMode"
    end
    extra.betNum = globalData.slotRunData:getCurTotalBet()
    self:runCsbAction("over", false, function()
        if func ~= nil then
            func()
        end
        if self.m_showTip == true then
            -- self.m_machine:showLowerBetTip()
        end
        self:removeFromParent(true)
    end)
end

function FiveDragonLowerBetDialog:onKeyBack()
    self:closeUI("regularBtn")
end

return FiveDragonLowerBetDialog