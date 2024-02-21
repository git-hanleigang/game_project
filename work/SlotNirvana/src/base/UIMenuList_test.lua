--[[
    二级折叠菜单组

    构造：
    local groupData = {
        {
            title = '分类1',
            items = {
                { id = 1, count = 20, lv = 19 },
                { id = 2, count = 21, lv = 21 },
                { id = 3, count = 22, lv = 23 },
            }
        },
        {
            title = '图腾',
            items = {
                { id = 500001, count = 32, lv = 19 },
                { id = 500002, count = 21, lv = 65 },
                { id = 500003, count = 22, lv = 27 },
            }
        },
        {
            title = '武器',
            items = {
                { id = 101002, count = 20, lv = 45 },
                { id = 101003, count = 21, lv = 34 },
            }
        },
    }
    self._goodsCateList = gm.Common.UIMenuList.new( cc.size( 310, 510 ), groupData )

    -- 必须设置标题类型和内容类型，重写可改变样式
    self._goodsCateList:setClass( gm.Market.MarketMenuTitle, gm.Market.MarketMenuItem )
    
    -- 可选参数，是否可同时展开多个分组，默认false
    self._goodsCateList.showMulti = true

    -- 可选参数，是否默认选中组中第一个item
    self._goodsCateList.autoSelectFirstItem = true

    -- 可选参数，选中的title索引，默认为1
    self._goodsCateList.defaultGroup = 1

    -- 可选参数，选中的item索引，默认为1
    self._goodsCateList.defaultItem = 1

    加入舞台：
    self._goodsCateList:addToParent( self._bg, { x = 0, y = 0 } )

    @author cc
--]]

gm = gm or {}
rm = rm or {} 

local gm = gm
local rm = rm 

gm.Common                       = gm.Common or {}
gm.Common.UIMenuList            = class( "Common.UIMenuList" )
gm.Common.UIMenuList._name      = "Common.UIMenuList"

local g = gm.Common.UIMenuList

---------------------------------------------------------------------------------
--                                                                             --
--                          以下定义私有部分                                   --
--                                                                             --
---------------------------------------------------------------------------------

local function log( ... )
    print( '>>>>gm.Common.UIMenuList<<<<:', ...)
end

-- 点击标题项
function g:_onTouchTitle( sender )
    local titleInst = sender._inst

    -- 收缩点击项
    if titleInst.selected then
        self:_unSelectTitleInst( titleInst )
        return
    end

    -- 如果同时只展开一个分组，则隐藏上次展开的
    if not self._showMulti and self._selectedTitle then
        self:_unSelectTitleInst( self._selectedTitle )
    end

    -- 展开点击项
    local index = self._listView:getIndex( sender )
    local group = titleInst.data
    local itemInst
    for itemIdx, itemData in ipairs( group.items ) do
        itemInst = self:_createItemInst( itemData )
        self._listView:insertCustomItem( itemInst.ui, index + itemIdx )

        -- 将第一项设置为当前选中的内容项
        if self._autoSelectFirstItem and itemIdx == 1 then
            self.selectedItem = itemInst
        end 
    end

    -- 设置当前选中的标题项
    self.selectedTitle = titleInst
end

-- 点击内容项
function g:_onTouchItem( sender, eventType )
    if eventType == ccui.TouchEventType.ended then
        self.selectedItem = sender._inst
    end
    if self._itemClickFunc then
        self._itemClickFunc( sender, eventType )
    end
end

-- 收起标题项对应的分组
function g:_unSelectTitleInst( titleInst )
    local index = self._listView:getIndex( titleInst.ui )
    local group = titleInst.data
    local itemInst

    for i = 1, #group.items do

        -- 析构删除项
        itemInst = self._listView:getItem( index + 1 )._inst
        itemInst:finalize()

        -- 选中项被删除
        if self._selectedItem and self._selectedItem == itemInst then
            self._selectedItem = nil
        end

        self._listView:removeItem( index + 1 )
    end
    titleInst.selected = false

    if titleInst == self._selectedTitle then
        self._selectedTitle = nil
    end
end

-- 创建标题项
function g:_createTitleInst( data )
    if not self._titleCls then
        log( '没有设置标题类型!' )
        return
    end

    local titleInst = self._titleCls.new( )
    titleInst.data = data
    titleInst.ui._inst = titleInst
    makeTouchHandle( self, titleInst.ui, self._onTouchTitle )
    return titleInst
