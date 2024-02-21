--好友主界面
local FirendMainLayer = class("FirendMainLayer", BaseLayer)
local SensitiveWordParser = util_require("utils.sensitive.SensitiveWordParser")

function FirendMainLayer:ctor()
    FirendMainLayer.super.ctor(self)
    self:setLandscapeCsbName("Friends/csd/Activity_FriendsMain.csb")
    self.ManGer = G_GetMgr(G_REF.Friend)
    self.m_data = G_GetMgr(G_REF.Friend):getData()
end

function FirendMainLayer:initCsbNodes()
    self.empty_node = self:findChild("node_desc")
    self.node_table = self:findChild("node_table")
    self.node_helptable = self:findChild("node_helptable")
    self.node_macytable = self:findChild("node_macytable")
    self.friends_number = self:findChild("lb_friends_number")
    self.reddian = self:findChild("reddian")
    self.red_num = self:findChild("red_num")
    self.node_frid_main = self:findChild("node_frdmain")
    self.node_help_main = self:findChild("node_help_main")
    self.help_empty = self:findChild("node_help")
    self.node_macy_main = self:findChild("node_intimacy_main")
    self.macy_empty = self:findChild("node_iempty")
    self.btn_info = self:findChild("btn_info")
    self.btn_sdel = self:findChild("btn_del")
    self.lb_noSearch = self:findChild("lb_noSearch")
    self.sp_num_icon = self:findChild("sp_num_icon")
end

function FirendMainLayer:initView()
    G_GetMgr(G_REF.Friend):pGetAllFriendList(nil,nil,"first")
    self.btn_img = {self:findChild("firend_main"),self:findChild("firend_help"),self:findChild("firend_invite")}
    self.friend_data = {}
    local content_size = self.node_table:getContentSize()
    local param = {
        tableSize = content_size,
        parentPanel = self.node_table,
        directionType = 2
    }
    self.m_tableView = util_require("views.FirendCode.FirendTableView").new(param)
    self.node_table:addChild(self.m_tableView)
    local requestData = self.m_data:getRequestList()
    if requestData and #requestData > 0 then
        self.reddian:setVisible(true)
        self.red_num:setString(#requestData)
    end
    local size = self.node_helptable:getContentSize()
    local param = {
        tableSize = size,
        parentPanel = self.node_helptable,
        directionType = 2
    }
    self.m_helptableView = util_require("views.FirendCode.HelpTableView").new(param)
    self.node_helptable:addChild(self.m_helptableView)
    self.m_current = 1
    self.btn_sdel:setVisible(false)
    -- help页签按钮可用状态
    self:checkBtnHelpEnableState()
end

-- help页签按钮可用状态
function FirendMainLayer:checkBtnHelpEnableState()
    local bCardNovice = CardSysManager:isNovice()
    local spHelpLock = self:findChild("sp_helpLock")
    local btnHelp = self:findChild("btn_help")
    spHelpLock:setVisible(bCardNovice)
    btnHelp:setTouchEnabled(not bCardNovice)
end

function FirendMainLayer:updataHelp(_data)
    if #_data > 0 then
        self.help_empty:setVisible(false)
    else
        self.help_empty:setVisible(true)
    end
    self.m_helptableView:reload(_data,1)
    self:checkReve()
end

function FirendMainLayer:updataTable(_data)
    if _data and #_data > 0 then
        self.empty_node:setVisible(false)
    else
        self.empty_node:setVisible(true)
    end
    self.m_tableView:reload(_data)
end

function FirendMainLayer:updataMacy(_data)
    if #_data > 0 then
        self.macy_empty:setVisible(false)
    else
        self.macy_empty:setVisible(true)
    end
    self.m_helptableView:reload(_data,2)
end

function FirendMainLayer:serchName()
    local textFieldSearch = self:findChild("text_seek")
    self.spPlaceHolder = self:findChild("lb_seek")
    self.m_eboxSearch = util_convertTextFiledToEditBox(textFieldSearch, nil, function(strEventName,pSender)
        if strEventName == "began" then
            self.spPlaceHolder:setVisible(false)
        elseif strEventName == "changed" or strEventName == "return" then
            local content = self.m_eboxSearch:getText()
            local content = SensitiveWordParser:getString(content, "*", SensitiveWordParser.PARSE_LEVEL.HIGH)
            content = string.gsub(content, "[^%w]", "")
            self.spPlaceHolder:setVisible(#content <= 0)
            self.btn_sdel:setVisible(#content > 0)
            self.m_eboxSearch:setText(content)

            if strEventName == "return" then
                if #self.friend_data > 0 and content ~= nil then
                    local s_data = self.ManGer:stringMatch(self.friend_data,content)
                    if s_data and #s_data > 0 then
                        self.lb_noSearch:setVisible(false)
                        self:updataTable(s_data)
                    else
                        self.m_tableView:reload({})
                        self.lb_noSearch:setVisible(true)
                    end
                end
            end
        end
    end)
end

function FirendMainLayer:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(sender, _type)
            if _type and _type == "first" then
                self.ManGer:requestAddFriendList(_type)
            end
            self.m_data = G_GetMgr(G_REF.Friend):getData()
            self.friends_number:setString(self.m_data:getCourentCount().."/"..self.m_data:getMaxCount())
            self.friend_data = self.m_data:getFriendAllList()
            self:updataTable(self.friend_data)
            self:serchName()
            self.friends_number:setVisible(true)
            self.sp_num_icon:setVisible(true)
        end,
        FriendConfig.EVENT_NAME.FRIEND_ALL_LIST
    )
    gLobalNoticManager:addObserver(
        self,
        function(sender, _num)
            self.ManGer:showAddLayer()
        end,
        FriendConfig.EVENT_NAME.COMMOND_LIST
    )
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.num and params.num > 0 then
                self.reddian:setVisible(true)
                self.red_num:setString(params.num)
            else
                self.reddian:setVisible(false)
            end
            if params.type and params.type == "first" then
                self.ManGer:requestFriendCardList("first")
                return
            end
            self.ManGer:showRequstLayer()
        end,
        FriendConfig.EVENT_NAME.REQUEST_FRIEND_LIST
    )
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            local list = self.m_data:getRequestList()
            local _num = #list - 1
            if _num and _num > 0 then
                self.reddian:setVisible(true)
                self.red_num:setString(_num)
            else
                self.reddian:setVisible(false)
            end
            self.ManGer:setLobbyBottomNum(_num)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FRIEND_TIP,_num)
        end,
        FriendConfig.EVENT_NAME.REQUEST_FRIEND
    )

    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(sender, params)
            
    --     end,
    --     FriendConfig.EVENT_NAME.CARD_FRIEND
    -- )

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            local list = self.m_data:getAllCardList()
            local index = 0
            if #list > 0 then
                for i,v in ipairs(list) do
                    if params.cardId == v.id and v.tab == 0 then
                        index = i
                    end
                end
            end
            if index ~= 0 then
                local item = self.m_helptableView:getCellByIndex(index)
                if not item then
                    return
                end
                if params.type == 1 then
                    self:playItem(index,item)
                else
                    item.view:playAction(function()
                        if tolua.isnull(self) then
                            return
                        end
                        self:playItem(index,item)
                    end)
                end
                
            end
        end,
        FriendConfig.EVENT_NAME.CARD_SUCCESS
    )
