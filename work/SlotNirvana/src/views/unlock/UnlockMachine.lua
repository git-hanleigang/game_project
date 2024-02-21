--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-08-31 18:54:02
--
local UnlockMachine = class("UnlockMachine", BaseView)
UnlockMachine.m_isPlayClose = nil -- 是否play 下一关 的关闭

function UnlockMachine:initUI(data)
    local unlockMachineName = data[1]
    self.m_unlockMachineName = unlockMachineName
    self.m_index = data[2]
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self:createCsbNode("Unlock/UnlockLayer.csb", isAutoScale)
    performWithDelay(
        self,
        function()
            self:runCsbAction(
                "show",
                false,
                function()
                    self:removeFromParent()
                end,
                60
            )
        end,
        1
    )
    if globalData.slotRunData.isPortrait then
        local bangHeight = util_getBangScreenHeight()
        self:setPosition(display.width - 450, display.height - 170 - bangHeight)
    else
        self:setPosition(display.width - 450, display.height - 170)
    end
    if unlockMachineName == nil then
        return
    end
    local unlockIcon = self:findChild("tubiao_0")
    local path = globalData.GameConfig:getLevelIconPath(unlockMachineName, LEVEL_ICON_TYPE.SMALL)
    local bLoad = util_changeTexture(unlockIcon, path)
    --重置UIImage size
    if bLoad then
        unlockIcon:ignoreContentAdaptWithSize(true)
    end
end

-- function UnlockMachine:onExit( )
--       -- 通知完成
--     --   if self.m_isPlayClose == false then
--     --         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE
--     --               ,GameEffect.EFFECT_Unlock)
--     --   end
-- end

--desc:
--Author:{author}
--date:2018-08-31 18:54:02
function UnlockMachine:clickFunc(sender)
    gLobalSoundManager:playSound("Sounds/btn_click.mp3")
    local name = sender:getName()
    if name == "btn_play" then
        self.m_isPlayClose = true

        globalData.unlockMachineName = self.m_unlockMachineName
        release_print("UnlockMachine back to lobby!!!")
        gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
    elseif name == "btn_close" or name == "btn_back" then
        self.m_isPlayClose = false
        self:runCsbAction(
            "unlock_over",
            false,
            function()
                self:removeFromParent()
            end,
            60
        )
    end
end

return UnlockMachine
