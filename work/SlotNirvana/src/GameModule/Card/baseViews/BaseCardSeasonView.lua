--[[
    集卡系统 赛季选择画面的base类
--]]
local BaseCardSeasonView = class("BaseCardSeasonView", util_require("base.BaseView"))

-- 初始化UI --
function BaseCardSeasonView:initUI()
end

function BaseCardSeasonView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_quit" or name == "Button_back" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        CardSysManager:closeCardSeasonView(
            function()
                CardSysManager:exitCard()
            end
        )
    end
end

-- 关闭事件 --
function BaseCardSeasonView:closeUI(exitFunc)
    if self.isClose then
        return
    end
    self.isClose = true
    performWithDelay(
        self,
        function()
            if exitFunc then
                exitFunc()
            end
            self:removeFromParent()
        end,
        0.5
    )
end

return BaseCardSeasonView
