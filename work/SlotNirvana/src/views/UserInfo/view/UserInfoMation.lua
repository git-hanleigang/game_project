--查看个人信息界面
local UserInfoMation = class("UserInfoMation", BaseLayer)
function UserInfoMation:ctor(params)
    UserInfoMation.super.ctor(self)
    self.data = params
    self:setExtendData("UserInfoMation")
    self:setLandscapeCsbName("Activity/csd/Information_Check/Information_Check_mainUI.csb")
    self.ManGer = G_GetMgr(G_REF.UserInfo)
    self.config = G_GetMgr(G_REF.UserInfo):getConfig()
end

function UserInfoMation:initCsbNodes()
    -- body
    self.txt_id = self:findChild("txt_id")
    self.txt_name = self:findChild("txt_name")
    self.txt_level = self:findChild("txt_level1")
    self.head_img = self:findChild("node_frame")
    self.node_avter = self:findChild("node_avter")
    self.sp_kuang = self:findChild("sp_kuang")
    self.lb_fdesc = self:findChild("lb_fdesc")
    self.node_btn = self:findChild("node_btn")
    self.sp_label = self:findChild("sp_label")
    self.m_btn_add = self:findChild("btn_add")
end

function UserInfoMation:initView()
    self:setTextName(self.data.nickName)
    self.txt_id:setString("ID:" .. self.data.id)
    self.txt_level:setString(self.data.level)
    self:updataAvter()
    self:updataHistory()
    self:updataVip()
    self:updataTeam()
    self:updataSession()
    self:updataFrame()
    self:updataFriend()
end

function UserInfoMation:updataAvter()
    if self.data.frame and self.data.frame ~= "" then
        self.sp_kuang:setVisible(false)
    end
    self.sp_kuang:setScale(0.51)
    local size = cc.size(112,112)
    if self.data and self.data.facebookId ~= nil then
        self.data.fbId = self.data.facebookId
    end
    local node = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(
        self.data.fbId, 
        self.data.head, 
        self.data.frame, 
        self.data.robot,
        size)
    self.node_avter:addChild(node)
end

function UserInfoMation:updataHistory()
    local time = self:findChild("txt_desc6")
    time:setString(self.data.register)
    local totalspin = self:findChild("txt_desc7")
    local bigMultiple = self:findChild("txt_desc8")
    local bigwin = self:findChild("txt_desc9")
    totalspin:setString(self.data.spinTimesTotal or 0)
    bigMultiple:setString(self.data.maximumWinMultiple or 0)
    local mix = 0
    if self.data.maximumWin then
        mix = util_formatCoins(tonumber(self.data.maximumWin),12)
    end
    bigwin:setString(mix)
    local bigwint = self:findChild("txt_desc10")
    local megawin = self:findChild("txt_desc11")
    local epicwin = self:findChild("txt_desc12")
    local jackpot = self:findChild("txt_desc13")
    local legendwin = self:findChild("txt_desc14")
    if legendwin then
        legendwin:setString(self.data.legendaryWinTimesTotal or 0)
    end
    bigwint:setString(self.data.bigWinTimesTotal)
    megawin:setString(self.data.megaWinTimesTotal)
    epicwin:setString(self.data.epicWinTimesTotal)
    jackpot:setString(self.data.jackpotTimes)
end

function UserInfoMation:updataVip()
    local vip_level = self:findChild("txt_vipdesc")
    local vip_bg = self:findChild("img_vipbg")
    if self.data.vipLevel then
        local cfg = VipConfig.LISTVIEW_CONFIG[self.data.vipLevel]
        vip_level:setString(cfg and cfg.name or "")
        local path = "Activity/img/Information/Iformation_vip/Iformation_vip"..self.data.vipLevel..".png"
        util_changeTexture(vip_bg, path)
    end
end

