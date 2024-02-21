--[[
    -- link卡集齐面板
    author:{author}
    time:2019-10-16 11:30:52
]]
local BaseCardComplete = util_require("GameModule.Card.baseViews.BaseCardComplete")
local CardLinkComplete = class("CardLinkComplete", BaseCardComplete)
function CardLinkComplete:initUI(params)
    BaseCardComplete.initUI(self, params)
    self:updateUI()
end

function CardLinkComplete:clickFunc(sender)
    BaseCardComplete.clickFunc(self, sender)

    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_collect" then
        if self.m_clickCollect then
            return
        end
        self.m_clickCollect = true
        CardSysManager:closeCardCollectComplete()
    end
end

function CardLinkComplete:playHideAction()
    gLobalSoundManager:playSound("Sounds/soundHideView.mp3")
    CardLinkComplete.super.playHideAction(self, "over")
end

function CardLinkComplete:updateUI()
    self:setClickState()
    self:updateLinkComplete()
end

function CardLinkComplete:updateLinkComplete()
    -- 数据处理
    -- UI处理
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CompletelinkAllDone)
    local root = self:findChild("tanban5")
    self:runCsbAction(
        "start_1",
        false,
        function()
            self:runCsbAction("idle", true, nil, 60)
        end,
        60
    )
end

return CardLinkComplete
