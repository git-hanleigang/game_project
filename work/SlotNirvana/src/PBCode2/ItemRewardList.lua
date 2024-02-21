--道具
local BaseItemNode = util_require("PBCode2.BaseItemNode")
local ItemRewardList = class("ItemRewardList",BaseItemNode)
local DEFAULT_SIZE = cc.size(1000,400)      --默认大小
local DEFAULT_SCALE = 0.8                  --默认缩放大小
local MAX_COUNT = 5                         --每行最多数量

local ONCE_SALE_LIST = {1.1,1.1,1,DEFAULT_SCALE,DEFAULT_SCALE}     --缩放大小
local ONCE_SPAN_LIST = {2,1.5,1.3,1.2,1}    --间距缩放值

local DOUBLE_POS_LIST = {95,-85}                  --两排Y坐标

--初始化UI
-- csc 2022-01-26 list 提供新的接口，允许一行多列以及自定义cell间距和缩放
function ItemRewardList:initUI(itemList,size,maxCount,nodeSpace,scale,doublePos,onelineNoScale)
    self.m_itemList = itemList
    self.m_size = size or DEFAULT_SIZE
    self.m_maxCount = maxCount or MAX_COUNT
    self.m_nodeSpace = nodeSpace or nil
    self.m_scale = scale or DEFAULT_SCALE
    self.m_doublePos = doublePos or DOUBLE_POS_LIST 
    self.m_onelineNoScale = onelineNoScale
    self:createCsbNode("PBRes/CommonItemRes/ItemRewardList.csb")
    self:initLines()
end
--获取所有节点
function ItemRewardList:getCellList()
    return self.m_cellList
end
--根据icon获取节点只检索第一个
function ItemRewardList:findCell(icon)
    if not self.m_cellList or #self.m_cellList == 0 then
        return nil
    end
    local newIcon = gLobalItemManager:getOldToNewIcon(icon)
    for i=1,#self.m_cellList do
        local cellNode = self.m_cellList[i]
        if cellNode and cellNode.getItemData then
            local itemData = cellNode:getItemData()
            local curIcon = gLobalItemManager:getOldToNewIcon(itemData.p_icon)
            if newIcon == curIcon then
                return self.m_cellList[i]
            end
        end
    end
    return nil
