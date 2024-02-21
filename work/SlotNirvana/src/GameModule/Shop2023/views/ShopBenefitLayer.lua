local ShopBenefitLayer = class("ShopBenefitLayer", BaseLayer)

function ShopBenefitLayer:ctor()
    ShopBenefitLayer.super.ctor(self)
    self:setLandscapeCsbName(SHOP_RES_PATH.ItemBenefitBoard)
end

function ShopBenefitLayer:initDatas(_buyData)
    self.m_buyData = _buyData
    self.m_listCell = {}
    self.ROW_MAX_COUNT = 2
end

function ShopBenefitLayer:initCsbNodes()
    self.m_listView = self:findChild("benefitsView")
end

function ShopBenefitLayer:initView()
    self.m_listView:setScrollBarEnabled(false)
    -- 加载list view
    local itemList = gLobalItemManager:checkAddLocalItemList(self.m_buyData)
    local itemCellNum = (itemList ~= nil and table.nums(itemList) > 0) and #itemList or 0

    -- 计算出应该添加几条 cell
    -- 每行两个任务 ，算出当前一共可以放几行，向上取整数
    local rowSize = math.ceil(itemCellNum / self.ROW_MAX_COUNT)
    for i = 1, rowSize do
        local cell = util_createView(SHOP_CODE_PATH.ItemBenefitBoardCellNode)
        local cellLayout = ccui.Layout:create()
        cellLayout:setContentSize({width = 910, height = 140})
        cellLayout:addChild(cell)
        self.m_listView:pushBackCustomItem(cellLayout)
        table.insert(self.m_listCell, cell)
    end
    -- 获得数据传入创建好的条
    local iSum = 0
    local itemDataInfo = {}
    for i = 1, #itemList do
        local itemData = itemList[i]
        if itemData then
            iSum = iSum + 1
            table.insert(itemDataInfo, itemData)
            if iSum == self.ROW_MAX_COUNT or (i == #itemList and iSum == 1) then
                local index = i / iSum == i and rowSize or i / iSum
                self.m_listCell[index]:updateView(itemDataInfo)
                iSum = 0
                itemDataInfo = {}
            end
        end
    end
end

function ShopBenefitLayer:clickFunc(sender)
    if self.m_isTouch then
        return
    end
    self.m_isTouch = true

    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

return ShopBenefitLayer
