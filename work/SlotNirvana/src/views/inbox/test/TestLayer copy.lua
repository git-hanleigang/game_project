--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-08-16 12:13:36
]]
local TestLayer = class("TestLayer", BaseLayer)

function TestLayer:initDatas()
    self:setLandscapeCsbName("InBox/TestLayer.csb")

    self.m_titleLuaPath = "views.inbox.test.TestListTitle"
    self.m_itemLuaPath = "views.inbox.test.TestListItem"

    self.m_selectedTitles = {}
end

function TestLayer:initCsbNodes()
    self.m_pList = self:findChild("Panel_list")
    -- self.m_listView = self:findChild("ListView_1")
    -- self.m_listView:setScrollBarEnabled(false)
end

function TestLayer:initView()
    self:initList()
    self:initListView()
end

-- function TestLayer:initListView()
--     self.m_listItems = {}
--     local listData = self:getGroupData()
--     if listData and #listData > 0 then
--         for i=1,#listData do
--             local item = nil
--             local data = listData[i]
--             if data.type == "title" then
--                 item = util_createView(self.m_titleLuaPath, data, handler(self, self.clickTitle))
--             elseif data.type == "item" then
--                 item = util_createView(self.m_itemLuaPath, data)
--             end
--             if item then
--                 local layout = ccui.Layout:create()
--                 layout:addChild(item)
--                 local itemSize = item:getContentSize()
--                 layout:setContentSize(itemSize)
--                 -- item:setPosition(itemSize.width / 2, itemSize.height / 2)
--                 item:setPosition(cc.p(0, 0))
--                 self.m_listView:pushBackCustomItem(layout)
--                 local p = cc.p(layout:getPosition())
--                 print("p = ", p.x, p.y)
--                 table.insert( self.m_listItems, {data = data, layer = layout, item = item})
--             end
--         end
--     end
-- end

-- function TestLayer:clickTitle(_id, _key, _num)
--     if self.m_listItems and #self.m_listItems > 0 then
--         for i=1,#self.m_listItems do
--             local layer = self.m_listItems[i].layer
--             local data = self.m_listItems[i].data
--             if data.id > _id then
--                 if data.key == _key then
--                     self:moveItem(layer, )
--                 else

--                 end  
--             end
--         end
--     end
-- end

-- function TestLayer:moveItem(_item, _moveDistance)
--     local nowPos = cc.p(_item:getPosition())
--     print("nowPos = ", i, nowPos.x, nowPos.y)

--     local actionList = {}
--     actionList[#actionList + 1] = cc.MoveTo:create(1, cc.p(nowPos.x, nowPos.y + _moveDistance))
--     _item:runAction(cc.Sequence:create(actionList))
-- end

function TestLayer:initList()
    local size = self.m_pList:getContentSize()
    local groupData = self:getGroupData()
    self.m_listView = TestGroupList:create(size, groupData)
    self.m_listView:addToParent(self.m_pList)
    self.m_listView:setClass(self.m_titleLuaPath, self.m_itemLuaPath)
end

function TestLayer:getGroupData()
    return {
        {
            title = 'coupon',
            items = {
                { id = 1, count = 20, lv = 19 },
                { id = 2, count = 21, lv = 21 },
                { id = 3, count = 22, lv = 23 },
                { id = 4, count = 22, lv = 23 },
                { id = 5, count = 22, lv = 23 },
            }
        },
        {
            title = 'mini game',
            items = {
                { id = 1, count = 20, lv = 19 },
                { id = 2, count = 21, lv = 21 },
                { id = 3, count = 22, lv = 23 },
                { id = 3, count = 22, lv = 23 },
            }
        }
    }
end

-- function TestLayer:getGroupData()
--     return {
--         {id = 1, type = "title", key = "coupon", num = 4},
--         {id = 2, type = "item", key = "coupon"},
--         {id = 3, type = "item", key = "coupon"},
--         {id = 4, type = "item", key = "coupon"},
--         {id = 5, type = "item", key = "coupon"},
--         {id = 6, type = "title", key = "miniGame", num = 3},
--         {id = 7, type = "item", key = "miniGame"},
--         {id = 8, type = "item", key = "miniGame"},
--         {id = 9, type = "item", key = "miniGame"},
--         {id = 10, type = "normal", key = "normal"},
--         {id = 11, type = "normal", key = "normal"},
--         {id = 12, type = "normal", key = "normal"},
--         {id = 13, type = "normal", key = "normal"},
--         {id = 14, type = "normal", key = "normal"},
--     }
-- end

return TestLayer