--[[
]]
local CFG_TXT = {
    {
        "Earn more coins\r\nfor the same price.",
        "Earn more points\r\nwith every Purchase.",
        "Earn more coins\r\nin Store Gifts.",
        "Earn larger\r\nGold Vault\r\nwith vip status.",
        "Earn larger\r\nSilver Vault\r\nwith vip status."
    },
    {
        "Earn larger\r\nCash Wheel\r\nwith vip status.",
        "Earn more coins\r\nfrom Fanpage.",
        "Earn more coins\r\nfrom Notification.",
        "Collect VIP exclusive\r\ncoupon on your first\r\nweekly login from inbox\r\nonce a week.",
        "Collect weekly gifts on\r\nyour first weekly login\r\nfrom inbox once a week."
    }
}
local BG_OFFSET_WIDTH = 30
local BG_OFFSET_HEIGHT = 30
local BG_HEIGHT_MIN = 150
local CellBubble = class("CellBubble", BaseView)

function CellBubble:getCsbName()
    return "VipNew/csd/rewardUI/CellBubble.csb"
end

function CellBubble:initDatas(_pageIndex, _index)
    self.m_pageIndex = _pageIndex
    self.m_index = _index
end

function CellBubble:initCsbNodes()
    self.m_nodeTxt = self:findChild("node_txt")
    self.m_imgBg = self:findChild("img_bg")
    self.m_lbStr = self:findChild("lb_str")
end

function CellBubble:initUI()
    CellBubble.super.initUI(self)
    if globalData.slotRunData.isPortrait then
        util_adaptPortrait(self.m_csbNode)
    end
    self:updateStr()
end

function CellBubble:updateUI(_pageIndex)
    self.m_pageIndex = _pageIndex
    self:updateStr()
end

function CellBubble:updateStr()
    local str = CFG_TXT[self.m_pageIndex][self.m_index]
    self.m_lbStr:setString(str)
    local lbSize = self.m_lbStr:getContentSize()

    local bgWidth = lbSize.width + BG_OFFSET_WIDTH
    local bgHeight = lbSize.height + BG_OFFSET_HEIGHT
    bgHeight = math.max(bgHeight, BG_HEIGHT_MIN)

    self.m_imgBg:setContentSize(cc.size(bgWidth, bgHeight))

    -- if self.m_index == VipConfig.CellNum then
    --     self.m_nodeTxt:setPositionY((bgHeight - BG_OFFSET_HEIGHT) / 2)
    -- else
    --     self.m_nodeTxt:setPositionY(0)
    -- end
end

function CellBubble:playShow(_over)
    self:runCsbAction(
        "show",
        false,
        function()
            if _over then
                _over()
            end
            self:runCsbAction("idle", true, nil, 60)
        end,
        60
    )
end

function CellBubble:playOver()
    self:runCsbAction(
        "over",
        false,
        function()
            if _over then
                _over()
            end
        end,
        60
    )
end

return CellBubble
