--好友主界面
local FirendAddLayer = class("FirendAddLayer", BaseLayer)
local SensitiveWordParser = util_require("utils.sensitive.SensitiveWordParser")

function FirendAddLayer:ctor()
    FirendAddLayer.super.ctor(self)
    self:setLandscapeCsbName("Friends/csd/Activity_Friends_AddMain.csb")
    self.ManGer = G_GetMgr(G_REF.Friend)
    self.m_data = G_GetMgr(G_REF.Friend):getData()
end

function FirendAddLayer:initCsbNodes()
    self.ser_node = self:findChild("node_serch")
    self.listView = self:findChild("ListView")
    self.m_lb_serc = self:findChild("lb_serc")
    self.m_lb_sercempty = self:findChild("lb_sercempty")
    self.m_lb_title = self:findChild("lb_title")
    self.btn_sdel = self:findChild("btn_back")
    self.m_addbtn = self:findChild("btn_add")
end

function FirendAddLayer:initView()
    self.btn_sdel:setVisible(false)
    self:updataListView(self.m_data:getCommondList())
    self.node_action = util_createAnimation("Friends/csd/Activity_Friends_AddMain_recommended.csb")
    self.ser_node:addChild(self.node_action)
    self.ser_frame = self.node_action:findChild("node_frame")
    self.ser_name = self.node_action:findChild("lb_name")
    self.ser_level = self.node_action:findChild("lb_level")
    self.btn_request = self.node_action:findChild("btn_request")
    local btn_profile = self.node_action:findChild("btn_prol")
    local lb_quest = util_getChildByName(self.btn_request,"label_1")
    lb_quest:setString("ADD")
    --self:addClick(self.btn_request)
    self.btn_request:setVisible(false)
    self:addClick(btn_profile)
    self:serchName()
    self.m_addbtn:setVisible(false)
end

function FirendAddLayer:updataListView(_data)
    self.listView:removeAllChildren()
    for i,v in ipairs(_data) do
        local view = util_createView("views.FirendCode.FirendAddCell")
        local size = view:getItemSize()
        view:updataCell(v)
        local layout = ccui.Layout:create()
        layout:setContentSize({width = size.width, height = size.height})
        view:setPosition(size.width/2+7,size.height/2-5)
        layout:addChild(view)
        self.listView:pushBackCustomItem(layout)
    end
end

function FirendAddLayer:serchName()
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
                if content and content ~= "" then
                    self.ManGer:requestSerchList(content)
                else
                    self:updataSerchNode()
                end
            end
        end
    end)
end

function FirendAddLayer:updataSerchNode(_data)
    if _data and _data[1] then
        self.m_lb_serc:setVisible(true)
        self.m_lb_sercempty:setVisible(true)
        self.m_lb_title:setPositionY(19)
        self.listView:setPositionY(288)
        self.m_addbtn:setVisible(true)
        local m_isf = self.ManGer:getIsMyFriend(_data[1].udid)
        self.m_contentdata = _data[1]
        self.ser_frame:removeAllChildren()
        self.ser_name:setString(_data[1].name)
        self.ser_level:setString("LEVEL:".._data[1].level)
        local head_node = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(
            _data[1].facebookId, 
            _data[1].head, 
            _data[1].headFrame, 
            nil,
            cc.size(100,100))
        if head_node then
            self.ser_frame:addChild(head_node)
        end
        if m_isf then
            self.m_addbtn:setVisible(false)
            self.btn_request:setTouchEnabled(false)
            self.node_action:playAction("over",true)
        else
            self.btn_request:setTouchEnabled(true)
            self.node_action:playAction("idle",true,nil)
        end
        self.ser_node:setVisible(true)
        self.listView:setContentSize(985,300)
    else
        self.ser_node:setVisible(false)
        self.m_addbtn:setVisible(false)
        if not _data then
            self.m_lb_serc:setVisible(false)
            self.m_lb_sercempty:setVisible(false)
            self.m_lb_title:setPositionY(178)
            self.listView:setContentSize(985,448)
            self.listView:setPositionY(448)
        else
            self.m_lb_serc:setVisible(true)
            self.m_lb_sercempty:setVisible(true)
            self.m_lb_title:setPositionY(19)
            self.listView:setContentSize(985,300)
            self.listView:setPositionY(288)
        end
        
    end
    self:updataListView(self.m_data:getCommondList())
    self.listView:jumpToTop() 
end

function FirendAddLayer:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(sender, _num)
            self:updataSerchNode(self.m_data:getSerchList())
        end,
        FriendConfig.EVENT_NAME.ADD_SERCH_LIST
    )
    gLobalNoticManager:addObserver(
        self,
        function(sender, _num)
            if not _num then
                return
            end
            self.btn_request:setTouchEnabled(false)
            if self.ManGer:getAdduid() == self.m_contentdata.udid then
                self.m_addbtn:setVisible(false)
                self.btn_request:setVisible(true)
                gLobalSoundManager:playSound(FriendConfig.Sounds.CUT_BTN)
                self.node_action:playAction("start",false,function()
                    self.node_action:playAction("over",true)
                end)
            end
        end,
        FriendConfig.EVENT_NAME.ADD_SERCH_SUCCESS
    )
end

function FirendAddLayer:clickStartFunc(sender)
end

function FirendAddLayer:closeUI()
    FirendAddLayer.super.closeUI(self)
end

function FirendAddLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_prol" then
        --查看个人信息
        G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.m_contentdata.udid, "","",self.m_contentdata.head)
    elseif name == "btn_add" then
        --添加好友请求
        if self.ManGer:getAddStuts() == 0 then
            self.ManGer:setAddStuts(1)
            self.ManGer:setAdduid(self.m_contentdata.udid)
            self.ManGer:requestAddFriend("Apply",self.m_contentdata.udid,"Serch","2")
        end
    elseif name == "btn_back" then
        self.m_eboxSearch:setText("")
        self.spPlaceHolder:setVisible(true)
        self.btn_sdel:setVisible(false)
        self:updataSerchNode()
    end
end

return FirendAddLayer