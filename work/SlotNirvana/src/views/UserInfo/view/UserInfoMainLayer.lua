--个人信息界面
local BaseRotateLayer = util_require("base.BaseRotateLayer")
local UserInfoMainLayer = class("UserInfoMainLayer", BaseRotateLayer)
function UserInfoMainLayer:ctor()
    UserInfoMainLayer.super.ctor(self)
    self:setExtendData("UserInfoMainLayer")
    self:setLandscapeCsbName("Activity/csd/Information/Iformation_mainUI.csb")
    self.ManGer = G_GetMgr(G_REF.UserInfo)
    self.config = G_GetMgr(G_REF.UserInfo):getConfig()
    if globalData.slotRunData.isPortrait == true then
        self:setShowBgOpacity(250)
    end
end

function UserInfoMainLayer:initCsbNodes()
    -- body
    self.txt_id = self:findChild("txt_id")
    self.txt_name = self:findChild("txt_name")
    self.txt_level = self:findChild("txt_desc")
    self.txt_leveGao = self:findChild("txt_descGao")
    self.proess = self:findChild("img_progress")
    self.proess_Gao = self:findChild("img_proGao")
    self.scrollView = self:findChild("ListView")
    self.head_img = self:findChild("node_frame")
    self.node_avter = self:findChild("node_avter")
    self.m_progressLevel = self:findChild("grade_lodingbar")
    self.m_progressGBC = self:findChild("gaobei_lodingbar")
    self.sp_kuang = self:findChild("sp_kuang")
    self.btn_name = self:findChild("btn_name")
    self.m_effectG = self:findChild("effect1")
    self.m_effect = self:findChild("effct")
    self.m_node_birthday = self:findChild("node_birthday")
end

function UserInfoMainLayer:initView()
    self:runCsbAction(
        "idle",
        true,
        function()
        end,
        120
    )
    local size = self.m_effect:getContentSize()
    self.ManGer:addDefultItem(self:findChild("node_me"),1)
    self:setTextName(globalData.userRunData.nickName)
    self.txt_id:setString("ID:" .. globalData.userRunData.loginUserData.displayUid)
    self.txt_level:setString(globalData.userRunData.levelNum)
    local currProVal = globalData.userRunData.currLevelExper
    local totalProVal = globalData.userRunData:getPassLevelNeedExperienceVal()
    local floatLevelPercent = currProVal / totalProVal
    floatLevelPercent = floatLevelPercent > 1 and 1 or floatLevelPercent
    self.m_progressLevel:setPercent(math.floor(floatLevelPercent * 100))
    local width = size.width * floatLevelPercent
    self.m_effect:setContentSize(cc.size(width,size.height))
    local deluexeCurrPoint = globalData.deluexeClubData.p_currPoint
    local deluextTotalPoint = globalData.constantData.CLUB_OPEN_POINTS
    local floatDelPercent = deluexeCurrPoint / deluextTotalPoint
    floatDelPercent = floatDelPercent > 1 and 1 or floatDelPercent
    width = size.width * floatDelPercent
    self.m_effectG:setContentSize(cc.size(width,size.height))
    self.txt_leveGao:setString(deluexeCurrPoint .. "/" .. deluextTotalPoint)
    self.m_progressGBC:setPercent(math.floor(floatDelPercent * 100))
end

function UserInfoMainLayer:updataScrollSize()
    local nums = 0
    if G_GetMgr(G_REF.Invite) and G_GetMgr(G_REF.Invite):getData() then
        local data = G_GetMgr(G_REF.Invite):getData()
        local t = G_GetMgr(G_REF.Invite):getInviteeVs()
        if data:getInviteeReward() ~= nil and t then
            nums = nums + 1
        end
        if globalData.userRunData.levelNum >= globalData.constantData.INVITE_LEVEL and data:getInviterReward() ~= nil and data:getInviterReward().inviteNum ~= nil then
            nums = nums + 1
        end
    end
    if nums == 0 then
        self.scroll_height = 1160
    elseif nums == 1 then
        self.scroll_height = 1270
    elseif nums == 2 then
        self.scroll_height = 1380
    end
end

