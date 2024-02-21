--[[
    特殊卡册-购物主题 说明
]]
local ObsidianCardInfoUI = class("ObsidianCardInfoUI", BaseLayer)

function ObsidianCardInfoUI:initDatas()
    self.m_curPageIndex = 1
    self:setLandscapeCsbName("CardRes/CardObsidian_6/csb/info/ObsidianChip_Rules.csb")
end

function ObsidianCardInfoUI:onEnter()
    ObsidianCardInfoUI.super.onEnter(self)
    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == G_REF.ObsidianCard then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function ObsidianCardInfoUI:initCsbNodes()
    self.m_btnClose = self:findChild("btn_close")
    self.m_btnLeft = self:findChild("btn_left")
    self.m_btnRight = self:findChild("btn_right")

    self.m_nodePages = {}
    for i = 1, math.huge do
        local pageNode = self:findChild("node_rules_" .. i)
        if not pageNode then
            break
        end
        table.insert(self.m_nodePages, pageNode)
    end
    self.m_pageCount = #self.m_nodePages
end

function ObsidianCardInfoUI:getData()
    return G_GetMgr(ACTIVITY_REF.Redecor):getData()
end

function ObsidianCardInfoUI:initView()
    self:updatePageNode()
end

function ObsidianCardInfoUI:updatePageNode()
    self.m_btnLeft:setVisible(self.m_curPageIndex > 1)
    self.m_btnRight:setVisible(self.m_curPageIndex < self.m_pageCount)
    for i = 1, #self.m_nodePages do
        self.m_nodePages[i]:setVisible(i == self.m_curPageIndex)
    end
    self:runCsbAction("idle" .. self.m_curPageIndex, true, nil, 60)
end

function ObsidianCardInfoUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_left" then
        if self.m_curPageIndex == 1 then
            return
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_curPageIndex = self.m_curPageIndex - 1
        self:updatePageNode()
    elseif name == "btn_right" then
        if self.m_curPageIndex == self.m_pageCount then
            return
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_curPageIndex = self.m_curPageIndex + 1
        self:updatePageNode()
    end
end

function ObsidianCardInfoUI:onShowedCallFunc()
    self:runCsbAction("idle" .. self.m_curPageIndex, true, nil, 60)
end

return ObsidianCardInfoUI
