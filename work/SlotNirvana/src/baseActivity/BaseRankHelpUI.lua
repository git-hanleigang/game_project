--[[
    author:JohnnyFred
    time:2019-12-16 18:12:21
]]
local BaseRankHelpUI = class("BaseRankHelpUI", util_require("base.BaseView"))

function BaseRankHelpUI:onEnter()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
end

function BaseRankHelpUI:onExit()
    if gLobalViewManager:isPauseAndResumeMachine(self) then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
    end
end

function BaseRankHelpUI:clickFunc(sender)
    if not self.btnDisableFlag then
        local name = sender:getName()
        -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if name == "btn_gotit" or name == "btn_x" or name == "btn_close" or name == "btn_rankinfo" then
            sender:setTouchEnabled(false)
            self:close()
        end
    end
end

function BaseRankHelpUI:setButtonDisableFlag(flag)
    self.btnDisableFlag = flag
end

function BaseRankHelpUI:close()
    if not self.btnDisableFlag then
        self:setButtonDisableFlag(true)
        self:commonHide(
            self:findChild("root"),
            function()
                self:removeFromParent()
            end
        )
    end
end

------------------------------------------子类重写---------------------------------------
function BaseRankHelpUI:initUI()
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 or globalData.slotRunData.isPortrait == true then
        isAutoScale = false
    end

    self:createCsbNode(self:getCsbName(), isAutoScale)

    self:commonShow(
        self:findChild("root"),
        function()
            self:setButtonDisableFlag(false)
            self:runCsbAction("idle", true)
        end
    )
    self:setButtonDisableFlag(true)
    self:startLeftTimer()

    self:addClickSound({"btn_gotit", "btn_x", "btn_close", "btn_rankinfo"}, SOUND_ENUM.MUSIC_BTN_CLICK)
end

function BaseRankHelpUI:startLeftTimer()
    local gameData = self:getGameData()
    if not gameData or gameData == "" then
        return
    end

    self:stopLeftTimerAction()
    local function update()
        local gameData = self:getGameData()
        if not gameData or not gameData:isRunning() then
            self:stopLeftTimerAction()
            self:close()
        end
    end
    self.leftTimerAction = schedule(self, update, 1)
    update()
end

function BaseRankHelpUI:stopLeftTimerAction()
    if self.leftTimerAction ~= nil then
        self:stopAction(self.leftTimerAction)
        self.leftTimerAction = nil
    end
end

function BaseRankHelpUI:getCsbName()
    return ""
end

function BaseRankHelpUI:getGameData()
    return ""
end
------------------------------------------子类重写---------------------------------------
return BaseRankHelpUI
