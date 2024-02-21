local UserInfoFirstItemWithTrophyView = class("UserInfoFirstItemWithTrophyView", BaseLayer)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function UserInfoFirstItemWithTrophyView:ctor()
    UserInfoFirstItemWithTrophyView.super.ctor(self)
    self:setExtendData("UserInfoFirstItemWithTrophyView")
    self:setLandscapeCsbName("Activity/csd/Information/Iformation_Zong/Iformation_zong_with_trophy.csb")
    self.ManGer = G_GetMgr(G_REF.UserInfo)
    self.config = G_GetMgr(G_REF.UserInfo):getConfig()
    self:setShowActionEnabled(false)
    self:setMaskEnabled(false)
end

-- 初始化节点
function UserInfoFirstItemWithTrophyView:initCsbNodes()
    local btn_vip = self:findChild("btn_vip")
    btn_vip:setSwallowTouches(false)
    self.btn_section = self:findChild("btn_section")
    self.btn_section:setSwallowTouches(false)
    self.btn_team = self:findChild("btn_team")
    self.btn_team:setSwallowTouches(false)
    local btn_fram = self:findChild("btn_fram")
    btn_fram:setSwallowTouches(false)
    local btn_record = self:findChild("btn_record")
    btn_record:setSwallowTouches(false)
    local btn_avp = self:findChild("btn_jiahao1")
    btn_avp:setSwallowTouches(false)
    local btn_avp1 = self:findChild("btn_jiahao2")
    btn_avp1:setSwallowTouches(false)
    local btn_avp2 = self:findChild("btn_jiahao3")
    btn_avp2:setSwallowTouches(false)
    self.vip_level = self:findChild("txt_vipdesc")
    self.my_team = self:findChild("txt_teamdesc")
    self.vip_bg = self:findChild("img_vipbg")
    self.my_teambg = self:findChild("img_teambg")
    self.jian_s  = self:findChild("sp_arrow")
    self.jian_x  = self:findChild("sp_arrow2")
    self.jian_x:setVisible(false)
    self.show_txt = self:findChild("txt_show")
    self.node_record_show = self:findChild("node_record_show")
    self.unlock_team = self:findChild("txt_unlock_tip")
    self.unlock_session = self:findChild("txtsn_unlock_tip")
    self.m_nodeFrame = self:findChild("node_frame") -- 头像框 节点
end

function UserInfoFirstItemWithTrophyView:initView()
    self:addClickSound({"btn_record"}, SOUND_ENUM.MUSIC_BTN_CLICK)

    self.hsi_type = 1
    self:updataVip()
    self:updataTeam()
    self:updataFrame()
    self:updataSession()
    self:updataHistory()
    self:updateLeagueTrophy()
    self:setShowTag(1)
end

function UserInfoFirstItemWithTrophyView:updataHistory()
    local time = self:findChild("txt_desc6")
    local time_str = os.date("%Y-%m-%d", tonumber(globalData.userRunData.createTime / 1000))
    time:setString(time_str)
    local data = G_GetMgr(G_REF.AvatarFrame):getData():getStatsData()
    if not data then
        return
    end
    local newdata = self.ManGer:getHistory()
    if newdata and newdata.m_spinTimesTotal then
        data = newdata
    end
    local totalspin = self:findChild("txt_desc7")
    local bigMultiple = self:findChild("txt_desc8")
    local bigwin = self:findChild("txt_desc9")
    local bigwint = self:findChild("txt_desc10")
    local megawin = self:findChild("txt_desc11")
    local epicwin = self:findChild("txt_desc12")
    local jackpot = self:findChild("txt_desc13")
    local legendwin = self:findChild("txt_desc14")
    if legendwin then
        legendwin:setString(data.m_legendaryWinTimesTotal or 0)
    end
    totalspin:setString(data.m_spinTimesTotal or 0)
    bigMultiple:setString(data.m_maximumWinMultiple or 0)
    local mix = 0
    if data.m_maximumWin then
        mix = util_formatCoins(tonumber(data.m_maximumWin),12)
    end
    bigwin:setString(mix)
    bigwint:setString(data.m_bigwin)
    megawin:setString(data.m_megawin)
    epicwin:setString(data.m_epicwin)
    jackpot:setString(data.m_jackpot)
end

