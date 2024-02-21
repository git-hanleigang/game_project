local GamePusherShowView = class("GamePusherShowView", util_require("Levels.BaseLevelDialog"))
local ShopItem = util_require("data.baseDatas.ShopItem")
local ActivityTaskManager = util_require("manager.ActivityTaskManager")
local Config = require("CandyPusherSrc.GamePusherMain.GamePusherConfig")

function GamePusherShowView:initUI(path)
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 or globalData.slotRunData.isPortrait == true then
        isAutoScale = false
    end
    self:createCsbNode(path.Path, isAutoScale)
    util_setCascadeOpacityEnabledRescursion(self, true)
    self:setExtendData("GamePusherShowView")
    self._Type = path.Type

    self:commonShow(
        self:findChild("root"),
        function()
            self._TouchEnabled = true
            self:runCsbAction("idle", true, nil, 30)

            if CoinPusherMgr:checkAutoDrop() then
                self:didClose()
            end
        end
    )
end

function GamePusherShowView:clickFunc(sender)
    if self._TouchEnabled == false then
        return
    end
    local btnName = sender:getName()
    gLobalSoundManager:playSound("Sounds/btn_click.mp3")

    if btnName == "btn_close" or btnName == "btn_collect" then
        -- 屏蔽点击
        self._TouchEnabled = false
        self:didClose()
    end
end

function GamePusherShowView:closeUI()
    self._TouchEnabled = false
    self:commonHide(
        self:findChild("root"),
        function()
        end
    )
end

-- 执行关闭逻辑
function GamePusherShowView:didClose()
    gLobalNoticManager:postNotification(Config.Event.GamePusherEffectEnd, self._Type)
    gLobalNoticManager:removeAllObservers(self)
    self:removeFromParent()
end



function GamePusherShowView:onExit()
    GamePusherShowView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

return GamePusherShowView