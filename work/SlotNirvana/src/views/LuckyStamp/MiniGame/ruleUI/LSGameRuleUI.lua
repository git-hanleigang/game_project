--[[--
    小游戏 奖励界面
]]
local LSGameRuleUI = class("LSGameRuleUI", BaseLayer)

function LSGameRuleUI:initDatas()
    LSGameRuleUI.super.initDatas(self)
    self:setLandscapeCsbName(LuckyStampCfg.csbPath .. "ruleUI/NewLuckyStamp_Rule.csb")
    self.m_pageIndex = 1
end

function LSGameRuleUI:initCsbNodes()
    self.m_btnLeft = self:findChild("btn_left")
    self.m_btnRight = self:findChild("btn_right")
    self.m_nodeRules = {}
    for i = 1, math.huge do
        local rule = self:findChild("node_rule" .. i)
        if not rule then
            break
        end
        table.insert(self.m_nodeRules, rule)
    end
    self.m_pageNum = #self.m_nodeRules
end

function LSGameRuleUI:initView()
    self:updatePage()
    self:updateBtns()
end

function LSGameRuleUI:updateBtns()
    self.m_btnLeft:setVisible(self.m_pageIndex > 1)
    self.m_btnRight:setVisible(self.m_pageIndex < self.m_pageNum)
end

function LSGameRuleUI:updatePage()
    for i = 1, #self.m_nodeRules do
        self.m_nodeRules[i]:setVisible(i == self.m_pageIndex)
    end
end

function LSGameRuleUI:onShowedCallFunc()
end

function LSGameRuleUI:onEnter()
    LSGameRuleUI.super.onEnter(self)
end

function LSGameRuleUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_left" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_pageIndex = math.max(self.m_pageIndex - 1, 1)
        self:updatePage()
        self:updateBtns()
    elseif name == "btn_right" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_pageIndex = math.min(self.m_pageIndex + 1, self.m_pageNum)
        self:updatePage()
        self:updateBtns()
    elseif name == "btn_close" then
        self:closeUI()
    end
end

return LSGameRuleUI
