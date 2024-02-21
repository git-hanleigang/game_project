--[[
    author:{author}
    time:2019-07-24 15:10:06
]]
local CardRecoverRule = class("CardRecoverRule", BaseLayer)

function CardRecoverRule:initDatas()
    self.m_pageIndex = 1
    self:setLandscapeCsbName(string.format(CardResConfig.commonRes.CardRecoverRuleRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
end

function CardRecoverRule:initCsbNodes()
    self.m_btnBack = self:findChild("Button_5")
    self.m_btnLeft = self:findChild("btn_fanye_left")
    self.m_btnRight = self:findChild("btn_fanye_right")
    self.m_nodeRules = {}
    for i = 1, math.huge do
        local ruleNode = self:findChild("node_rules_" .. i)
        if not ruleNode then
            break
        end
        self.m_nodeRules[#self.m_nodeRules + 1] = ruleNode
    end
    self.m_pageNum = #self.m_nodeRules
end

function CardRecoverRule:initView()
    self:updatePageNodes()
end

function CardRecoverRule:updatePageNodes()
    for i = 1, self.m_pageNum do
        local ruleNode = self.m_nodeRules[i]
        ruleNode:setVisible(i == self.m_pageIndex)
    end
    self.m_btnLeft:setVisible(self.m_pageIndex > 1)
    self.m_btnRight:setVisible(self.m_pageIndex < self.m_pageNum)
end

function CardRecoverRule:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function CardRecoverRule:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_5" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        CardSysManager:closeCardRecoverRule()
    elseif name == "btn_fanye_left" then
        if self.m_pageIndex <= 1 then
            return
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_pageIndex = self.m_pageIndex - 1
        self:updatePageNodes()
    elseif name == "btn_fanye_right" then
        if self.m_pageIndex >= self.m_pageNum then
            return
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_pageIndex = self.m_pageIndex + 1
        self:updatePageNodes()
    end
end

function CardRecoverRule:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true
    CardRecoverRule.super.closeUI(self)
end

function CardRecoverRule:onEnter()
    CardRecoverRule.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- 新赛季开启的时候退出集卡所有界面
            CardSysManager:getRecoverMgr():closeCardRecoverRule()
        end,
        ViewEventType.CARD_ONLINE_ALBUM_OVER
    )
end

return CardRecoverRule
