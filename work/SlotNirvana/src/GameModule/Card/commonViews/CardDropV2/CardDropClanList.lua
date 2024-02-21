--[[
]]
local CardDropClanList = class("CardDropClanList", BaseView)

function CardDropClanList:getCsbName()
    if globalData.slotRunData.isPortrait == true then
        return "CardsBase201903/CardRes/season201903/DropNew2/clan_list_shu.csb"    
    end
    return "CardsBase201903/CardRes/season201903/DropNew2/clan_list.csb"
end

function CardDropClanList:initDatas(_cardDatas, _clanCollects)
    self.m_cardDatas = _cardDatas
    self.m_clanCollects = _clanCollects

    -- 列数
    self.m_colNumber = globalData.slotRunData.isPortrait == true and 3 or 2
    -- 章节的大小
    self.m_cellSize = cc.size(200, 150)
end

function CardDropClanList:initCsbNodes()
    self.m_listView = self:findChild("Panel_list")
    self.m_listViewWidth = self.m_listView:getContentSize().width
    self.m_listViewHeight = self.m_listView:getContentSize().height
end

function CardDropClanList:initUI()
    CardDropClanList.super.initUI(self)
    self:initView()
end

function CardDropClanList:initView()
    self:initListView()
end

function CardDropClanList:initListView()
    local listData = self:getListViewData()

    -- 行数
    self.m_rowNumber = math.ceil(table.nums(listData)/self.m_colNumber)
    print("initListView self.m_rowNumber=", self.m_rowNumber)
    -- 高度
    local layoutW = self.m_listViewWidth
    local layoutH = self.m_cellSize.height
    -- innersize
    local innerH = self.m_rowNumber * layoutH
    self.m_listView:setInnerContainerSize(cc.size(layoutW, innerH))

    self.m_items = {}
    for cellIndex = 1, self.m_rowNumber do
        -- 创建layout
        local layout = ccui.Layout:create()
        layout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
        layout:setBackGroundColor(cc.c3b(255, 0, 0))
        layout:setBackGroundColorOpacity(0)        
        layout:setContentSize({width = layoutW, height = layoutH})
        -- 创建item
        for colIndex = 1, self.m_colNumber do
            local dataIndex = colIndex + (cellIndex-1)*self.m_colNumber
            print("initListView dataIndex=", dataIndex)
            local cellData = listData[dataIndex]
            if cellData then
                local cell = util_createView("GameModule.Card.commonViews.CardDropV2.CardDropClan")
                layout:addChild(cell)
                cell:updateCell(dataIndex, cellData)
                -- 设置item位置
                local cellW = layoutW/self.m_colNumber -- self.m_cellSize.width
                local cellPosX = cellW/2 + (colIndex - 1)*cellW
                cell:setPosition(cc.p(cellPosX, layoutH/2))
                -- 存表
                table.insert(self.m_items, cell)
            end
        end
        -- 插入listview
        self.m_listView:addChild(layout)
        local topH = math.max(innerH, self.m_listViewHeight)
        local layoutPosY = topH - layoutH * cellIndex
        layout:setPosition(cc.p(0, layoutPosY))
        
        -- self.m_listView:pushBackCustomItem(layout)
    end
end

function CardDropClanList:onEnter()
    CardDropClanList.super.onEnter(self)
end

function CardDropClanList:getListViewData()
    -- local cardClans, wildClans, normalClans, statueClans = CardSysRuntimeMgr:getAlbumTalbeviewData()
    local normalClans = CardSysRuntimeMgr:getClanCollects(true)
    local clans = {}
    if normalClans and #normalClans > 0 then
        for i = 1,#normalClans do
            local clanData = normalClans[i]
            if self.m_clanCollects[clanData.clanId] ~= nil then
                -- print("CardDropClanList:getListViewData, clanId="..clanData.clanId)
                clans[#clans+1] = clanData
            end
        end
    end
    if clans and #clans > 0 then
        table.sort(clans,
            function(a, b)
                return tonumber(a.clanId) < tonumber(b.clanId)
            end
        )
    end
    return clans
end

function CardDropClanList:getClanCellByClanId(_clanId)
    local items = self.m_items
    if items and #items > 0 then
        for i=1,#items do
            local item = items[i]
            local clanId = item:getClanId()
            -- print("getClanCellByClanId clanId 1", clanId, _clanId)
            if clanId == _clanId then
                -- print("getClanCellByClanId clanId 2", clanId, _clanId)
                return item
            end
        end
    end
    return item
end

function CardDropClanList:playClansFlyIn(_isSkip)
    local items = self.m_items
    if items and #items > 0 then
        for i = 1, #items do 
            local item = items[i]
            item:playFlyIn(_isSkip)
        end
    end    
end

function CardDropClanList:getPanelCenterWorldPos()
    local panelPos = cc.p(self.m_listView:getPosition())
    local panelWPos = self.m_listView:getParent():convertToWorldSpace(cc.p(panelPos.x, panelPos.y))
    return panelWPos
end

function CardDropClanList:getPanelBottomWorldPos()
    local panelPos = cc.p(self.m_listView:getPosition())
    local panelSize = self.m_listView:getContentSize()
    local panelWPos = self.m_listView:getParent():convertToWorldSpace(cc.p(panelPos.x, panelPos.y-panelSize.height/2))
    return panelWPos
end

function CardDropClanList:getClanCellWorldPos(_clanId)
    local panelWPos = self:getPanelBottomWorldPos()
    local clanCell = self:getClanCellByClanId(_clanId)
    if not clanCell then
        -- print("getClanCellWorldPos not find clanCell, _clanId =", _clanId)
        return panelWPos
    end
    local clanPos = cc.p(clanCell:getPosition())
    local clanLayout = clanCell:getParent()
    local clanLayoutPos = cc.p(clanLayout:getPosition())
    -- print("clanPos = ", clanLayoutPos.x, clanLayoutPos.y, clanPos.x, clanPos.y)
    local clanWPos = clanCell:getParent():convertToWorldSpace(cc.p(clanCell:getPosition()))
    if clanWPos.y < panelWPos.y then
        -- print("getClanCellWorldPos clanWPos.y < panelWPos.y", _clanId, clanWPos.y, panelWPos.y)
        return panelWPos
    end
    -- print("getClanCellWorldPos clanWPos = ", _clanId, clanWPos.x, clanWPos.y, panelWPos.x, panelWPos.y)
    return clanWPos
end

return CardDropClanList