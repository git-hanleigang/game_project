--[[
]]
-- 玩法介绍

local CSInfoLayer = class("CSInfoLayer", BaseLayer)

function CSInfoLayer:ctor()
    CSInfoLayer.super.ctor(self)
    self:setLandscapeCsbName(CardSeekerCfg.csbPath .. "Seeker_RuleLayer.csb")
end

function CSInfoLayer:initDatas()
    self.m_curPageIndex = 1
end

function CSInfoLayer:initUI()
    CSInfoLayer.super.initUI(self)
    self:setExtendData("CSInfoLayer")
end

function CSInfoLayer:initCsbNodes()
    self.m_panelLeft = self:findChild("btn_left")
    self.m_panelRight = self:findChild("btn_right")

    self.m_nodePages = {}
    for i = 1, math.huge do
        local pageNode = self:findChild("node_rule_" .. i)
        if not pageNode then
            break
        end
        table.insert(self.m_nodePages, pageNode)
    end
    self.m_pageCount = #self.m_nodePages
end

function CSInfoLayer:initView()
    self:updatePageNode()
end

function CSInfoLayer:updatePageNode()
    self.m_panelLeft:setVisible(self.m_curPageIndex > 1)
    self.m_panelRight:setVisible(self.m_curPageIndex < self.m_pageCount)

    for i = 1, self.m_pageCount do
        self.m_nodePages[i]:setVisible(i == self.m_curPageIndex)
    end
end

function CSInfoLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function CSInfoLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_left" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_curPageIndex == 1 then
            return
        end
        self.m_curPageIndex = self.m_curPageIndex - 1
        self:updatePageNode()
    elseif name == "btn_right" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_curPageIndex == self.m_pageCount then
            return
        end
        self.m_curPageIndex = self.m_curPageIndex + 1
        self:updatePageNode()
    end
end

return CSInfoLayer
