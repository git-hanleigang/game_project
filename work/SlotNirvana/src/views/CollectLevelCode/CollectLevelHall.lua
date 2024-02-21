
--收藏关卡大厅列表
local CollectLevelHall = class("CollectLevelHall", util_require("base.BaseView"))

function CollectLevelHall:initUI()
    self:createCsbNode("CollectionLevel/csd/Activity_CollectionLevel_Hall.csb")
    self:initView()
end

function CollectLevelHall:initCsbNodes()
    self.node_table = self:findChild("node_table")
end

function CollectLevelHall:initView()
    self.m_scale = self:getUIScalePro()
    local size = self.node_table:getContentSize()
    size.height = size.height*(1/self.m_scale)
    local offset = util_getBangScreenHeight()
    if offset and offset > 0 then
        size.width = size.width - offset - 20
    end
    self.node_table:setContentSize(size.width,size.height)
    local param = {
        tableSize = size,
        parentPanel = self.node_table,
        directionType = 1
    }
    self.m_tableView = util_require("views.CollectLevelCode.CollectLevelTable").new(param)
    self.node_table:addChild(self.m_tableView)
end

function CollectLevelHall:updataList(_type)
    local list = G_GetMgr(G_REF.CollectLevel):getHallList(_type)
    self.m_tableView:reload(list,self.m_scale,_type)
end

function CollectLevelHall:onEnter()
    CollectLevelHall.super.onEnter(self)
end

return CollectLevelHall