function UserInfoMainLayer:initScrollView()
   
    self.scrollView:setScrollBarEnabled(false)
    self.scrollView:setInnerContainerSize(cc.size(657,self.scroll_height-220))
    local size = self.scrollView:getInnerContainerSize()
    if self:checkCanShowTrophyView() then
        self.firstItem = util_createView("views.UserInfo.view.UserInfoFirstItemWithTrophyView")
    else
        self.firstItem = util_createView("views.UserInfo.view.UserInfoFirstItem")
    end
    local pos_y = size.height - 530/2 + 100
    local worldPos = self.scrollView:convertToWorldSpace(cc.p(0, 0))
    local pos_x = (size.width/2)+175+(worldPos.x-604)
    self.firstItem:setPosition(pos_x,pos_y)
    self.scrollView:addChild(self.firstItem)

    self.twoItem = util_createView("views.UserInfo.view.UserInfoTwoItem")
    pos_y = size.height - 626
    self.twoItem:setPosition(pos_x,pos_y)
    self.scrollView:addChild(self.twoItem)
    self:updataAvter()
    self:updataHead()
end

function UserInfoMainLayer:updataAvter()
    local head_old = self.node_avter:getChildByName("head_avatarFrameId")
    if head_old ~= nil and not tolua.isnull(head_old) then
        self.node_avter:removeAllChildren()
    end
    self.sp_kuang:setVisible(true)
    if not globalData.userRunData.avatarFrameId or globalData.userRunData.avatarFrameId == "" then
        return
    end
    local avatarFrameId = tonumber(globalData.userRunData.avatarFrameId or 1)
    local head_sprite = G_GetMgr(G_REF.AvatarFrame):createAvatarFrameNode(avatarFrameId,true)
    if not head_sprite then
        return
    end 
    self.sp_kuang:setVisible(false)
    head_sprite:setContentSize(cc.size(160,160))
    head_sprite:setScale(0.66)
    self.node_avter:addChild(head_sprite)
    head_sprite:setName("head_avatarFrameId")
end

function UserInfoMainLayer:updataHead()
    local head_old = self.head_img:getChildByName("head_Uid")
    if head_old ~= nil and not tolua.isnull(head_old) then
        self.head_img:removeChildByName("head_Uid")
    end
    local headId = tonumber(globalData.userRunData.HeadName or 1)
    if gLobalSendDataManager:getIsFbLogin() then
        -- self.txt_name:setString(globalData.userRunData.fbName)
        -- util_scaleCoinLabGameLayerFromBgWidth(self.txt_name, 255)
        local head_sprite = G_GetMgr(G_REF.Avatar):createAvatarClipNode(globalData.userRunData.facebookBindingID, headId, nil, false, cc.size(150,150), true)
        self.head_img:addChild(head_sprite)
        head_sprite:setName("head_Uid")
    else
        local head_sprite = G_GetMgr(G_REF.Avatar):createAvatarClipNode(nil, headId, nil, false, cc.size(150,150), false)
        self.head_img:addChild(head_sprite)
        head_sprite:setName("head_Uid")
    end
end

function UserInfoMainLayer:setTextName(strName)
    strName = strName or ""
    self.txt_name:setString(strName)
    util_scaleCoinLabGameLayerFromBgWidth(self.txt_name, 255)
    -- local len = string.len(strName)
    local width = self.txt_name:getContentSize().width
    local pos_C = width/2 - 260
    if pos_C > -132 then
        pos_C = -132
    end
    self.btn_name:setPositionX(pos_C)
end

function UserInfoMainLayer:initBirthdayEditNode()
    -- 集卡新手期
    local isNovice = CardSysManager:isNovice()
    if self.m_node_birthday and not isNovice then
        local node = util_createView("views.UserInfo.view.UserInfoBirthdayEditNode")
        self.m_node_birthday:addChild(node)
        self.m_birthdayEditNode = node
    end
end

