-- 卡牌商店 玩法介绍界面

local BaseActivityHelpUI = util_require("baseActivity.BaseActivityHelpUI")
local CardStoreBlindHelpLayer = class("CardStoreBlindHelpLayer", BaseActivityHelpUI)

function CardStoreBlindHelpLayer:initUI(closeCallBack)
    BaseActivityHelpUI.initUI(self, closeCallBack)
    util_portraitAdaptLandscape(self.m_csbNode)
    self:setExtendData("CardStoreBlindHelpLayer")
end

function CardStoreBlindHelpLayer:getCsbName()
    local p_config = G_GetMgr(G_REF.CardStore):getConfig()
    return p_config.BlindInfoUI
end

function CardStoreBlindHelpLayer:getHelpItemLuaName()
    return "GameModule.Card.CardStore.views.CardStoreBlindHelpItem"
end

function CardStoreBlindHelpLayer:getPageCount()
    return 3
end

function CardStoreBlindHelpLayer:clickFunc(sender)
    BaseActivityHelpUI.clickFunc(self, sender)
    if not self.btnDisableFlag then
        local senderName = sender:getName()
        if senderName == "btn_close" then
            self:close()
        end
    end
end

return CardStoreBlindHelpLayer
