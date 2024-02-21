--[[
Author: cxc
Date: 2021-02-02 19:52:02
LastEditTime: 2022-05-26 17:56:33
LastEditors: bogon
Description: 公会home面板 玩家有公会了 进入这
FilePath: /SlotNirvana/src/views/clan/ClanHomeView.lua
--]]
local BaseActivityMainLayer = require("baseActivity.BaseActivityMainLayer")
local ClanHomeView = class("ClanHomeView", BaseActivityMainLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ChatManager = util_require("manager.System.ChatManager"):getInstance()
local ChatConfig = require("data.clanData.ChatConfig")

function ClanHomeView:ctor()
    ClanHomeView.super.ctor(self)
    self.m_bCanReqRank = true
    self.m_bCanReqMember = true
    self.m_clanData = ClanManager:getClanData()
    self:setHideLobbyEnabled(true)
    self:setPauseSlotsEnabled(true)
    self:setKeyBackEnabled(true)
    self:setExtendData("ClanHomeView")
    self:setLandscapeCsbName("Club/csd/Main/ClubMainLayer.csb")
    -- self:setBgm(ClanConfig.MUSIC_ENUM.BG)
    G_GetMgr(ACTIVITY_REF.Zombie):setSpinData(true)
end

function ClanHomeView:initUI(_enterSysType)
    ClanHomeView.super.initUI(self)
 
    -- 没有指定跳转页签的 检查有没有要红包领取
    self.m_bCheckColRedGift = _enterSysType == nil
    self.m_enterSysType = _enterSysType

    -- 背景
    self:initBgUI()

    -- 小红点
    self:readNodes()

    -- 周三公会双倍积分倒计时
    self:initClanDoublePointsUI()

    -- 添加菜单UI
    local btnMenu = self:findChild("btn_menu")
    local view = util_createView("views.clan.ClanMoreMenuLayer")
    local nodeLeftmenu = self:findChild("node_leftmenu")
    view:addTo(nodeLeftmenu)
    view:move(nodeLeftmenu:convertToNodeSpaceAR(btnMenu:convertToWorldSpaceAR(cc.p(util_getBangScreenHeight(), 0))))
    self.m_memuUI = view

    -- 公会基本信息
    self:updateClanBaseInfoUI()
    
    -- 请求下公会成员信息 为了及时刷新小红点
    ClanManager:requestClanApplyList()
    self:updateUI()
end

-- 背景
function ClanHomeView:initBgUI()
    local bgLeft = self:findChild("imgView_bg_left")
    local bgRight = self:findChild("imgView_bg_right")
    local bgSize = bgLeft:getContentSize()
    local scale = self:getUIScalePro()
    if scale == 1 and display.width > bgSize.width*2 then
        bgLeft:setScale(display.width * 0.5 / bgSize.width)
        bgRight:setScale(display.width * 0.5 / bgSize.width)
    else
        bgLeft:setScale(1 / scale)
        bgRight:setScale(1 / scale)
    end
end
function  ClanHomeView:initClanDoublePointsUI()
    local mgr = G_GetMgr(ACTIVITY_REF.ClanDoublePoints)
    if mgr then
        local countDownNode = mgr:showLeftTime()
        self.countDown = self:findChild("node_ClanDoublePoints")
        if countDownNode and self.countDown then
            self.countDown:addChild(countDownNode)
        end
    end
end
function ClanHomeView:readNodes()
    -- 聊天消息 红点
    self.sp_msgBg = self:findChild("sp_msgBg")
    self.lb_msg = self:findChild("lb_msg")

    -- 成员列表 红点
    self.sp_memberBg = self:findChild("sp_memberBg")
    self.lb_member = self:findChild("lb_member")
end

function ClanHomeView:updateUI(_clickSysType)
    if self.m_clickSysType and self.m_clickSysType == _clickSysType then
        return
    end
    self.m_clickSysType = _clickSysType or ClanConfig.systemEnum.MAIN

    --left
    self:updateSysBtnState()

    -- center
    self:updateCenterNodesVisible()
    if self.m_clickSysType == ClanConfig.systemEnum.MAIN then
        self:updateMainUI()
    elseif self.m_clickSysType == ClanConfig.systemEnum.CHAT then
        self:updateChatUI()
    elseif self.m_clickSysType == ClanConfig.systemEnum.MEMEBER then
        self:updateMemberUI()
    elseif self.m_clickSysType == ClanConfig.systemEnum.RANK then
        self:updateRankUI()
    end

    ClanManager:setCurSystemShowType(self.m_clickSysType)

    -- 公会多倍积分活动倒计时
    if self.countDown then
        if self.m_clickSysType == ClanConfig.systemEnum.CHAT then
            self.countDown:setVisible(false)
        else
            self.countDown:setVisible(true)
        end
    end
end

-- 更新菜单按钮位置
function ClanHomeView:updateMenuBtnPos()
    local btnMenu = self:findChild("btn_menu")
    btnMenu:setPositionX(btnMenu:getPositionX() + util_getBangScreenHeight())
end

function ClanHomeView:onEnter()
    ClanHomeView.super.onEnter(self)

    -- 背景音乐
    -- local bgMusicPath = self:getBgMusicPath()
    -- if bgMusicPath and bgMusicPath ~= "" then
    --     gLobalSoundManager:playBgMusic(bgMusicPath)
    --     gLobalSoundManager:setLockBgMusic(true)
    --     gLobalSoundManager:setLockBgVolume(true)
    -- end
    util_setCascadeOpacityEnabledRescursion(self, true)

    self:updateRedPoints()
    self:updateMenuBtnPos()
    schedule(self, handler(self, self.updateRedPoints), 1)
end

function ClanHomeView:onShowedCallFunc()
    ClanHomeView.super.onShowedCallFunc(self)

    self:updateUI(self.m_enterSysType)
    if self.m_clickSysType == ClanConfig.systemEnum.MAIN then
        self:checkSelfPosition()
    end
    ClanManager:clanHomeViewPoptLayer()
end

function ClanHomeView:updateRedPoints()
    local msg_counts = ChatManager:getUnreadMessageCounts()
    self.sp_msgBg:setVisible(msg_counts > 0)

    if msg_counts > 99 then
        msg_counts = "99+"
    end
    self.lb_msg:setString(msg_counts)
    util_scaleCoinLabGameLayerFromBgWidth(self.lb_msg, 36, 0.9)

    local clanData = ClanManager:getClanData()
    if clanData and clanData:getUserIdentity() == ClanConfig.userIdentity.LEADER then
        local apply_counts = clanData:getApplyCounts()
        self.sp_memberBg:setVisible(apply_counts > 0)

        if apply_counts > 99 then
            apply_counts = "99+"
        end
        self.lb_member:setString(apply_counts)
        util_scaleCoinLabGameLayerFromBgWidth(self.lb_member, 36, 0.9)
    else
        self.sp_memberBg:setVisible(false)
    end
end

-- 更新公会基本信息
function ClanHomeView:updateClanBaseInfoUI()
    self:updateClanIconUI()
    self:updateClanNameUI()
end
-- 公会 勋章
function ClanHomeView:updateClanIconUI()
    local spClanIconBg = self:findChild("sp_clubIconBg")
    local spClanIcon = self:findChild("sp_clubIcon")
    local iconName = self.m_clanData:getClanSimpleInfo():getTeamLogo()
    local imgBgPath = ClanManager:getClanLogoBgImgPath(iconName)
    local imgPath = ClanManager:getClanLogoImgPath(iconName)
    util_changeTexture(spClanIconBg, imgBgPath)
    util_changeTexture(spClanIcon, imgPath)
end
-- 公会 名字
function ClanHomeView:updateClanNameUI()
    local layoutName = self:findChild("layout_name")
    local lbClanName = self:findChild("font_clubname")
    local clanName = self.m_clanData:getClanSimpleInfo():getTeamName()
    lbClanName:setString(clanName)
    -- util_scaleCoinLabGameLayerFromBgWidth(lbClanName, 258, 0.8)
    local layoutNameWidth = layoutName:getContentSize().width
    local lbNameWidth = lbClanName:getContentSize().width * lbClanName:getScale()
    if layoutNameWidth < lbNameWidth then
        util_wordSwing(lbClanName, 1, layoutName, 3, 30, 3)
    else
        lbClanName:stopAllActions()
        lbClanName:setPositionX((layoutNameWidth - lbNameWidth) * 0.5)
    end
end

-- 改变 sys 按钮 状态
function ClanHomeView:updateSysBtnState()
    local btnMain = self:findChild("btn_main")
    local btnChat = self:findChild("btn_wall")
    local btnMember = self:findChild("btn_member")
    local btnRank = self:findChild("btn_rank")

    btnMain:setEnabled(self.m_clickSysType ~= ClanConfig.systemEnum.MAIN)
    btnChat:setEnabled(self.m_clickSysType ~= ClanConfig.systemEnum.CHAT)
    btnMember:setEnabled(self.m_clickSysType ~= ClanConfig.systemEnum.MEMEBER)
    btnRank:setEnabled(self.m_clickSysType ~= ClanConfig.systemEnum.RANK)
end

-- 更新 sys 节点显隐
function ClanHomeView:updateCenterNodesVisible()
    local nodeMain = self:findChild("node_main")
    local nodeChat = self:findChild("node_wall")
    local nodeMember = self:findChild("node_member")
    local nodeRank = self:findChild("node_rank")

    nodeMain:setVisible(self.m_clickSysType == ClanConfig.systemEnum.MAIN)
    nodeChat:setVisible(self.m_clickSysType == ClanConfig.systemEnum.CHAT)
    nodeMember:setVisible(self.m_clickSysType == ClanConfig.systemEnum.MEMEBER)
    nodeRank:setVisible(self.m_clickSysType == ClanConfig.systemEnum.RANK)
end

-- 更新 主界面
function ClanHomeView:updateMainUI()
    if not self.m_mainNodeObj then
        local nodeMain = self:findChild("node_main")
        self.m_mainNodeObj = util_createView("views.clan.baseInfo.ClanSysViewMain", self)
        self.m_mainNodeObj:addTo(nodeMain)
    else
        ClanManager:sendTeamRushInfoReqest()
        self.m_mainNodeObj:updateUI()
    end
end

-- 更新 聊天
function ClanHomeView:updateChatUI()
    if not self.m_chatNodeObj then
        local nodeMain = self:findChild("node_wall")
        self.m_chatNodeObj = util_createView("views.clan.chat.ClanSysViewChat")
        self.m_chatNodeObj:addTo(nodeMain)
    end

    ChatManager:getInstance():onOpen()
    self.m_chatNodeObj:updateUI()
    local curState = ChatManager:getSocketState()
    if curState == ChatConfig.TCP_STATE.CLOSED then
        ClanManager:requestHttpChatInfo()
    end
end

-- 更新 成员
function ClanHomeView:updateMemberUI()
    if not self.m_memberNodeObj then
        local nodeMain = self:findChild("node_member")
        self.m_memberNodeObj = util_createView("views.clan.member.ClanSysViewMember")
        self.m_memberNodeObj:addTo(nodeMain)
    else
        local lastReqMemDataType = self.m_clanData:getLastReqMemDataType()
        if lastReqMemDataType == "ClanRankUser" and ProtoConfig.REQUEST_CLAN_MEMBER.preReqTime then
            local subTime = os.time() - ProtoConfig.REQUEST_CLAN_MEMBER.preReqTime
            if subTime < ProtoConfig.REQUEST_CLAN_MEMBER.limitReqTime then
                self.m_memberNodeObj:updateUI()
            end
        end
    end

    ClanManager:sendClanMemberList()
end

-- 更新 排行榜
function ClanHomeView:updateRankUI()
    if not self.m_rankNodeObj then
        local nodeMain = self:findChild("node_rank")
        self.m_rankNodeObj = util_createView("views.clan.rank.ClanSysViewRank")
        self.m_rankNodeObj:addTo(nodeMain)
    else
        self.m_rankNodeObj:updateUI()
    end

    ClanManager:sendClanRankReq()
end

function ClanHomeView:clickFunc(sender)
    local name = sender:getName()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_close" then
        self:closeUI()

    elseif name == "btn_menu" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if tolua.isnull(self.m_memuUI) then
            return
        end
        self.m_memuUI:switchState()
    elseif name == "btn_baseInfo" or name == "btn_info" then
        -- 公会基本信息面板
        ClanManager:popClanBaseInfoPanel()
    elseif name == "btn_main" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:updateUI(ClanConfig.systemEnum.MAIN)
    elseif name == "btn_wall" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:updateUI(ClanConfig.systemEnum.CHAT)
    elseif name == "btn_member" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:updateUI(ClanConfig.systemEnum.MEMEBER)
    elseif name == "btn_rank" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:updateUI(ClanConfig.systemEnum.RANK)
    end
end

function ClanHomeView:closeUI()
    if self.m_bClose then
        return
    end
    self.m_bClose = true

    if self.m_memuUI then
        self.m_memuUI:setVisible(false)
    end
    
    gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.CLOSE_CLAN_GUIDE_LAYER) -- 关闭引导界面事件
    gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.CLOSE_CLAN_HOME_VIEW) -- 关闭引导界面事件

    local cb = function()
        if self.m_clanData then
            self.m_clanData:resetClanMemberList()
        end

        ClanManager:exitClanSystem()

        if self.m_viewOverFunc then
            self.m_viewOverFunc()
        end

        ClanManager:onQuit()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_FUN_OVER)
    end

    ClanHomeView.super.closeUI(self, cb)
