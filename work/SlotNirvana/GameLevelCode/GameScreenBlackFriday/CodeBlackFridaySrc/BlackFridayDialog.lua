---
--xcyy
--2018年5月23日
--FruitFarmView.lua

local BlackFridayDialog = class("BlackFridayDialog",util_require("Levels.BaseDialog"))

BlackFridayDialog.m_tanbanOverSound = nil

--开始弹框
function BlackFridayDialog:openDialog()
    if self.m_autoType and self.m_autoType == BlackFridayDialog.AUTO_TYPE_ONLY then
        --弹出自动弹版
        self:showAuto()
    else
        --正常弹出开始弹版
        self.m_allowClick = false
        self:showStart()
    end
end

--开始ccb中配置 暂时屏蔽
function BlackFridayDialog:showStart()
    self.m_status = self.STATUS_START
    self:runCsbAction(self.m_start_name)
    local time = self:getAnimTime(self.m_start_name)
    if not time or time <= 0 then
        time = self.m_startTime
    end

    performWithDelay(
        self,
        function()
            self.m_allowClick = true
            self:showidle()
        end,
        time
    )
end

function BlackFridayDialog:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    local name
    if sender then
        name = sender:getName()
    end
    gLobalSoundManager:playSound(self.m_btnTouchSound)
    if self.m_tanbanOverSound then
        gLobalSoundManager:playSound(self.m_tanbanOverSound)
    end

    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if sender and sender.setTouchEnabled then
        sender:setTouchEnabled(false)
    end
    if self.m_status == self.STATUS_START or self.m_status == self.STATUS_IDLE or self.m_status == self.STATUS_AUTO then
        self:showOver(name)
    end
end

return BlackFridayDialog