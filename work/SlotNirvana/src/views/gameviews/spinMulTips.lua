local spinMulTips = class("spinMulTips", util_require("base.BaseView"))
spinMulTips.m_isAction = nil
function spinMulTips:initUI()
    self:createCsbNode("Game/tishi.csb")
    self:setVisible(false)
    self:setPos()
    self.m_basePath = "Game/ui/beishu.png"
end
function spinMulTips:showUp(mul)
    self.m_isAction = true
    local m_lb_mul = self:findChild("m_lb_mul")
    m_lb_mul:setString("X" .. mul)
    self:setVisible(true)
    gLobalActivityManager:changeBubbleGZorder(self:getParent(), 1)
    local node_level = self:findChild("node_level")
    local sp_normal = self:findChild("sp_normal")
    node_level:setVisible(true)
    sp_normal:setVisible(false)
    self:runCsbAction("show")
    performWithDelay(
        self,
        function()
            if not tolua.isnull(self) then
                self:hide()
            end
        end,
        5
    )
end
function spinMulTips:show()
    if self.m_isAction then
        return
    end
    self.m_isAction = true
    self:setVisible(true)
    gLobalActivityManager:changeBubbleGZorder(self:getParent(), 1)
    local node_level = self:findChild("node_level")
    local sp_normal = self:findChild("sp_normal")
    node_level:setVisible(false)
    self:refreshSpNormal()
    sp_normal:setVisible(true)
    self:runCsbAction("show")
    gLobalViewManager:addAutoCloseTips(
        self,
        function()
            if not tolua.isnull(self) then
                self:hide()
            end
        end
    )
end
function spinMulTips:hide()
    if self.isHide then
        return
    end
    self.isHide = true
    self:runCsbAction(
        "over",
        false,
        function()
            self.m_isAction = false
            self.isHide = false
            self:setVisible(false)
            gLobalActivityManager:changeBubbleGZorder(self:getParent(), 0)
        end
    )
end

function spinMulTips:onKeyBack()
end

function spinMulTips:initCsbNodes()
    self.m_sp_bg = self:findChild("Image_1")
    self.m_sp_arrow = self:findChild("Image_2")
end

function spinMulTips:setPos()
    if globalData.slotRunData.isPortrait == true then
        self.m_sp_bg:setAnchorPoint(0.15, 1)
        self.m_sp_bg:setPositionX(self.m_sp_bg:getPositionX() + 15)
        self.m_sp_arrow:setPositionX(self.m_sp_arrow:getPositionX() - 285)
    end
end

-- 刷新sp_normal的纹理
function spinMulTips:refreshSpNormal()
    local sp_normal = self:findChild("sp_normal")
    if sp_normal then
        local basePath = "Game/ui/beishu.png"
        local monthlyCardMgr = G_GetMgr(G_REF.MonthlyCard)
        if monthlyCardMgr then
            local data = monthlyCardMgr:getRunningData()
            if data and data:isBuyMonthlyCardDeluxe() then
                basePath = "Game/ui/beishu2.png"
            end
        end
        if self.m_basePath ~= basePath then
            util_changeTexture(sp_normal, basePath)
            self.m_basePath = basePath
        end
    end
end

return spinMulTips
