--[[
    Spin推送关卡
    author:{author}
    time:2023-10-16 09:12:04
]]
local SpinPushGameNode = class("SpinPushGameNode", BaseView)

function SpinPushGameNode:initDatas()
end

function SpinPushGameNode:initUI()
    -- local unlockMachineName = data[1]
    -- self.m_unlockMachineName = unlockMachineName
    -- self.m_index = data[2]
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self:createCsbNode("Unlock/RecommendLevelLayer.csb", isAutoScale)

    if globalData.slotRunData.isPortrait then
        local bangHeight = util_getBangScreenHeight()
        self:setPosition(display.width - 360, display.height - 170 - bangHeight)
    else
        self:setPosition(display.width - 360, display.height - 170)
    end
    -- if unlockMachineName == nil then
    --     return
    -- end
end

function SpinPushGameNode:updateView(slotInfo)
    self.m_levelInfo = slotInfo
    local unlockIcon = self:findChild("tubiao_0")
    local path = globalData.GameConfig:getLevelIconPath(slotInfo.p_levelName, LEVEL_ICON_TYPE.SMALL)
    local bLoad = util_changeTexture(unlockIcon, path)
    --重置UIImage size
    if bLoad then
        unlockIcon:ignoreContentAdaptWithSize(true)
    end
end

function SpinPushGameNode:onEnter()
    SpinPushGameNode.super.onEnter(self)
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
end

function SpinPushGameNode:clickFunc(sender)
    gLobalSoundManager:playSound("Sounds/btn_click.mp3")
    local name = sender:getName()
    if name == "btn_play" then
        self.m_isPlayClose = true

        gLobalViewManager:gotoSlotsScene(self.m_levelInfo)
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

return SpinPushGameNode