end
--根据icon获取节点列表
function ItemRewardList:findCellList(icon)
    if not self.m_cellList or #self.m_cellList == 0 then
        return nil
    end
    local nodeList = {}
    local newIcon = gLobalItemManager:getOldToNewIcon(icon)
    for i=1,#self.m_cellList do
        local cellNode = self.m_cellList[i]
        if cellNode and cellNode.getItemData then
            local itemData = cellNode:getItemData()
            local curIcon = gLobalItemManager:getOldToNewIcon(itemData.p_icon)
            if newIcon == curIcon then
                nodeList[#nodeList+1] = self.m_cellList[i]
            end
        end
    end
    return nodeList
end
--显示界面
function ItemRewardList:initLines()
    if not self.m_itemList or #self.m_itemList == 0 then
        return
    end
    self.m_list = self:findChild("list")
    self.m_list:setContentSize(self.m_size)
    self.m_list:removeAllItems()
    self.m_list:setScrollBarEnabled(false)
    self.m_lines = {}
    self.m_cellList = {}
    local cloumnIndex = 1
    local rowIndex = 1
    for i=1,#self.m_itemList do
        if not self.m_lines[rowIndex] then
            self.m_lines[rowIndex] = {}
        end
        self.m_lines[rowIndex][cloumnIndex] = self.m_itemList[i]
        cloumnIndex = cloumnIndex + 1
        --是否需要换行
        if cloumnIndex>self.m_maxCount then
            rowIndex = rowIndex + 1
            cloumnIndex = 1
        end
    end
    if #self.m_lines == 1 then 
        self:updateOnceLine()
    elseif #self.m_lines == 2 then
        self:updateDoubleLine()
    else
        self:updateLines()
    end
end
--一排
function ItemRewardList:updateOnceLine()
    --修改配置
    local itemType = ITEM_SIZE_TYPE.REWARD_BIG  --图标大小
    local scale = self.m_scale                 --默认缩放值
    local width,height = self:getIconDefaultSize(itemType)   --宽度
    --计算图标缩放大小和间距
    local count = #self.m_lines[1]
    if self.m_onelineNoScale then
        scale =  self.m_scale
    else
        scale = ONCE_SALE_LIST[count] or self.m_scale
    end
    if ONCE_SPAN_LIST[count] and not self.m_onelineNoScale then
        width = ONCE_SPAN_LIST[count] * width
    end
    --添加道具
    local baseNode = gLobalItemManager:addPropNodeList(self.m_lines[1],itemType,scale,width)
    self:addChild(baseNode)
    --添加子节点列表
    for i=1,count do
        local cellNode = baseNode:getChildByTag(i)
        if cellNode.setIconTouchSwallowed then
            cellNode:setIconTouchSwallowed(false)
        end
        self.m_cellList[#self.m_cellList+1] = cellNode
    end
    --图标为啥会有些偏下
    baseNode:setPositionY(10)
end
--两排
function ItemRewardList:updateDoubleLine()
    --修改配置
    local itemType = ITEM_SIZE_TYPE.REWARD_BIG  --图标大小
    local scale = self.m_scale                 --默认缩放值
    local width,height = self:getIconDefaultSize(itemType)   --宽度
    --添加道具
    for i=1,#self.m_lines do
        local count = #self.m_lines[i]
        local baseNode = gLobalItemManager:addPropNodeList(self.m_lines[i],itemType,scale,width)
        self:addChild(baseNode)
        --添加子节点列表
        for i=1,count do
            local cellNode = baseNode:getChildByTag(i)
            if cellNode.setIconTouchSwallowed then
                cellNode:setIconTouchSwallowed(false)
            end
            self.m_cellList[#self.m_cellList+1] = cellNode
        end
        local otherX = 0
        if i == #self.m_lines and i ~= 1 then
            if count ~= self.m_maxCount then
                --最后一组没有满需要左对齐
                otherX = (count-self.m_maxCount)*width*0.5*scale
            end
        end
        baseNode:setPosition(otherX,self.m_doublePos[i])
    end
end
--超过两排
function ItemRewardList:updateLines()
    if not self.m_list or not self.m_lines or #self.m_lines == 0 then
        return
    end
    self.m_list:setScrollBarEnabled(true)
    --修改配置
    local itemType = ITEM_SIZE_TYPE.REWARD_BIG  --图标大小
    local scale = self.m_scale                 --默认缩放值
    local width,height = self:getIconDefaultSize(itemType)   --宽度
    local layoutSize = cc.size(self.m_size.width,height*scale)
    --添加道具
    for i=1,#self.m_lines do
        local count = #self.m_lines[i]
        local baseNode = gLobalItemManager:addPropNodeList(self.m_lines[i],itemType,scale,width)
        local layout=ccui.Layout:create()
        layout:setContentSize(layoutSize)
        layout:addChild(baseNode)
        self.m_list:pushBackCustomItem(layout)
        --添加子节点列表
        for i=1,count do
            local cellNode = baseNode:getChildByTag(i)
            if cellNode.setIconTouchSwallowed then
                cellNode:setIconTouchSwallowed(false)
            end
            self.m_cellList[#self.m_cellList+1] = cellNode
        end
        local otherX = 0
        if i == #self.m_lines and i ~= 1 then
            if count ~= self.m_maxCount then
                --最后一组没有满需要左对齐
                otherX = (self.m_maxCount - count)*width*0.5*scale
            end
        end
        baseNode:setPosition(layoutSize.width*0.5-otherX,layoutSize.height*0.5)
    end
    --底部填充
    local layoutBottom=ccui.Layout:create()
    layoutBottom:setContentSize(cc.size(self.m_size.width,50))
    self.m_list:pushBackCustomItem(layoutBottom)
end

--[[
    @desc: 提供方法统一返回 icon之间的 左右间距以及上下间距
    author:{author}
    time:2022-01-26 17:19:30
]]
function ItemRewardList:getIconDefaultSize(_itemType)
    local width = gLobalItemManager:getIconDefaultWidth(_itemType)   --宽度
    local height = width 
    -- csc 2022-01-26 修改cell 间距提供
    if self.m_nodeSpace then
        width = self.m_nodeSpace.width or width
        height = self.m_nodeSpace.height or height
    end
    return width,height
end

function ItemRewardList:getListView()
    return self.m_list
end
return ItemRewardList