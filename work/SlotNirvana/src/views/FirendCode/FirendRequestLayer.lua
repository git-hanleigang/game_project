--好友消息处理界面
local FirendRequestLayer = class("FirendRequestLayer", BaseLayer)

function FirendRequestLayer:ctor()
    FirendRequestLayer.super.ctor(self)
    self:setLandscapeCsbName("Friends/csd/Activity_Friends_Requests.csb")
    self.ManGer = G_GetMgr(G_REF.Friend)
    self.m_data = G_GetMgr(G_REF.Friend):getData()
end

function FirendRequestLayer:initCsbNodes()
    self.listView = self:findChild("ListView")
    self.lb_friends_number = self:findChild("lb_friends_number")
    self.empty_img = self:findChild("empty_img")
end

function FirendRequestLayer:initView()
    self.add_list = self.m_data:getRequestList()
    self.listView:setScrollBarEnabled(false)
    self:updataListView(self.add_list)
    self.lb_friends_number:setString(#self.add_list.."/"..self.m_data:getMaxCount())
end

function FirendRequestLayer:updataListView(_data)
    if #self.add_list == 0 then
        self.empty_img:setVisible(true)
    else
        self.empty_img:setVisible(false)
    end
    self.item_list = {}
    self.listView:removeAllChildren()
    for i,v in ipairs(_data) do
        local view = util_createView("views.FirendCode.FirendRequestCell")
        local size = view:getItemSize()
        view:updataCell(v)
        local layout = ccui.Layout:create()
        layout:setContentSize({width = size.width, height = size.height})
        view:setPosition(size.width/2,size.height/2-5)
        layout:addChild(view)
        table.insert(self.item_list,layout)
        self.listView:pushBackCustomItem(layout)
    end
end

function FirendRequestLayer:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            local list = self.m_data:getRequestList()
            local index = 0
            if #list > 0 then
                for i,v in ipairs(list) do
                    if params.uid == v.udid then
                        index = i
                    end
                end
            end
            if index ~= 0 then
                self:playItem(index)
            end
        end,
        FriendConfig.EVENT_NAME.REQUEST_FRIEND
    )
end

function FirendRequestLayer:playItem(_index)
    local item = self.item_list[_index]
    table.remove(self.item_list,_index)
    if item then
        util_fadeOutNode(
            item,
            1,
            function()
                if not tolua.isnull(self) then
                    self.listView:removeChild(item)
                    local list = self.m_data:getRequestList()
                    table.remove(list,_index)
                    self.m_data:setRequestList(list)
                    self.lb_friends_number:setString(#list.."/"..self.m_data:getMaxCount())
                end
            end
        )
    end
end

function FirendRequestLayer:clickStartFunc(sender)
end

function FirendRequestLayer:closeUI()
    FirendRequestLayer.super.closeUI(self)
end

function FirendRequestLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

return FirendRequestLayer