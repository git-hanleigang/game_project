
--收藏关卡大厅列表
local CollectHall = class("CollectHall", util_require("base.BaseView"))

function CollectHall:initUI()
    self:createCsbNode("CollectionLevel/csd/Activity_CollectionLevel_Hall.csb")
    self:initView()
end

function CollectHall:initCsbNodes()
    self.node_table = self:findChild("node_table")
end

function CollectHall:initView()
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
    self.m_tableView = util_require("views.CollectLevelCode.CollectTableView").new(param)
    self.node_table:addChild(self.m_tableView)
    local list = G_GetMgr(G_REF.CollectLevel):getLevelList()
    self.m_tableView:reload(list,self.m_scale)
end

function CollectHall:updataList()
    local list = G_GetMgr(G_REF.CollectLevel):getLevelList()
    self.m_tableView:reload(list,self.m_scale)
end

function CollectHall:clickFunc(sender)

    local name = sender:getName()
    
end

function CollectHall:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(sender, _index)
            self:updataList()
        end,
        G_GetMgr(G_REF.CollectLevel):getConfig().EVENT_NAME.LEVEL_LIST
    )
end

function CollectHall:onEnter()
    CollectHall.super.onEnter(self)
    self:registerListener()
    G_GetMgr(G_REF.CollectLevel):sendGetListReq()
end

return CollectHall