function UserInfoMainLayer:registerListener()
    UserInfoMainLayer.super.registerListener(self)
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(self, _bGoGameScene)
    --         self:closeUI()
    --     end,
    --     self.config.ViewEventType.MAIN_CLOSE
    -- )
    gLobalNoticManager:addObserver(
        self,
        function(self, _index)
            --刷新下名字
            self:setTextName(globalData.userRunData.nickName)
            self:updataAvter()
            self:updataHead()
        end,
        self.config.ViewEventType.NOTIFY_USERINFO_MODIFY_SUCC
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, _index)
            self:setTabNode(_index)
        end,
        self.config.ViewEventType.MAIN_IN
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, _type)
            local size = self.scrollView:getInnerContainerSize()
            if _type == 1 then
                self.scrollView:setInnerContainerSize(cc.size(size.width,self.scroll_height))
            else
                self.scrollView:setInnerContainerSize(cc.size(size.width,self.scroll_height-220))
            end
            self:setItemPos()
        end,
        self.config.ViewEventType.MAIN_HASTIORY
    )
    gLobalNoticManager:addObserver(
        self,
        function(Target, loginInfo)
            self:checkFBLoginState(loginInfo)
        end,
        GlobalEvent.FB_LoginStatus,
        true
    )
    gLobalNoticManager:addObserver(
        self,
        function(Target, loginState)
            self:fbLoginout(loginState)
        end,
        GlobalEvent.FB_LogoutStatus,
        true
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, _index)
            self:updataScrollSize()
            local size = self.scrollView:getInnerContainerSize()
            self.scrollView:setInnerContainerSize(cc.size(size.width,self.scroll_height-220))
            self:setItemPos(1)
        end,
        ViewEventType.NOTIFY_ACTIVITY_INVITE_MAIN
    )
    -- 头像框资源下载结束
    gLobalNoticManager:addObserver(
        self, 
        function()
            self:updataAvter()
        end, 
        ViewEventType.NOTIFY_AVATAR_FRME_RES_DOWNLOAD_COMPLETE
    )
    --头像卡到期卸下自己的头像框
    gLobalNoticManager:addObserver(self, function()
        if tonumber(globalData.userRunData.avatarFrameId) == nil then
            local head_old = self.node_avter:getChildByName("head_avatarFrameId")
            if head_old ~= nil and not tolua.isnull(head_old) then
                self.node_avter:removeAllChildren()
            end
            self.sp_kuang:setVisible(true)
        end
    end, ViewEventType.NOTIFY_AVATAR_TAKEOFF_SELF_FRAME_UI) 
end

function UserInfoMainLayer:checkFBLoginState(loginInfo)
    local platform = device.platform
    local supportVersion = nil
    if platform == "ios" then
        supportVersion = "1.6.6"
    elseif platform == "android" then
        supportVersion = "1.5.8"
    end

    if supportVersion ~= nil and util_isSupportVersion(supportVersion) then
        local loginState = loginInfo.state
        local msg = loginInfo.message
        --成功
        if loginState == 1 then
            --取消
            self:setTextName(globalData.userRunData.fbName)
            self:updataHead()
        elseif loginState == 0 then
            --失败
        else
        end
    else
        if loginInfo then
            self:setTextName(globalData.userRunData.fbName)
            self:updataHead()
        end
    end
end

function UserInfoMainLayer:fbLoginout(loginState)
    local platform = device.platform
    local supportVersion = nil
    if platform == "ios" then
        supportVersion = "1.6.6"
    elseif platform == "android" then
        supportVersion = "1.5.8"
    end

    gLobalViewManager:removeLoadingAnima()
    if supportVersion ~= nil and util_isSupportVersion(supportVersion) then
    else
        if loginState then
            self:setTextName(globalData.userRunData.nickName)

            self:updataHead()
        else
            release_print("xcyy :FB logout失败 ！！！")
        end
    end
end

function UserInfoMainLayer:setItemPos(_type)
    local size = self.scrollView:getInnerContainerSize()
    local pos_y = size.height - 530/2 + 100
    local worldPos = self.scrollView:convertToWorldSpace(cc.p(0, 0))
    self.firstItem:setPositionY(pos_y)
    pos_y = size.height - 626
    self.twoItem:setPositionY(pos_y)
    if not _type then
        self.scrollView:jumpToPercentVertical(60)
    end 
end

function UserInfoMainLayer:setButtonImage(defult)
    local path = "Activity/img/Information/"
    for i=1,4 do
        local btn_bg = self:findChild("sp_pages"..i)
        local btn_text = self:findChild("sp_desc"..i)
        if defult == i then
            util_changeTexture(btn_bg,path.."Information_pages2.png")
            util_changeTexture(btn_text,path..self.config.BtnPath[i])
        else
            util_changeTexture(btn_bg,path.."Information_pages1.png")
            util_changeTexture(btn_text,path..self.config.BtnPath[i+4])
        end
    end