end

-- 创建内容项
function g:_createItemInst( data )
    if not self._itemCls then
        log( '没有设置内容类型!' )
        return
    end

    local itemInst = self._itemCls.new( )
    itemInst.data = data
    itemInst.ui._inst = itemInst
    makeTouchHandle2( self, itemInst.ui, self._onTouchItem )
    return itemInst
end

-- 初始化
function g:_initialize( )
    self._listView = ccui.ListView:create()
    self._listView:setBounceEnabled( true )
    self._listView:setDirection( ccui.ScrollViewDir.vertical )
    self._listView:setSize( self._size )

    if not self._groupData then
        log( '分组数据为空!' )
        return
    end
    
    local titleInst, itemInst
    self._titleInstList = {}

    for groupIdx, group in ipairs( self._groupData ) do

        titleInst = self:_createTitleInst( group )
        self._listView:pushBackCustomItem( titleInst.ui )
        table.insert( self._titleInstList, titleInst )

        -- 展开默认分组
        if self._defaultGroupIdx and groupIdx == self._defaultGroupIdx then
            self.selectedTitle = titleInst
            
            for itemIdx, itemData in ipairs( group.items ) do

                itemInst = self:_createItemInst( itemData )
                self._listView:pushBackCustomItem( itemInst.ui )

                -- 选中默认项
                if self._defaultItemIdx and itemIdx == self._defaultItemIdx then
                    self.selectedItem = itemInst
                end
            end
        end
    end
end

---------------------------------------------------------------------------------
--                                                                               --
--                        以下定义set, get 部分函数                               --
--                                                                               --
---------------------------------------------------------------------------------

function g:_getUi( )
    return self._listView
end

-- 是否同时展开多个组
function g:_setShowMulti( value )
    self._showMulti = value
end

-- 获取数据
function g:_getGroupData( )
    return self._groupData
end

function g:_setGroupData( value )
    self._groupData = value
end

-- 设置默认展开的分组索引
-- @i value
function g:_setDefaultGroup( value )
    self._defaultGroupIdx = value
end

-- 设置默认选中的item索引
--@i value 
function g:_setDefaultItem( value )
    self._defaultItemIdx = value
end

-- 获取选中的标题项
function g:_getSelectedTitle( )
    return self._selectedTitle
end

function g:_setSelectedTitle( value )
    value.selected = true
    self._selectedTitle = value
    rm.BindManager.propertyChanged( self, "selectedTitle" )
end

-- 获取选中的内容项
function g:_getSelectedItem( )
    return self._selectedItem
end

function g:_setSelectedItem( value )
    if self._selectedItem then
        self._selectedItem.selected = false 
    end
    value.selected = true
    self._selectedItem = value
    rm.BindManager.propertyChanged( self, "selectedItem" )
end

-- 设置点击item项的回调函数
function g:_setItemClickFunc( value )
    self._itemClickFunc = value
end

-- 设置是否自动选中组中第一个item
function g:_setAutoSelectFirstItem( value )
    self._autoSelectFirstItem = value
end

---------------------------------------------------------------------------------
--                                                                             --
--                          以下定义公共部分                                   --
--                                                                             --
---------------------------------------------------------------------------------

-- 构造
-- @t size cc.size类型
-- @t groupData 分组数据，结构如{ { title = tData, items = { iData1, iData2 } }, ... }
function g:ctor( size, groupData )
    self._size = size or cc.size( 200, 200 )
    self._groupData = groupData
    self._titleInstList = nil
    self._defaultGroupIdx = nil
    self._defaultItemIdx = nil
    self._selectedTitle = nil
    self._selectedItem = nil
    self._titleCls = nil
    self._itemCls = nil
    self._showMulti = false
    self._autoSelectFirstItem = false
    self._itemClickFunc = nil
end

-- 设置标题项和内容项类型
-- @t titleClass 继承自gm.Common.UIMenuItem，重写可改变样式
-- @t itemClass  继承自gm.Common.UIMenuItem，重写可改变样式
function g:setClass( titleClass, itemClass )
    self._titleCls = titleClass
    self._itemCls = itemClass
end

-- 添加到舞台
-- @widget parent 父显示对象
-- @t        pos    位置，{ x = , y = }
-- @i        zOrder 层级
function g:addToParent( parent, pos, zOrder )
    if not parent then
        log( '父显示对象不可为空!' )
        return
    end
    self:_initialize()
    zOrder = zOrder or 1
    pos = pos or cc.p( 0, 0 )
    self._listView:setPosition( pos )
    parent:addChild( self._listView, zOrder )