end

function FirendMainLayer:checkReve()
    local id_list = self.m_data:getReveCardList()
    if id_list and #id_list > 0 then
        self.ManGer:requestSendCard("Receive", nil,"CARD",nil,id_list,handler(self, self.updateReceive))
    end
end

function FirendMainLayer:updateReceive()
    --刷新帮助列表
    local id_list = self.m_data:getReveCardList()
    for i=1,#id_list do
        local item = self.m_helptableView:getCellByIndex(i)
        self:playReveItem(i,item)
    end
end

function FirendMainLayer:playItem(_index,_item)
    if _item then
        util_fadeOutNode(
            _item,
            1,
            function()
                if not tolua.isnull(self) then
                    self.m_helptableView:removeCellAtIndex(_index)
                    local list = self.m_data:getAllCardList()
                    table.remove(list,_index)
                    self.m_data:setAllCardList(list)
                    self:updataHelp(self.m_data:getAllCardList())
                end
            end
        )
    end
end

function FirendMainLayer:playReveItem(_index,_item)
    if _item then
        util_fadeOutNode(
            _item,
            1,
            function()
                if not tolua.isnull(self) then
                    local id_list = self.m_data:getReveCardList()
                    for i=1,#id_list do
                        self.m_helptableView:removeCellAtIndex(1)
                        local list = self.m_data:getAllCardList()
                        table.remove(list,1)
                        self.m_data:setAllCardList(list)
                    end
                    self.m_data:setReveCardList()
                    self:updataHelp(self.m_data:getAllCardList())
                end
            end
        )
    end
end

function FirendMainLayer:updateButton(index)
    for i=1,#self.btn_img do
        if i == index then
            util_changeTexture(self.btn_img[i],FriendConfig.btn_img[1][i])
        else
            util_changeTexture(self.btn_img[i],FriendConfig.btn_img[2][i])
        end
    end
end

function FirendMainLayer:clickStartFunc(sender)
end

function FirendMainLayer:closeUI()
    FirendMainLayer.super.closeUI(self)
end

function FirendMainLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_friends" then
        if self.m_current == 1 then
            return
        end
        gLobalSoundManager:playSound(FriendConfig.Sounds.CUT)
        self.m_current = 1
        self:updateButton(1)
        self.node_frid_main:setVisible(true)
        self.node_help_main:setVisible(false)
        self.node_helptable:setVisible(false)
        self.node_macy_main:setVisible(false)
        self.btn_info:setVisible(false)
    elseif name == "btn_help" then
        if self.m_current == 2 then
            return
        end
        gLobalSoundManager:playSound(FriendConfig.Sounds.CUT)
        self.m_current = 2
        self:updateButton(2)
        self.node_frid_main:setVisible(false)
        self.node_help_main:setVisible(true)
        self.node_helptable:setVisible(true)
        self.node_macy_main:setVisible(false)
        self.btn_info:setVisible(false)
        local m_list = self.m_data:getAllCardList()
        self:updataHelp(m_list)
    elseif name == "btn_level" then
        if self.m_current == 3 then
            return
        end
        gLobalSoundManager:playSound(FriendConfig.Sounds.CUT)
        self.m_current = 3
        self:updateButton(3)
        self.node_frid_main:setVisible(false)
        self.node_help_main:setVisible(false)
        self.node_helptable:setVisible(true)
        self.node_macy_main:setVisible(true)
        self.btn_info:setVisible(true)
        self.macy_data = self.m_data:getMacyList()
        self:updataMacy(self.macy_data)
    elseif name == "btn_add" then
        --添加好友
        self.ManGer:getCommondList()
    elseif name == "btn_request" then
        --好友请求列表
        self.ManGer:requestAddFriendList()
    elseif name == "btn_info" then
        self.ManGer:showRulesLayer()
    elseif name == "btn_del" then
        --搜索删除
        self.m_eboxSearch:setText("")
        self.spPlaceHolder:setVisible(true)
        self:updataTable(self.friend_data)
        self.lb_noSearch:setVisible(false)
        self.btn_sdel:setVisible(false)
    end
end

return FirendMainLayer