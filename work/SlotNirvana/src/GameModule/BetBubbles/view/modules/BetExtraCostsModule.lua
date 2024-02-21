--[[
]]
local OFFSET_H = 10

local BetExtraCostsModule = class("BetExtraCostsModule", BaseView)

function BetExtraCostsModule:initDatas(_refDatas)
    self.m_refDatas = _refDatas
    
    -- self.m_GameBetLua = "BetExtraBubbleCode/GameBetExtraNode"
    -- self.m_gameBetH = self:getViewHeight(self.m_GameBetLua)
    -- self.m_refHeights = self:getRefHeights()
    -- self.m_labelH = self:getLabelH()
end

-- function BetExtraCostsModule:getViewHeight(_filePath)
--     local height = 0
--     local view = self:createView(_filePath)
--     if view and view.getLabelSize then
--         local size = view:getLabelSize()
--         height = size.height or 0
--     end
--     return height
-- end

function BetExtraCostsModule:getViewH(_view)
    local viewH = 0
    if not tolua.isnull(_view) and _view.getLabelSize then
        local vSize = _view:getLabelSize()
        viewH = vSize.height
    end
    return viewH
end

function BetExtraCostsModule:getCsbName()
    return "BetExtraBubble/csd/BetExtraMain.csb"
end

function BetExtraCostsModule:initCsbNodes()
    self.m_nodeBubbles = self:findChild("node_bubbles")
end

function BetExtraCostsModule:getLabelSize()
    local totalH = 0
    if self.m_views and #self.m_views > 0 then
        for i=1,#self.m_views do
            totalH = totalH + self.m_views[i].viewH
        end
    end
    return cc.size(BetBubblesCfg.BG_W, totalH + OFFSET_H)
end

-- function BetExtraCostsModule:getLabelH()
--     local height = 0
--     local refsH = self:getRefsH()
--     if refsH > 0 then
--         height = height + self.m_gameBetH
--         height = height + refsH
--     end
--     return height 
-- end

-- function BetExtraCostsModule:getRefsH()
--     local height = 0
--     if self.m_refHeights and #self.m_refHeights > 0 then
--         for i=1,#self.m_refHeights do
--             height = height + self.m_refHeights[i]
--         end
--     end
--     return height     
-- end

-- function BetExtraCostsModule:getRefHeights()
--     local heights = {}
--     if self.m_refDatas and #self.m_refDatas > 0 then
--         for i=1,#self.m_refDatas do
--             local refData = self.m_refDatas[i]
--             if refData:isSwitchOn() then
--                 table.insert(heights, refData:getHeight() or 0)
--             else
--                 table.insert(heights, 0)
--             end
--         end
--     end
--     return heights
-- end

-- function BetExtraCostsModule:createView(_filePath)
--     if _filePath and _filePath ~= "" then
--         if util_IsFileExist(_filePath .. ".lua") or util_IsFileExist(_filePath .. ".luac") then
--             _filePath = string.gsub(_filePath, "/", ".")        
--             return util_createView(_filePath)
--         end
--     end
--     return 
-- end

function BetExtraCostsModule:initUI()
    BetExtraCostsModule.super.initUI(self)
    self:initBubbles()
end

function BetExtraCostsModule:initBubbles()
    self.m_views = {}
    local viewTotalH = 0
    -- GameBet
    local view = util_createView("BetExtraBubbleCode.GameBetExtraNode")
    if view then
        self.m_nodeBubbles:addChild(view)
        local viewH = self:getViewH(view)
        viewTotalH = viewTotalH + viewH
        table.insert(self.m_views, {view = view, viewH = viewH})
    end
    -- refs
    if self.m_refDatas and #self.m_refDatas > 0 then
        for i=1,#self.m_refDatas do
            local refData = self.m_refDatas[i]
            if refData:isSwitchOn() then
                local view = self:createBubble(refData:getRefName())
                if view then
                    self.m_nodeBubbles:addChild(view)
                    local viewH = self:getViewH(view)
                    viewTotalH = viewTotalH + viewH
                    table.insert(self.m_views, {view = view, viewH = viewH})
                end
            end
        end
    end
    -- 位置
    if #self.m_views > 0 then
        local posY = viewTotalH/2
        for i=1,#self.m_views do
            local view = self.m_views[i].view
            local viewH = self.m_views[i].viewH
            view:setPosition(cc.p(0, posY - viewH/2))
            posY = posY - viewH
        end
    end
end

function BetExtraCostsModule:createBubble(_refName)
    local view = nil
    local refMgr = G_GetMgr(_refName)
    if refMgr and refMgr.isCanShowBetBubble and refMgr:isCanShowBetBubble() then
        if refMgr.getBetBubbleLuaPath then
            local luaPath = refMgr:getBetBubbleLuaPath()
            if luaPath and luaPath ~= "" then
                view = util_createView(luaPath)
            end
        end
    end
    return view
end



return BetExtraCostsModule