end

-- 刷新当前展开的分组，只可在互斥（showMulti = false）模式下使用
-- @t group 数据，结构如{ title = tData, items = { iData1, iData2 } }
function g:refreshSelectedTitle( group )
    if not self._selectedTitle then return end
    self:refreshTitle( self._selectedTitle, group )
end

-- 刷新指定位置的分组
-- @i titleIndex     分组索引
-- @t group         组数据
function g:refreshTitleAtIndex( titleIndex, group )
    local title = self._titleInstList( titleIndex )
    self:refreshTitle( title, group )
end

-- 刷新指定分组
-- @t             某个分组
-- @t group     组数据
function g:refreshTitle( title, group )
    local index = self._listView:getIndex( title.ui )
    local prevNumItems = title.selected and #title.data.items or 0
    local currNumItems = #group.items
    local deltaNum = prevNumItems - currNumItems
    local itemInst

    -- 设置title数据
    title:_setData( group )
    self._groupData[ table.indexOf( self._titleInstList, title ) ] = group

    -- title没展开，以下无需执行
    if not title.selected then return end

    -- 设置item数据
    for itemIdx, itemData in ipairs( group.items ) do
        if itemIdx <= prevNumItems then
            itemInst = self._listView:getItem( index + itemIdx )._inst    
            itemInst:_setData( itemData )
        else
            itemInst = self:_createItemInst( itemData )
            self._listView:insertCustomItem( itemInst.ui, index + itemIdx )
        end
    end

    -- 旧数量比当前数量多，需要删除多余的item
    if deltaNum > 0 then
        for i = 1, deltaNum do
            itemInst = self._listView:getItem( index + currNumItems + 1 )._inst
            itemInst:finalize()

            -- 选中项被删除
            if self._selectedItem and self._selectedItem == itemInst then
                self._selectedItem = nil
            end

            self._listView:removeItem( index + currNumItems + 1 )
        end
    end
end

-- 刷新整个控件
-- @t 控件数据，结构如构造函数同名参数所示
function g:refresh( groupData )
    self._groupData = groupData
    if not self._groupData then
        log( '分组数据为空!' )
        return
    end

    local prevNumTitles = #self._titleInstList
    local currNumTitles = #groupData
    local deltaNum = prevNumTitles - currNumTitles
    local titleInst
    
    -- 刷新所有分组
    for groupIdx, group in ipairs( groupData ) do
        if groupIdx <= prevNumTitles then 
            titleInst = self._titleInstList[ groupIdx ]
            self:refreshTitle( titleInst, group )
        else
            titleInst = self:_createTitleInst( group )
            self._listView:pushBackCustomItem( titleInst.ui )
            table.insert( self._titleInstList, titleInst )
        end
    end
    
    -- 新分组比旧分组少，需要删除多余的title
    if deltaNum > 0 then
        local numListItems = #self._listView:getItems()

        -- 清空全部
        if currNumTitles == 0 then
            for i = numListItems - 1, 0, -1 do
                titleInst = self._listView:getItem( i )._inst
                titleInst:finalize()
            end
            self._listView:removeAllItems()
            self._titleInstList = {}
            self._selectedTitle = nil
            self._selectedItem = nil
            return
        end

        local lastTitleInst = self._titleInstList[ currNumTitles ]
        local index = self._listView:getIndex( lastTitleInst.ui ) + ( lastTitleInst.selected and #lastTitleInst.data.items or 0 )

        for i = numListItems - 1, index + 1, -1 do
            -- 析构被删除的title
            titleInst = self._listView:getItem( i )._inst
            titleInst:finalize()

            -- 选中title被删除
            if self._selectedTitle and self._selectedTitle == titleInst then
                self._selectedTitle = nil
            end

            -- 选中项被删除
            if self._selectedItem and self._selectedItem == titleInst then
                self._selectedItem = nil
            end

            self._listView:removeItem( i )
        end

        -- 从title列表中移除
        for i = prevNumTitles, currNumTitles + 1, -1 do
            table.remove( self._titleInstList, i )
        end
    end
end

-- 析构
function g:finalize()
    if self._listView then
        self._listView:removeFromParent()
        self._listView = nil
    end
    self._titleInstList = nil
    self._groupData = nil
    self._itemClickFunc = nil
end