function UserInfoFirstItemWithTrophyView:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updataVip()
        end,
        ViewEventType.NOTIFY_UPDATE_VIP
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updataVip()
        end,
        ViewEventType.NOTIFY_UPDATE_BAR
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updataFrame()
        end,
        self.config.ViewEventType.FRAME_LIKE_SELECT
    )  
    --头像卡到期卸下自己的头像框
    gLobalNoticManager:addObserver(
        self, 
        function(self, params)
            self:updataFrame()
        end, 
        ViewEventType.NOTIFY_AVATAR_TAKEOFF_SELF_FRAME_UI
    )
end

function UserInfoFirstItemWithTrophyView:updataVip()
    local vip = self.ManGer:getVipLevel()
    local cfg = VipConfig.LISTVIEW_CONFIG[vip]
    self.vip_level:setString(cfg and cfg.name or "")
    local path = "Activity/img/Information/Iformation_vip/Iformation_vip"..vip..".png"
    util_changeTexture(self.vip_bg, path)
end

function UserInfoFirstItemWithTrophyView:updataTeam()
    self.my_team:setString("")
    local clanData = ClanManager:getClanData()
    local unlock = ClanManager:isUnlock()
    self.btn_team:setVisible(unlock)
    self.btn_team:setEnabled(unlock)
    if not unlock then
        local txt = "UNLOCK AT LV" .. globalData.constantData.CLAN_OPEN_LEVEL
        self.my_team:setString(txt)
        return
    end
    if clanData then
        local clanSimpleInfo = clanData:getClanSimpleInfo()
        if clanSimpleInfo and clanSimpleInfo.getTeamName then
            self.my_team:setString(clanSimpleInfo:getTeamName())
        end
        local _iconName = 1
        if clanSimpleInfo and clanSimpleInfo.getTeamLogo then
            _iconName = clanSimpleInfo:getTeamLogo()
            _iconName = tonumber(_iconName) + 1
        end
        if tonumber(_iconName) > 25 then
            _iconName = 26
        end
        
        local path = "Activity/img/Information/Iformation_team/Iformation_team".._iconName..".png"
        util_changeTexture(self.my_teambg, path)
    end
end

function UserInfoFirstItemWithTrophyView:updataFrame()
    local hold_data = G_GetMgr(G_REF.AvatarFrame):getUserHoldFrameTimeList()
    local all_cf = self.ManGer:getCfAllList()
    local lb_fdesc = self:findChild("lb_fdesc")
    local str = #hold_data .."/"..#all_cf
    lb_fdesc:setString(str)
    local frame_data = G_GetMgr(G_REF.AvatarFrame):getUserLikeFrameList()
    if frame_data ~= nil and #frame_data > 0 then
        for i=1,3 do
            local node = self:findChild("node_raward"..i)
            local sp = node:getChildByName("head_rew"..i)
            if sp and not tolua.isnull(sp) then
                node:removeChild(sp)
            end
            local jiahao = self:findChild("btn_jiahao"..i)
            jiahao:setOpacity(255)
            local item = frame_data[i]
            if item then
                jiahao:setOpacity(0)
                local head_sprite = G_GetMgr(G_REF.AvatarFrame):createAvatarFrameNode(tonumber(item))
                head_sprite:setScale(0.3)
                head_sprite:setName("head_rew"..i)
                node:addChild(head_sprite)
            end
        end
    else
        for i=1,3 do
            local node = self:findChild("node_raward"..i)
            local sp = node:getChildByName("head_rew"..i)
            if sp and not tolua.isnull(sp) then
                node:removeChild(sp)
            end
            local jiahao = self:findChild("btn_jiahao"..i)
            jiahao:setOpacity(255)
        end
        local status = G_GetMgr(G_REF.AvatarFrame):getLikeStatus()
        local current_list = self.ManGer:getCurrentFrame()
        local send_data = {}
        if status == 0 and #current_list > 0 then
            for i,v in ipairs(current_list) do
                local node = self:findChild("node_raward"..i)
                local jiahao = self:findChild("btn_jiahao"..i)
                jiahao:setOpacity(0)
                local item = current_list[i]
                if item then
                    table.insert(send_data,item.id)
                    local head_sprite = G_GetMgr(G_REF.AvatarFrame):createAvatarFrameNode(item.id)
                    head_sprite:setScale(0.3)
                    head_sprite:setName("head_rew"..i)
                    node:addChild(head_sprite)
                end
            end
        end
        if status == 0 then
            self.ManGer:sendFrameLikenReq(send_data)
        end 
    end
end

-- 比赛 巅峰赛获得的 奖杯
function UserInfoFirstItemWithTrophyView:updateLeagueTrophy()
    local nodeTrophy = self:findChild("node_trophy")
    local view = util_createView("views.UserInfo.view.UserinfoLeagueTrophyView")
    nodeTrophy:addChild(view, -1)
    self.m_nodeTrophyView = view
