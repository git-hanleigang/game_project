--[[
    购买权益
]]

local PBInfoLayer = class("PBInfoLayer", BaseLayer)

function PBInfoLayer:ctor()
    PBInfoLayer.super.ctor(self)
    self:setLandscapeCsbName(SHOP_RES_PATH.ItemBenefitBoard)
end

function PBInfoLayer:initDatas(_buyData, _itemList, _refName, _notRemoveSame)
    self.m_buyData = _buyData
    self.m_itemList = _itemList or {}
    self.m_refName = _refName
    self.m_notRemoveSame = _notRemoveSame
    self.m_listCell = {}
    self.ROW_MAX_COUNT = 2
end

function PBInfoLayer:initCsbNodes()
    self.m_listView = self:findChild("benefitsView")
end

function PBInfoLayer:initView()
    self.m_listView:setScrollBarEnabled(false)
    -- 加载list view
    local itemList = {}
    if self.m_buyData then 
        itemList = gLobalItemManager:checkAddLocalItemList(self.m_buyData, self.m_itemList, nil, self.m_notRemoveSame)
    else
        itemList = self.m_itemList
    end
    local itemCellNum =  (itemList ~= nil and table.nums(itemList) > 0) and #itemList or 0

    -- 计算出应该添加几条 cell 向上取整
    local rowSize = math.ceil(itemCellNum / self.ROW_MAX_COUNT) 
    for i = 1 ,rowSize do
        local cell = util_createView(SHOP_CODE_PATH.ItemBenefitBoardCellNode)
        local cellLayout = ccui.Layout:create()
        cellLayout:setContentSize({width = 910, height = 140})
        cellLayout:addChild(cell)
        self.m_listView:pushBackCustomItem(cellLayout)
        table.insert(self.m_listCell,cell)
    end
    -- 获得数据传入创建好的条
    local iSum = 0
    local itemDataInfo = {}
    for i = 1 ,#itemList do
        local itemData = itemList[i]
        if itemData then
            iSum = iSum + 1
            table.insert(itemDataInfo,itemData)
            if iSum == self.ROW_MAX_COUNT or (i == #itemList and iSum == 1) then
                local index = i/iSum == i and rowSize or i/iSum
                self.m_listCell[index]:updateView(itemDataInfo)
                iSum = 0
                itemDataInfo = {}
            end
        end
    end
end

function PBInfoLayer:clickFunc(sender)
    if self.m_isTouch then
        return
    end
    self.m_isTouch = true

    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

function PBInfoLayer:onEnter()
    PBInfoLayer.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)
        self:closeUI() 
    end ,ViewEventType.NOTIFY_SHOPINFO_CLOSE)

    -- 跨天刷新ui
    gLobalNoticManager:addObserver(
        self,
        function(params)
            if not tolua.isnull(self) then
                self:closeUI() 
            end
        end,
        ViewEventType.NOTIFY_NEWZEROUPDATE
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if self.m_refName and params.name == self.m_refName then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

return PBInfoLayer