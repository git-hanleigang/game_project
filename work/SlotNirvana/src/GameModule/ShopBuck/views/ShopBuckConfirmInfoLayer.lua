--[[
]]
local ShopBuckConfirmInfoLayer = class("ShopBuckConfirmInfoLayer", BaseLayer)

function ShopBuckConfirmInfoLayer:initDatas()

    -- self.m_pageIndex = 1

    self:setLandscapeCsbName("ShopBuck/csb/info/ShopBuckInfo2Layer.csb")
    self:setPortraitCsbName("ShopBuck/csb/info/ShopBuckInfo2Layer_V.csb")
end

-- function ShopBuckConfirmInfoLayer:initCsbNodes()
--     self.m_nodePagePoint = self:findChild("node_pagePoint")
--     self.m_btnLeft = self:findChild("btn_left")
--     self.m_btnRight = self:findChild("btn_right")
--     self.m_nodeRules = {}
--     for i = 1, math.huge do
--         local rule = self:findChild("node_info_" .. i)
--         if not rule then
--             break
--         end
--         table.insert(self.m_nodeRules, rule)
--     end
--     self.m_pageNum = #self.m_nodeRules    
-- end

-- function ShopBuckConfirmInfoLayer:initView()
--     self:initPoints()
--     self:updatePoints()
--     self:updatePage()
--     self:updateBtns()
-- end

-- function ShopBuckConfirmInfoLayer:initPoints()
--     local UIList = {}
--     self.m_points = {}
--     for i=1,self.m_pageNum do
--         local point = util_createAnimation("ShopBuck/csb/info/ShopBuckInfo_Point.csb")
--         self.m_nodePagePoint:addChild(point)
--         table.insert(self.m_points, point)
--         table.insert(UIList, {node = point, scale = 1, size = cc.size(40, 40), anchor = cc.p(0.5, 0.5)})
--     end
--     util_alignCenter(UIList)
-- end

-- function ShopBuckConfirmInfoLayer:updatePoints()
--     for i = 1, #self.m_points do
--         local point = self.m_points[i]
--         local spSel = point:findChild("sp_select")
--         if spSel then
--             spSel:setVisible(i == self.m_pageIndex)
--         end
--     end
-- end

-- function ShopBuckConfirmInfoLayer:updateBtns()
--     self.m_btnLeft:setVisible(self.m_pageIndex > 1)
--     self.m_btnRight:setVisible(self.m_pageIndex < self.m_pageNum)
-- end

-- function ShopBuckConfirmInfoLayer:updatePage()
--     for i = 1, #self.m_nodeRules do
--         self.m_nodeRules[i]:setVisible(i == self.m_pageIndex)
--     end
-- end

-- function ShopBuckConfirmInfoLayer:playShowAction()
--     ShopBuckConfirmInfoLayer.super.playShowAction(self)
-- end

function ShopBuckConfirmInfoLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function ShopBuckConfirmInfoLayer:onEnter()
    ShopBuckConfirmInfoLayer.super.onEnter(self)
end

function ShopBuckConfirmInfoLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_left" then
        -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        -- self.m_pageIndex = math.max(self.m_pageIndex - 1, 1)
        -- self:updatePage()
        -- self:updateBtns()
        -- self:updatePoints()
    elseif name == "btn_right" then
        -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        -- self.m_pageIndex = math.min(self.m_pageIndex + 1, self.m_pageNum)
        -- self:updatePage()
        -- self:updateBtns()
        -- self:updatePoints()
    elseif name == "btn_close" then
        self:closeUI()
    end
end

return ShopBuckConfirmInfoLayer