end

-- 编辑公会新信息成功
function ClanHomeView:editClanInfoSuccessEvt()
    self:updateClanBaseInfoUI()
end

-- 公会成员 职位发生变化
function ClanHomeView:clanSelfIdentityChangeEvt()
    if self.m_clanData:isClanMember() or gLobalViewManager:getViewByExtendData("ClanSimpleInfoPanel") then
        return
    end

    -- 你被踢出公会了
    ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.KICKED_OFF_TEAM, handler(self, self.closeUI))
end

-- 注册事件
function ClanHomeView:registerListener()
    ClanHomeView.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.RECIEVE_USER_LEAVE_CLAN)
    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.KICKED_OFF_TEAM)
    gLobalNoticManager:addObserver(self, "editClanInfoSuccessEvt", ClanConfig.EVENT_NAME.RECIEVE_NEW_CLAN_INFO_SUCCESS)
    gLobalNoticManager:addObserver(self, "editClanInfoSuccessEvt", ClanConfig.EVENT_NAME.RECIEVE_CHAGE_CLAN_NAME)
    gLobalNoticManager:addObserver(self, "clanSelfIdentityChangeEvt", ClanConfig.EVENT_NAME.SEND_SYNC_CLAN_ACT_DATA) -- 同步公会配套的活动数据
    gLobalNoticManager:addObserver(self, "closeUI", ViewEventType.NOTIFY_CLOSE_OPEN_USER_INFO_LAYER_SYSTEM)
    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.RUSH_TASK_JUMP_TO_OTHER_FEATURE)
    gLobalNoticManager:addObserver(self, "closeUI", ViewEventType.CLOSE_USER_INFO_SCENE_GOTO_SCENE)
