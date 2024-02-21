--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-08-16 12:13:36
]]
local TestLayer = class("TestLayer", BaseLayer)

function TestLayer:initDatas()
    self:setLandscapeCsbName("InBox/TestLayer.csb")

    self._titleLuaPath =  "views.inbox.test.TestListTitle"
    self._itemLuaPath = "views.inbox.test.TestListItem"  

    self.m_selectedTitles = {}
end

function TestLayer:initCsbNodes()
    self.m_pList = self:findChild("Panel_list")
end

function TestLayer:initView()
    self:initList()
end

function TestLayer:initList()
    local size = self.m_pList:getContentSize()
    local groupData = self:getGroupData()
    self.m_listView = util_require("view.inbox.test.TestGroupList"):create(size, groupData)
    self.m_listView:setClass(self._titleLuaPath, self._itemLuaPath)
    self.m_pList(self.m_listView)
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
                { id = 4, count = 22, lv = 23 },
            }
        },
        {
            title = 'collect',
            items = {
                { id = 1, count = 20, lv = 19 },
                { id = 2, count = 21, lv = 21 },
                { id = 3, count = 22, lv = 23 },
                { id = 4, count = 22, lv = 23 },
                { id = 5, count = 22, lv = 23 },
                { id = 6, count = 22, lv = 23 },
                { id = 7, count = 22, lv = 23 },
                { id = 8, count = 22, lv = 23 },
            }
        }
    }
end

return TestLayer