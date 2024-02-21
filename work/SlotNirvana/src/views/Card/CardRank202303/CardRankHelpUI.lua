-- 集卡排行榜 玩法简介
local CardRankConfig = require("views.Card.CardRank202303.CardRankConfig")

local CardRankHelpUI = class("CardRankHelpUI", BaseLayer)

function CardRankHelpUI:ctor()
    CardRankHelpUI.super.ctor(self)

    self:setLandscapeCsbName(CardRankConfig.RankHelpUI)
    self:setExtendData("CardRankHelpUI")
    self:addClickSound({"btnPre", "btnNext"}, SOUND_ENUM.MUSIC_BTN_CLICK)
end

function CardRankHelpUI:initView()
    self.node_page = self:findChild("node_page")
    self.btnPre = self:findChild("btnPre")
    self.btnNext = self:findChild("btnNext")

    local page1 = util_createView("views.Card.CardRank202303.CardRankHelpItemUI", 1)
    if not tolua.isnull(page1) then
        page1:addTo(self.node_page)
        self.page1 = page1
    end
    local page2 = util_createView("views.Card.CardRank202303.CardRankHelpItemUI", 2)
    if not tolua.isnull(page2) then
        page2:addTo(self.node_page)
        self.page2 = page2
    end

    self:onSelect(1)
end

function CardRankHelpUI:onSelect(idx)
    self.page1:setVisible(idx == 1)
    self.page2:setVisible(idx == 2)
    self.btnPre:setVisible(idx == 2)
    self.btnNext:setVisible(idx == 1)
end

function CardRankHelpUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btnPre" then
        self:onSelect(1)
    elseif name == "btnNext" then
        self:onSelect(2)
    end
end

function CardRankHelpUI:closeUI()
    if self.closed then
        return
    end
    self.closed = true
    self.page1:hideParticle()
    CardRankHelpUI.super.closeUI(self)
end

function CardRankHelpUI:onEnter()
    CardRankHelpUI.super.onEnter(self)
    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == G_REF.CardRank then
                if not tolua.isnull(self) then
                    self:closeUI()
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

return CardRankHelpUI
