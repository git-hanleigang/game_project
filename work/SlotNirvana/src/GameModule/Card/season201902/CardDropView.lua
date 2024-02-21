--[[
    集卡系统 卡片卡组掉落界面
]]
local BaseCardDropView = util_require("GameModule.Card.baseViews.BaseCardDropView")
local CardDropView = class("CardDropView", BaseCardDropView)

function CardDropView:initDatas(dropData)
    CardDropView.super.initDatas(self, dropData)
    self:setLandscapeCsbName(CardResConfig.seasonRes.CardDropView201902Res)
end

function CardDropView:createShowList()
    local dropListUI = util_createView("GameModule.Card.season201902.CardDropShow", self.m_list_card)
    return dropListUI
end

-- 显示背景光
function CardDropView:showBgLight(isShow)
    -- 可以直接显示背景光 --
    if isShow then
        self.m_bgLigt:setVisible(true)
        local selectNode, selectAct = util_csbCreate(CardResConfig.seasonRes.CardDropLight201902Res)
        self.m_bgLigt:addChild(selectNode)
        util_csbPlayForKey(
            selectAct,
            "start",
            false,
            function()
                util_csbPlayForKey(selectAct, "idle", true)
            end,
            30
        )
    else
        local callF = function()
            self.m_bgLigt:setVisible(false)
        end
        local opa = cc.FadeOut:create(0.7)
        local callFunc = cc.CallFunc:create(callF)
        local seq = cc.Sequence:create(opa, callFunc)
        self.m_bgLigt:runAction(seq)
    end
end
return CardDropView
