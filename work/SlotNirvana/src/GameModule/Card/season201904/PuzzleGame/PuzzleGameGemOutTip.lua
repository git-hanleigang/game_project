--[[
    红钻石不足提示
    author:{author}
    time:2020-09-04 15:53:33
]]
local BaseView = util_require("base.BaseView")
local PuzzleGameGemOutTip = class("PuzzleGameGemOutTip", BaseView)
function PuzzleGameGemOutTip:initUI()
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end    
    self:createCsbNode(CardResConfig.PuzzleGemOutRes, isAutoScale)

    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", false)
    end)
end

function PuzzleGameGemOutTip:onEnter()
end

function PuzzleGameGemOutTip:canClick()
    if self.m_closed then
        return false
    end
    return true
end

function PuzzleGameGemOutTip:clickFunc(sender)
    local name = sender:getName()
    if not self:canClick() then
        return
    end
    if name == "btn_buyMore" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)

        gLobalSendDataManager:getLogIap():setEntryName("btn_buyMore")

        -- 进入商城
        local view = G_GetMgr(G_REF.Shop):showMainLayer()
        view.buyShop = true

        gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_PUZZLE_GAME_JUMP_TO_SHOP)
        -- 退出卡牌系统
        -- CardSysManager:exitCard()
        -- 发送进入商店事件
        self:closeUI()
    elseif name == "btn_close" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        self:closeUI()
    end
end

function PuzzleGameGemOutTip:closeUI()

    if self.m_closed then
        return
    end
    self.m_closed = true

    self:runCsbAction(
        "over",
        false,
        function()
            self:removeFromParent()
        end
    )
end

return PuzzleGameGemOutTip