end

-- 处理 引导逻辑
function ClanHomeView:dealGuideLogic()
    if self.m_mainNodeObj and self.m_clickSysType == ClanConfig.systemEnum.MAIN then
        self.m_mainNodeObj:dealGuideLogic()
    end
end

function ClanHomeView:setViewOverFunc(_cb)
    self.m_viewOverFunc = _cb
end

-- 检查本人 职位是否发生变化
function ClanHomeView:checkSelfPosition()
    local view = ClanManager:popSelfPositionChangeTipLayer(util_node_handler(self, self.checkRankUpDown))
    if not view then
        self:checkRankUpDown()
    end
end

-- 检查段位变化
function ClanHomeView:checkRankUpDown()
    local view = ClanManager:checkPopRankUpDownLayer()
    if view then
        view:setOverFunc(
            function()
                self:checkPopColRedGift()
            end
        )
    else
        -- 引导逻辑
        performWithDelay(self, handler(self, self.checkPopColRedGift), 0)
    end
end

-- 检查领取 红包
function ClanHomeView:checkPopColRedGift()
    if not self.m_bCheckColRedGift then
        self:dealGuideLogic()
        return
    end

    local chatDatas = ChatManager:getChatData()
    local topGiftData = chatDatas:getUnCollectRedGift()
    if not topGiftData then
        self:dealGuideLogic()
        return
    end

    if topGiftData.msgId and topGiftData.extra and topGiftData.extra.randomSign then
        gLobalNoticManager:addObserver(self,function(self,data)
            if data.msgId == topGiftData.msgId then
                topGiftData.status = 1
                topGiftData.coins = tonumber(data.coins)

                -- 切换到 聊天标签
                self:updateUI(ClanConfig.systemEnum.CHAT)
                -- 弹出 自动领取红包弹板
                ClanManager:popAutoColRedGiftLayer(topGiftData)

                gLobalNoticManager:removeObserver(self, ChatConfig.EVENT_NAME.COLLECTED_TEAM_RED_GIFT_SUCCESS )
            end
        end, ChatConfig.EVENT_NAME.COLLECTED_TEAM_RED_GIFT_SUCCESS)
        ClanManager:sendTeamRedGiftCollect( topGiftData.msgId, topGiftData.extra.randomSign )
        return
    end

    self:dealGuideLogic()
end

return ClanHomeView