end

function UserInfoMainLayer:closeUI()
    self.ManGer:reset()
    local cb = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_USERINFO_CLOSE_MAINLAYER)
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
    UserInfoMainLayer.super.closeUI(self, cb)
end

function UserInfoMainLayer:clickStartFunc(sender)
end

function UserInfoMainLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        if self.ManGer:getNewStatus() then
            self.ManGer:setIsNew()
        end
        self:closeUI()
    elseif name == "btn_me" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:setButtonImage(self.config.ItmeTag.ITEM_ME)
        self.ManGer:setItemVisible(self.config.ItmeTag.ITEM_ME)
        if self.ManGer:getNewStatus() then
            self.ManGer:setIsNew()
        end
    elseif name == "btn_person" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:setTabNode(self.config.ItmeTag.PERSON)
    elseif name == "btn_solt" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:setTabNode(self.config.ItmeTag.SOLT)
        if self.ManGer:getNewStatus() then
            self.ManGer:setIsNew()
        end
    elseif name == "btn_bg" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
       self:setTabNode(self.config.ItmeTag.BG)
       if self.ManGer:getNewStatus() then
            self.ManGer:setIsNew()
        end
    elseif name == "btn_name" then
        self.ManGer:showEditNameLayer()
    elseif name == "btn_mainhead" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:setTabNode(self.config.ItmeTag.PERSON)
    end
end

function UserInfoMainLayer:setTabNode(tg)
    local middle = self:findChild("node_middle")
    local worldPos = middle:convertToWorldSpace(cc.p(0, 0))
    local dis_posx = worldPos.x-684
    if tg == self.config.ItmeTag.PERSON then
        self:setButtonImage(self.config.ItmeTag.PERSON)
        local node = self.ManGer:setItemVisible(self.config.ItmeTag.PERSON)
        if not node then
            node = util_createView("views.UserInfo.view.UserInfoFrame")
            local pos_x = 229.5+dis_posx
            local pos_y = 110.5
            node:setPosition(pos_x,pos_y)
            middle:addChild(node)
            self.ManGer:addDefultItem(node,self.config.ItmeTag.PERSON)
        end
    elseif tg == self.config.ItmeTag.SOLT then
        self:setButtonImage(self.config.ItmeTag.SOLT)
        local node = self.ManGer:setItemVisible(self.config.ItmeTag.SOLT)
        if not node then
            node = util_createView("views.UserInfo.view.UserInfoCash")
            local pos_x = 215+dis_posx
            local pos_y = 50
            node:setPosition(pos_x,pos_y)
            middle:addChild(node)
            self.ManGer:addDefultItem(node,self.config.ItmeTag.SOLT)
        end
    elseif tg == self.config.ItmeTag.BG then
        self:setButtonImage(self.config.ItmeTag.BG)
        local node = self.ManGer:setItemVisible(self.config.ItmeTag.BG)
        if not node then
            node = util_createView("views.UserInfo.view.UserInfoBag")
            local pos_x = 240+dis_posx
            local pos_y = 102
            node:setPosition(pos_x,pos_y)
            middle:addChild(node)
            self.ManGer:addDefultItem(node,self.config.ItmeTag.BG)
        end
    end
end

function UserInfoMainLayer:onEnter()
    UserInfoMainLayer.super.onEnter(self)
    self.ManGer:setGoInUserInfoMainLayer(true)
    self.ManGer:sendUserBagInfoReq()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    if G_GetMgr(G_REF.Invite) and G_GetMgr(G_REF.Invite):getData() then
        G_GetMgr(G_REF.Invite):sendDataReq()
    end
end

function UserInfoMainLayer:onEnterFinish()
    UserInfoMainLayer.super.onEnterFinish(self)
    self:updataScrollSize()
    self:initScrollView()
    self:updataHead()
    self.ManGer:setRecomdGames()
    self:initBirthdayEditNode() -- 初始化生日编辑节点
end

-- 监测是否显示 奖杯界面
function UserInfoMainLayer:checkCanShowTrophyView()
    local list = {}
    local trophyData = globalData.userRunData:getLeagueTrophyData()
    if trophyData then
        list = trophyData:getTrophyList()
    end
    
    return #list == 3
end

return UserInfoMainLayer