function UserInfoMation:updataTeam()
    local team = self:findChild("txt_teamdesc")
    team:setString(self.data.cname)
    local team_bg = self:findChild("img_teambg")
    local _iconName = 1
    if self.data.chead then
        _iconName = tonumber(self.data.chead) + 1
    end
    if tonumber(_iconName) > 25 then
        _iconName = 26
    end
    local path = "Activity/img/Information/Iformation_team/Iformation_team".._iconName..".png"
    util_changeTexture(team_bg, path)
end

function UserInfoMation:updataSession()
    local openLevel = globalData.constantData.LEAGUE_OPEN_LEVEL or 35
    local unlock_session = self:findChild("txtsn_unlock_tip")
    unlock_session:setVisible(false)
    local txt_sectiondesc = self:findChild("txt_sectiondesc")
    if self.data.league and self.data.league >= 1 then
        txt_sectiondesc:setString(self.config.SessionIconName[self.data.league])
        local img_sessionbg = self:findChild("img_sessionbg")
        local path = "Activity/img/Information/Iformation_section/Iformation_section"..self.data.league..".png"
        util_changeTexture(img_sessionbg,path)
    end
end

function UserInfoMation:updataFriend()
    self.m_btn_add:setVisible(false)
    if G_GetMgr(G_REF.Friend) and G_GetMgr(G_REF.Friend):getData() then
        self.friend_data = G_GetMgr(G_REF.Friend):getData():getFriendAllList()
        if #self.friend_data > 0 then
            local index = 0
            for i,v in ipairs(self.friend_data) do
                if v.p_udid == self.data.udid then
                    index = v.p_friendlinessLevel
                end
            end
            if index == 0 then
                self:addLayer()
            else
                util_changeTexture(self.sp_label,FriendConfig.macy_img[index])
                self.sp_label:setVisible(true)
            end
        else
            self:addLayer()
        end
    end
end

function UserInfoMation:addLayer()
    self.m_btn_add:setVisible(true)
    self.node_action = util_createAnimation("Activity/csd/Information/Iformation_friend_add.csb")
    self.btn_profile = self.node_action:findChild("btn_add")
    local lb_quest = util_getChildByName(self.btn_profile,"label_1")
    lb_quest:setString("ADD FRIEND")
    self.btn_profile:setVisible(false)
    self.node_btn:addChild(self.node_action)
end

function UserInfoMation:setTextName(name)
    self.txt_name:setString(name)
    util_scaleCoinLabGameLayerFromBgWidth(self.txt_name, 255)
end

function UserInfoMation:updataFrame()
    local num = 0
    if self.data.collectionNum then
        num = self.data.collectionNum
    end
    local all_cf = self.ManGer:getCfAllList()
    local str = ""
    if all_cf then
        str = num.."/"..#all_cf
    end
    self.lb_fdesc:setString(str)
    if self.data.favoriteFrame and #self.data.favoriteFrame > 0 then
        for i,v in ipairs(self.data.favoriteFrame) do
            if i > 3 then
                return
            end
            local node = self:findChild("node_raward"..i)
            local head_sprite = G_GetMgr(G_REF.AvatarFrame):createAvatarFrameNode(tonumber(v))
            if head_sprite then
                head_sprite:setScale(0.3)
                node:addChild(head_sprite)
            end
        end
    end
end

function UserInfoMation:closeUI()
    if self.m_bClose then
        return
    end
    self.m_bClose = true
    UserInfoMation.super.closeUI(self)
end

function UserInfoMation:clickStartFunc(sender)
end

function UserInfoMation:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_add" then
        self.m_btn_add:setVisible(false)
        self.btn_profile:setVisible(true)
        G_GetMgr(G_REF.Friend):requestAddFriend("Apply",self.data.udid,nil,"1")
        self.node_action:playAction("start",false,nil)
        self.btn_profile:setTouchEnabled(false)
    end
end

function UserInfoMation:onEnter()
    UserInfoMation.super.onEnter(self)
end


return UserInfoMation