end

-- 选择tag09
function UserInfoFirstItemWithTrophyView:setShowTag(_tag)
    self.m_nodeFrame:setVisible(_tag == 1)
    self.m_nodeTrophyView:setVisible(_tag == 2)
end

function UserInfoFirstItemWithTrophyView:updataSession()
    local openLevel = globalData.constantData.LEAGUE_OPEN_LEVEL or 35
    local txt_sectiondesc = self:findChild("txt_sectiondesc")
    self.unlock_session:setString("UNLOCK AT LV"..openLevel)
    self.unlock_session:setVisible(false)
    txt_sectiondesc:setVisible(true)
    self.btn_section:setTouchEnabled(true)
    if globalData.userRunData.levelNum < openLevel then
        self.unlock_session:setVisible(true)
        txt_sectiondesc:setVisible(false)
        self.btn_section:setTouchEnabled(false)
        return
    end
    local data = G_GetMgr(G_REF.LeagueCtrl):getOpenCtrl():getRunningData()
    if data then
        local version = data:getMyDivision()
        if version >= 1 then
            local img_sessionbg = self:findChild("img_sessionbg")
            local path = "Activity/img/Information/Iformation_section/Iformation_section"..version..".png"
            util_changeTexture(img_sessionbg,path)
            txt_sectiondesc:setString(self.config.SessionIconName[version])
        end
    end
end

function UserInfoFirstItemWithTrophyView:clickStartFunc(sender)
end

function UserInfoFirstItemWithTrophyView:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_vip" then
        --vip界面
        local vip = G_GetMgr(G_REF.Vip):showMainLayer()
        -- local vip = util_createView("views.vip.VipView")
        -- gLobalViewManager:showUI(vip, ViewZorder.ZORDER_UI)
    elseif name == "btn_section" then
        --竞技场
        local data = G_GetMgr(G_REF.LeagueCtrl):getOpenCtrl():getRunningData()
        if data then
            local openLevel = globalData.constantData.LEAGUE_OPEN_LEVEL or 35
            if globalData.userRunData.levelNum >= openLevel then
                G_GetMgr(G_REF.LeagueCtrl):getOpenCtrl():showMainLayer()
                --gLobalNoticManager:postNotification(self.config.ViewEventType.MAIN_CLOSE)
            end
        end
    elseif name == "btn_team" then
        --工会
        local currLevel = globalData.userRunData.levelNum
        if currLevel < globalData.constantData.CLAN_REMIND_OPEN_LEVEL then
            return false
        end
        if not globalData.constantData.CLAN_OPEN_SIGN then
            return
        end
        -- 是否支持此版本
        if not ClanManager:checkSupportAppVersion(true) then
            return
        end

        if not ClanManager:isDownLoadRes() then
            return
        end
        ClanManager:enterClanSystem()
        -- gLobalNoticManager:postNotification(self.config.ViewEventType.MAIN_CLOSE)
        G_GetMgr(G_REF.UserInfo):exitGame()
    elseif name == "btn_record" then
        --战绩
        if self.hsi_type == 1 then
            self.show_txt:setString("SHOW LESS")
            self.jian_x:setVisible(true)
            self.jian_s:setVisible(false)
            local move = cc.MoveTo:create(0.2, cc.p(508,420))
            self.node_record_show:runAction(move)
            gLobalNoticManager:postNotification(self.config.ViewEventType.MAIN_HASTIORY,1)
            self.hsi_type = 2
        else
            self.show_txt:setString("SHOW MORE")
            self.jian_x:setVisible(false)
            self.jian_s:setVisible(true)
            local move = cc.MoveTo:create(0.2, cc.p(508,733))
            self.node_record_show:runAction(move)
            gLobalNoticManager:postNotification(self.config.ViewEventType.MAIN_HASTIORY,2)
            self.hsi_type = 1
        end
    elseif name == "btn_fram" then
        --头像
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.ManGer:setFrameItem(2)
        gLobalNoticManager:postNotification(self.config.ViewEventType.MAIN_IN,self.config.ItmeTag.PERSON)
    elseif name == "btn_jiahao1" or name == "btn_jiahao2" or name == "btn_jiahao3" then
        --三个头像展示页
        self.ManGer:showFrameDisy()
    elseif name == "btn_tag_frame" then
        --显示头像框
        self:setShowTag(1)
    elseif name == "btn_tag_trophy" then
        -- 显示比赛 巅峰赛奖杯
        self:setShowTag(2)
    end
end

return UserInfoFirstItemWithTrophyView