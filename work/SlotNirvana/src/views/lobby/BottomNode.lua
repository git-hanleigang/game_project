--
--大厅底部UI栏
--
local BottomExtraMgr = require("manager.System.BottomExtraMgr")
local BottomNode = class("BottomNode", util_require("base.BaseView"))

BottomNode.m_cashBonusNode = nil
BottomNode.m_vipBoostNode = nil
BottomNode.m_bIsRepeatTipShow = nil

BottomNode.m_lobbyBottomMax = 7 -- 暂定最大只能放6个点
BottomNode.m_lobbyBottomNodeSize = 120 -- 规定下节点的默认间距

BottomNode.LOBBYBOTTOM_CONFIG = {
    -- 界面下边条具体配置信息
    --[[
        说明 这里是一个顺序表，
        id  代表排序 越小越靠前
        lobbyNodeName 代表节点的名称
        open 代表可这个节点是否能够显示
        activity  代表当前这个是不是活动 false 代表是常驻点位 直接显示添加  true -- 是活动相关，需要判断是否能添加
        activityName 对应服务器上面的活动名称  *** 这个必须跟服务器配置的相同 要用来做判断
        luaFileName 对应的lua文件名称
        commingSoon 活动如果结束了 是否要创建comming soon 状态继续停留在bottom上。（不区分返回大厅的操作）
        exclude 互斥判断 -- 如果A 配置了互斥 B 那么A存在的时候 ，B就不能出现, A必要要比 B的优先级高
        ....

        具体逻辑判断为 遍历这张info 表 , 最终得到一个 m_table 作为 bottomNode 最终显示的数据table
    ]]
    -- [1] = { id = 1, lobbyNodeName = "Card", open = true, activity = false ,activityName = "",luaFileName = "LobbyBottom_CardNode" , commingSoon = false ,exclude = ""},
    [1] = {
        id = 3,
        lobbyNodeName = "BingoRush",
        open = true,
        activity = true,
        activityName = ACTIVITY_REF.BingoRush,
        luaFileName = "Activity_BingoRushLobbyNode",
        commingSoon = false,
        exclude = "",
        clickName = "BingoRush"
    },
    [2] = {
        id = 1,
        lobbyNodeName = "Deluex",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "Activity_DeluexeNormalNode",
        commingSoon = false,
        exclude = "",
        clickName = "Club"
    },
    [3] = {
        id = 2,
        lobbyNodeName = "SideKicks",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "LobbyBottom_SideKicks",
        commingSoon = false,
        exclude = "",
        clickName = "SideKicks"
    },
    -- [3] = { id = 2, lobbyNodeName = "MissionMerge", open = true, activity = false ,activityName = "",luaFileName = "LobbyBottom_MissionMergeNode" , commingSoon = false ,exclude = ""},
    [4] = {
        id = 4,
        lobbyNodeName = "DailyMission",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "LobbyBottom_DailyMissionNode",
        commingSoon = false,
        exclude = "",
        clickName = "Mission"
    },
    -- [4] = { id = 3, lobbyNodeName = "BattlePass", open = true, activity = false ,activityName = "",luaFileName = "LobbyBottom_BattlePassNode" , commingSoon = false ,exclude = ""},
    -- [4] = {id = 3, lobbyNodeName = "Challenge", open = true, activity = false, activityName = "", luaFileName = "LobbyBottom_ChallengeNode", commingSoon = false, exclude = ""},
    [5] = {
        id = 5,
        lobbyNodeName = "Clan",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "LobbyBottom_ClanNode",
        commingSoon = false,
        exclude = "",
        clickName = "Team"
    },
    [6] = {
        id = 6,
        lobbyNodeName = "QuestNewUser",
        open = true,
        activity = true,
        activityName = "Activity_QuestNewUser",
        luaFileName = "Activity_QuestNewUser",
        commingSoon = false,
        exclude = "Activity_Quest",
        clickName = "Quest"
    },
    [7] = {
        id = 7,
        lobbyNodeName = "Quest",
        open = true,
        activity = true,
        activityName = "Activity_Quest",
        luaFileName = "Activity_Quest",
        commingSoon = true,
        exclude = "",
        clickName = "Quest"
    },
    [8] = {
        id = 8,
        lobbyNodeName = "QuestNew",
        open = true,
        activity = true,
        activityName = "Activity_QuestNew",
        luaFileName = "Activity_QuestNew",
        commingSoon = false,
        exclude = "",
        clickName = "QuestNew",
        replace = "Activity_Quest"
    },
    [9] = {
        id = 9,
        lobbyNodeName = "Activity",
        open = true,
        activity = true,
        activityName = "",
        luaFileName = "",
        commingSoon = true,
        exclude = "",
        clickName = ""
    },
    [10] = {
        id = 10,
        lobbyNodeName = "Inbox",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "LobbyBottom_InboxNode",
        commingSoon = false,
        exclude = "",
        clickName = "Inbox"
    },
    [11] = {
        id = 11,
        lobbyNodeName = "Challenge",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "LobbyBottom_ChallengeNode",
        commingSoon = false,
        exclude = "",
        clickName = "Challenge",
    },
    [12] = {
        id = 12,
        lobbyNodeName = "MonthlyCard",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "LobbyBottom_MonthlyCard",
        commingSoon = false,
        exclude = "",
        clickName = "MonthlyCard",
    },
    [13] = {
        id = 13,
        lobbyNodeName = "DailyBonus",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "LobbyBottom_DailyBonusNode",
        commingSoon = false,
        exclude = "",
        clickName = "DailyBonus"
    },
    [14] = {
        id = 14,
        lobbyNodeName = "LOTTERY",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "LobbyBottom_LotteryNode",
        commingSoon = false,
        exclude = "",
        clickName = "Lottery"
    },
    [15] = {
        id = 15,
        lobbyNodeName = "VIP",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "LobbyBottom_VIPNode",
        commingSoon = false,
        exclude = "",
        clickName = "Vip"
    },
    [16] = {
        id = 16,
        lobbyNodeName = "LEAGUES",
        open = true,
        activity = false,
        activityName = ACTIVITY_REF.League,
        luaFileName = "LobbyBottom_LeagueNode",
        commingSoon = true,
        exclude = "",
        clickName = "Leagues"
    },
    [17] = {
        id = 17,
        lobbyNodeName = "ScratchCards",
        open = true,
        activity = true,
        activityName = ACTIVITY_REF.ScratchCards,
        luaFileName = "Activity_ScratchCards",
        commingSoon = false,
        exclude = "",
        clickName = "ScratchCards"
    },
    [18] = {
        id = 18,
        lobbyNodeName = "Firend",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "LobbyBottom_FriendsNode",
        commingSoon = false,
        exclude = "",
        clickName = "Firend",
        mgrLua = "GameModule.Friend.controller.FriendManager"
    },
    [19] = {
        id = 19,
        lobbyNodeName = "LevelRoad",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "LobbyBottom_LevelRoadNode",
        commingSoon = false,
        exclude = "",
        clickName = "LevelRoad",
    },
    -- .....
}

BottomNode.ACTIVITY_INFO = {
    [1] = {activityName = ACTIVITY_REF.Bingo, luaFileName = "Activity_Bingo", clickName = "Bingo"},
    [2] = {activityName = ACTIVITY_REF.RichMan, luaFileName = "Activity_RichMan", clickName = "RichMan"},
    [3] = {activityName = ACTIVITY_REF.WorldTrip, luaFileName = "Activity_WorldTrip", clickName = "WorldTrip"},
    [4] = {activityName = ACTIVITY_REF.DinnerLand, luaFileName = "Activity_DinnerLand", clickName = "DinnerLand"},
    [5] = {activityName = ACTIVITY_REF.Blast, luaFileName = "Activity_Blast", clickName = "Blast"},
    [6] = {activityName = ACTIVITY_REF.Word, luaFileName = "Activity_Word", clickName = "Word"},
    [7] = {activityName = ACTIVITY_REF.CoinPusher, luaFileName = "Activity_CoinPusher", clickName = "CoinPusher"},
    [8] = {activityName = ACTIVITY_REF.DiningRoom, luaFileName = "Activity_DiningRoom", clickName = "DiningRoom"},
    [9] = {activityName = ACTIVITY_REF.Redecor, luaFileName = "Activity_Redecor", clickName = "Redecor"},
    [10] = {activityName = ACTIVITY_REF.Poker, luaFileName = "Activity_Poker", clickName = "Poker"},
    [11] = {activityName = ACTIVITY_REF.NewCoinPusher, luaFileName = "Activity_NewCoinPusher", clickName = "NewCoinPusher"},
    [12] = {activityName = ACTIVITY_REF.PipeConnect, luaFileName = "Activity_PipeConnect", clickName = "PipeConnect"},
    [13] = {activityName = ACTIVITY_REF.OutsideCave, luaFileName = "Activity_OutsideCave", clickName = "OutsideCave"},
    [14] = {activityName = ACTIVITY_REF.EgyptCoinPusher, luaFileName = "Activity_EgyptCoinPusher", clickName = "EgyptCoinPusher"},
}

BottomNode.MISSION_MERGE_INFO = {
    [1] = {lobbyNodeName = "DailyMission", luaFileName = "LobbyBottom_DailyMissionNode"},
    [2] = {lobbyNodeName = "Challenge", luaFileName = "LobbyBottom_ChallengeNode"},
    [3] = {lobbyNodeName = "League", luaFileName = "LobbyBottom_LeagueNode"}
    -- [3] = { lobbyNodeName = "BattlePass", luaFileName = "LobbyBottom_BattlePassNode" },
}

BottomNode.LOBBYBOTTOM_DISINFO = {
    -- 下边条具体ui间距设置
    -- key = lobbynode 个数
    -- space 间距
    -- scale 代表缩放系数
    -- fontScale 字体缩放系数
    [4] = {space = 160, scale = 1.0, fontScale = 1.0},
    [5] = {space = 150, scale = 1.0, fontScale = 1.0},
    [6] = {space = 130, scale = 1.0, fontScale = 0.85},
    [7] = {space = 115, scale = 0.8, fontScale = 0.85}
}

function BottomNode:initUI(data)
    -- setDefaultTextureType("RGBA8888", nil)

    self:createCsbNode("GameNode/BottomNode.csb")

    self.m_cashBonusTip = self:findChild("cash_bonus_tip")
    self.m_cashBonusNum = self:findChild("cash_bonus_num")
    self.m_cashBonusTip:setVisible(false)

    self.m_cashBonusNode = self:findChild("cash_bonus_entry")

    self.m_centerNode = self:findChild("Node_center")

    self:initCashBonusEntry()

    self:initWithTouchEvent()
    -- if data then
    --     self:openCashBonusTishi(data)
    -- end

    self:initActivityNode()

    -- csc 2020年08月12日15:15:15 替换为card
    local uiDeluexeClubBtn = util_createFindView("views/Activity_LobbyIcon/LobbyBottom_CardNode")
    if uiDeluexeClubBtn ~= nil then
        self:findChild("deluxeClub"):addChild(uiDeluexeClubBtn)
    end

    self:runCsbAction("idle", true)

    -- csc 新
    self:initLobbyBottomNode()
    -- self:updateUiBg()
    -- self.m_spRedPoint = self:findChild("sp_redPoint")
    -- if self.m_spRedPoint then
    --     self.m_spRedPoint:setVisible(false)
    -- end

    -- setDefaultTextureType("RGBA4444", nil)
end

function BottomNode:updateUiByDeluxe(isOpen)
    self:updateUiBg(isOpen)
end

function BottomNode:updateOption(bOpenDeluxe)
end

function BottomNode:updateUiBg(bOpenDeluxe)
    local spNormalBgL = self:findChild("sp_bg")
    -- local spNormalBgR = self:findChild("sp_bg_0")

    local spDeluxeBgL = self:findChild("sp_dcbg")
    -- local spDeluxeBgR = self:findChild("sp_dcbg_0")

    local bOpenDeluxe = bOpenDeluxe or globalData.deluexeClubData:getDeluexeClubStatus()

    spNormalBgL:setVisible(not bOpenDeluxe)
    -- spNormalBgR:setVisible(not bOpenDeluxe)
    spDeluxeBgL:setVisible(bOpenDeluxe)
    -- spDeluxeBgR:setVisible(bOpenDeluxe)

    for i = 1, 3 do
        local spBgNormal = self:findChild("sp_bg_normal_" .. i)
        local spBgSpecial = self:findChild("sp_bg_special_" .. i)
        if spBgNormal then
            spBgNormal:setVisible(not bOpenDeluxe)
        end
        if spBgSpecial then
            spBgSpecial:setVisible(bOpenDeluxe)
        end
    end

    -- local btnMoreRes = "GameNode/ui_lobbyBottom/ui_lobby_bottom_seeMore.png"
    -- if bOpenDeluxe then
    --     btnMoreRes = "GameNode/ui_lobbyBottom/ui_lobby_bottom_seeMore1.png"
    -- end
    -- local btnMore = self:findChild("Button_5")
    -- if btnMore then
    --     btnMore:loadTextureNormal(btnMoreRes)
    --     btnMore:loadTexturePressed(btnMoreRes)
    --     btnMore:loadTextureDisabled(btnMoreRes)
    -- end

    -- 节点文字
    for i = 1, #self.m_lobbyBottomNodeInfo do
        local nodeInfo = self.m_lobbyBottomNodeInfo[i]
        if nodeInfo and nodeInfo.node then
            nodeInfo.node:updateUiByDeluxe(bOpenDeluxe)
        end
    end
end

function BottomNode:initActivityNode()
    --vipboost
    local vipBoost = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
    if vipBoost then
        local extraLevel = vipBoost:getBoostVipLevel()
        if extraLevel > 0 then
            local btn_VIP = self:findChild("btn_VIP")
            if btn_VIP then
                if not self.m_vipBoostNode then
                    local boostIcon = util_createAnimation("Activity/VIPicon.csb")
                    btn_VIP:addChild(boostIcon, 1)
                    boostIcon:setPosition(50, 20)
                    boostIcon:playAction("idleframe", true)
                    self.m_vipBoostNode = boostIcon
                end
            end
        end
    end
end

--活动结束
function BottomNode:closeActivityNode(param)
    -- 修改这块儿的代码 。活动结束了找到对应的 bottom node 节点进行状态更换
    local activityKey = param
    local refresh = false
    for i = table.nums(self.m_lobbyBottomNodeInfo), 1, -1 do
        local data = self.m_lobbyBottomNodeInfo[i]
        local info = data.info
        if data.node then
            print("------- BottomNode:closeActivityNode activityKey = " .. activityKey)
            if info.activityName == activityKey then
                -- 直接更新 近期活动展示，如果近期没有活动需要开则活动节点就不显示了
                if info.lobbyNodeName == "Activity" or info.lobbyNodeName == "Quest" then
                    refresh = true
                    break
                else
                    if info.commingSoon then
                        if data.node.showCommingSoon then
                            data.node:showCommingSoon()
                        end
                    else
                        refresh = true
                        break
                    end
                end
            end
        end
    end
    if refresh then
        performWithDelay(
            self,
            function()
                self:updateLobbyNode()
            end,
            1.1
        )
    end
end

function BottomNode:getMinTime(tArray)
    local time = 0

    for k, v in pairs(tArray) do
        if k == 1 then
            time = v
        end

        if v < time then
            time = v
        end
    end

    return time
end

function BottomNode:getDayOrTimeState(Ostime)
    local isDay = false
    local timeStr = ""

    if Ostime > ONE_DAY_TIME_STAMP then
        timeStr = math.modf(Ostime / ONE_DAY_TIME_STAMP) .. " DAYS"
        isDay = true
    else
        isDay = false
        timeStr = util_count_down_str(Ostime)
    end

    return isDay, timeStr
end

function BottomNode:initCashBonusEntry()
    local bonusUI = util_createView("views.cashBonus.CashBonusLobbyTip")
    if bonusUI then
        bonusUI:setPositionY(57)
        self.m_cashBonusNode:addChild(bonusUI)
        globalNoviceGuideManager:addNode(NOVICEGUIDE_ORDER.dallyWhell, bonusUI)
        globalNoviceGuideManager:addNode(NOVICEGUIDE_ORDER.silverEntrepot, bonusUI)
        self.m_cashBonusGuide = bonusUI
    end
end

--TODO-NEWGUIDE 显示轮盘引导
function BottomNode:checkShowWheelGuide(isShowGuide)
    if isShowGuide then
        if not self.m_lastPos then
            self.m_lastPos = cc.p(self.m_cashBonusGuide:getPosition())
            local wordPos = self.m_cashBonusNode:convertToWorldSpace(self.m_lastPos)
            util_changeNodeParent(gLobalViewManager:getViewLayer(), self.m_cashBonusGuide, ViewZorder.ZORDER_GUIDE + 1)
            self.m_cashBonusGuide:setPosition(wordPos)
            -- local _scale = self.m_csbNode:getScale()
            local _scale = globalData.lobbyScale
            self.m_cashBonusGuide:setScale(_scale)
            self.m_cashBonusGuide:setGuide(self.m_cashBonusNode, self.m_lastPos)
            self.m_lastPos = nil
        end
    end
end

function BottomNode:checkShowWheelGuideCashMoney(data)
    if data.isShowGuide then
        self.m_lastPos = cc.p(self.m_cashBonusGuide:getPosition())
        local wordPos = self.m_cashBonusNode:convertToWorldSpace(self.m_lastPos)
        util_changeNodeParent(gLobalViewManager:getViewLayer(), self.m_cashBonusGuide, ViewZorder.ZORDER_GUIDE + 1)
        self.m_cashBonusGuide:setPosition(wordPos)
        -- local _scale = self.m_csbNode:getScale()
        local _scale = globalData.lobbyScale
        self.m_cashBonusGuide:setScale(_scale)
        self.m_cashBonusGuide:setCashMoneyTips(self.m_cashBonusNode, self.m_lastPos, data.id)
    end
end

-- fb 点击事件
function BottomNode:fbBtnTouchEvent()
    if gLobalSendDataManager:getIsFbLogin() == false then
        if globalFaceBookManager:getFbLoginStatus() then
            release_print("xcyy : FbLoginStatus")
            globalData.skipForeGround = true
            gLobalSendDataManager:getNetWorkLogon():FBLoginGame(LOG_ENUM_TYPE.BindFB_BaseIcon)
        else
            gLobalSendDataManager:getNetWorkLogon().m_fbLoginPos = LOG_ENUM_TYPE.BindFB_BaseIcon
            globalFaceBookManager:fbLogin()
            release_print("xcyy : FbLoginStatus fail")
        end
    else
        globalFaceBookManager:fbLogOut()
        gLobalSendDataManager:getNetWorkLogon():logoutGame()
    end
end
--点击监听
function BottomNode:clickStartFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name ~= "activity_suotou_but_layout" and name ~= "quest_suotou_but_layout" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUESTMSG_OPEN)
    end
    -- if name ~= "suotou_but_layout_0" then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MISSIONMSG_OPEN)
    -- end
end

function BottomNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name ~= "activity_suotou_but_layout" and name ~= "quest_suotou_but_layout" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUESTMSG_OPEN)
    end
    -- if name ~= "suotou_but_layout_0" then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MISSIONMSG_OPEN)
    -- end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CASHBONUS_TISHI_CLOSE)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MENUNODE_OPEN)
    if name == "btn_booster" then
    elseif name == "activity_suotou_but_layout" then
        self:clickTips(self:findChild("activity_msg"))
    elseif name == "quest_suotou_but_layout" then
        self:clickTips(self:findChild("quest_msg"))
    elseif name == "dian_bottom_0" then
        -- 商城 页面
        gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "buyCoins")
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local params = {
            shopPageIndex = 1,
            dotKeyType = name,
            dotUrlType = DotUrlType.UrlName,
            dotIsPrep = true,
            dotEntrySite = DotEntrySite.DownView,
            dotEntryType = DotEntryType.Lobby
        }
        G_GetMgr(G_REF.Shop):showMainLayer(params)
    elseif name == "suotou_but_layout_2" then
        -- self.m_piggy_msg:setVisible(true)
        -- gLobalViewManager:addAutoCloseTips(self.m_piggy_msg,function()
        --     self.m_piggy_msg:setVisible(false)
        -- end)
    elseif name == "bank_bottom_0_0" then
    elseif name == "btn_leader" then
    elseif name == "activity_map_bottom" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:clickTips(self:findChild("activity_msg"))
    elseif name == "quest_map_bottom" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:clickTips(self:findChild("quest_msg"))
    elseif name == "btn_rate_us" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        performWithDelay(
            self,
            function()
                globalData.skipForeGround = true
                globalData.rateUsData:checkNetWork()
                xcyy.GameBridgeLua:rateUsForSetting()
            end,
            0.2
        )
    elseif name == "btn_VIP" then
        local vip = G_GetMgr(G_REF.Vip):showMainLayer()
        if vip then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.click_vip)
            gLobalSendDataManager:getLogPopub():addNodeDot(vip, name, DotUrlType.UrlName, true, DotEntrySite.DownView, DotEntryType.Lobby)
        end
    elseif name == "Button_extend" then
        if self.m_clickExtend then
            return
        end
        self.m_clickExtend = true
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:runCsbAction(
            "start",
            false,
            function()
                self.runCsbAction("idle", true)
            end,
            60
        )
        performWithDelay(
            self,
            function()
                local view = util_createView("views.lobby.BottomExtraNode")
                view:setName("BottomExtraNode")
                gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
                gLobalSendDataManager:getLogBottomNode():sendFunctionClickLog(
                    {
                        siteType = "Lobby",
                        clickName = "See More",
                        site = 99
                    }
                )
            end,
            5 / 60
        )
    end
end

function BottomNode:showBottomExtraNode()
    if self.m_clickExtend then
        return
    end
    self.m_clickExtend = true
    local view = util_createView("views.lobby.BottomExtraNode")
    view:setName("BottomExtraNode")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    gLobalSendDataManager:getLogBottomNode():sendFunctionClickLog(
        {
            siteType = "Lobby",
            clickName = "See More",
            site = 99
        }
    )
end

function BottomNode:onExit()
    gLobalNoticManager:removeAllObservers(self)
    if self.m_redPointTimer then
        self:stopAction(self.m_redPointTimer)
        self.m_redPointTimer = nil
    end
end

function BottomNode:updateSeeMoreState()
    local isChange, hasRedPoint = BottomExtraMgr:getInstance():checkRedTip(self.m_tbBottomNodeKeys)
    if isChange then
        if self.m_spRedPoint then
            self.m_spRedPoint:setVisible(hasRedPoint)
        end
    end
end

function BottomNode:onEnter()
    BottomExtraMgr:getInstance():initInfos()
    -- 先请求下， 要不有1秒的间隔， 数字会明显显示不对
    self:checkCashBonusRedPoint()

    self:updateUiByDeluxe()

    self.m_redPointTimer =
        schedule(
        self,
        function()
            self:checkCashBonusRedPoint()
            self:updateSeeMoreState()
        end,
        1
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, mailCount)
            self:checkCashBonusRedPoint()
        end,
        ViewEventType.NOTIFY_CASHBONUS_COLLECT_PUSH
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, bLogonOutStatus)
            --self:setFbLabShow()
            gLobalViewManager:removeLoadingAnima()
        end,
        HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGOUT
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            gLobalViewManager:removeLoadingAnima()
            self:loginFail(data)
        end,
        HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_FAILD,
        true
    )

    --服务器返回成功消息
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            --self:setFbLabShow()
            gLobalViewManager:removeLoadingAnima()
        end,
        HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_SUCCESS,
        true
    )

    ---fb登陆成功回调
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
        function(Target, mailCount)
        end,
        ViewEventType.NOTIFY_QUESTMSG_OPEN
    )

    --活动结束
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:closeActivityNode(params)
        end,
        ViewEventType.NOTIFY_ACTIVITY_FIND_CLOSE
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.VipBoost then
                if self.m_vipBoostNode then
                    self.m_vipBoostNode:removeFromParent()
                    self.m_vipBoostNode = nil
                end
            else
                self:closeActivityNode(params.name)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.checkShowWheelGuide then
                self:checkShowWheelGuide(params)
            end
        end,
        ViewEventType.NOTIFY_CHANGE_CASHWHEEL_ZORDER
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.checkShowWheelGuideCashMoney then
                self:checkShowWheelGuideCashMoney(params)
            end
        end,
        ViewEventType.NOTIFY_CHANGE_CASHWHEEL_GUIDE_ZORDER
    )

    ---- quest 界面隐藏
    --gLobalNoticManager:addObserver(
    --    self,
    --    function(self, params)
    --        self:updateLobbyNode()
    --    end,
    --    ViewEventType.NOTIFY_QUEST_VIEW_HIDE
    --)

    -- 扩展栏打开完成
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self.m_clickExtend = false
        end,
        ViewEventType.NOTIFY_LOBBY_UI_EXTRA_UP
    )

    -- 等级里程碑 达到最高等级，系统关闭
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateLobbyNode()
        end,
        ViewEventType.NOTIFY_LEVELROAD_REFRESH_LOBBY_BOTTOMNODE
    )
end

function BottomNode:checkFBLoginState(loginInfo)
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
            gLobalSendDataManager:getNetWorkLogon():FBLoginGame()
        elseif loginState == 0 then
            --失败
            gLobalViewManager:removeLoadingAnima()
        else
            gLobalViewManager:removeLoadingAnima()
            self:loginFail(nil)
        end
    else
        if loginInfo then
            gLobalSendDataManager:getNetWorkLogon():FBLoginGame()
        else
            gLobalViewManager:removeLoadingAnima()
            self:loginFail(nil)
        end
    end
end

function BottomNode:openCashBonusTishi(id)
    if globalDynamicDLControl:checkDownloading("cashBonusDy") then
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_TOPDOWN_ZORDER, true)
        local cashBonus_tishi = util_createView("views.cashBonus.CashBonus_tishi", id)
        self:findChild("cashbonus_tishi"):addChild(cashBonus_tishi)
    end
end

function BottomNode:initWithTouchEvent()
    -- local function onTouchBegan_callback(touch, event)
    --     self:findChild("activity_msg"):setVisible(false)
    --     return false
    -- end
    -- local function onTouchMoved_callback(touch, event)
    -- end
    -- local function onTouchEnded_callback(touch, event)
    -- end
    -- local listener = cc.EventListenerTouchOneByOne:create()
    -- listener:setSwallowTouches(false)
    -- listener:registerScriptHandler(onTouchBegan_callback,cc.Handler.EVENT_TOUCH_BEGAN )
    -- listener:registerScriptHandler(onTouchMoved_callback,cc.Handler.EVENT_TOUCH_MOVED )
    -- listener:registerScriptHandler(onTouchEnded_callback,cc.Handler.EVENT_TOUCH_ENDED )
    -- local eventDispatcher = self:getEventDispatcher()
    -- eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function BottomNode:loginFail(errorData)
    -- 登录失败 -- 添加提示界面 
    local view = util_createView("views.logon.Logonfailure", true)
    view:setFailureDescribe(errorData)

    gLobalViewManager:showUI(view, ViewZorder.ZORDER_NETWORK)
end

function BottomNode:checkCashBonusRedPoint()
    local bonus = G_GetMgr(G_REF.CashBonus):getRunningData():getCurCollectBonus()
    -- 检测是否有 轮盘引导, 如果有轮盘引导则不显示数字
    if bonus and globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.dallyWhell.id) then
    else
        self.m_cashBonusTip:setVisible(false)
    end
end

function BottomNode:clickTips(node)
    if not node then
        return
    end
    if node:isVisible() then
        node:setVisible(false)
        return
    end
    node:setVisible(true)
    gLobalViewManager:addAutoCloseTips(
        node,
        function()
            performWithDelay(
                self,
                function()
                    if not tolua.isnull(node) then
                        node:setVisible(false)
                    end
                end,
                0.1
            )
        end
    )
end

function BottomNode:initLobbyBottomNode()
    -- 检索一遍当前能展示的节点信息
    self.m_excludeName = {}
    self.m_lobbyBottomNodeInfo = {} -- 节点信息 组装数据 data
    self.m_tbBottomNodeKeys = {}
    --[[
        node -- lobbynode
        info -- 配置表信息
        commingsoon :  true false
    ]]
    -- 初始化节点信息
    self:initLobbyBottomNodeInfo()
    -- 初始化节点位置
    -- self:initBottomNodePos()

    -- 根据节点的顺序排序一下
    table.sort(
        self.m_lobbyBottomNodeInfo,
        function(a, b)
            return tonumber(a.info.id) < tonumber(b.info.id)
        end
    )
    -- 添加节点到相应位置上
    self:addLobbyBottomNode()
end

function BottomNode:initLobbyBottomNodeInfo()
    for i = 1, #self.LOBBYBOTTOM_CONFIG do
        local data = {}
        local info = clone(self.LOBBYBOTTOM_CONFIG[i])
        local tablenums = table.nums(self.m_lobbyBottomNodeInfo) + 1
        local canAdd = false
        if info.open then
            data.info = info
            data.commingsoon = false
            if info.activity then
                -- 活动开启或者 comming soon 状态开启 都把活动添显示出来
                -- csc 2020年08月21日 修改为遍历查找当前能显示的活动
                if info.lobbyNodeName == "Activity" then
                    local newData, comingSoon = self:checkCurrShowActivityNode()
                    if newData then
                        -- 赋值两个值
                        data.info.activityName = newData.activityName
                        data.info.luaFileName = newData.activityName
                        data.info.clickName = newData.clickName

                        data.commingsoon = comingSoon
                        canAdd = true
                    end
                else
                    if info.lobbyNodeName == "ScratchCards" then
                        local canShow, comingSoon = self:checkCurrShowScratchCardsNode(info)
                        if canShow then
                            data.commingsoon = comingSoon
                            canAdd = true
                        end
                    else
                        if info.lobbyNodeName == "Quest" then
                            if G_GetMgr(ACTIVITY_REF.QuestNew):isRunning() then
                                info.commingSoon = false
                            end
                        end
                        local canShow, comingSoon = self:checkCurrShowQuestNode(info)
                        if canShow then
                            data.commingsoon = comingSoon
                            canAdd = true
                        end
                    end
                end
            else
                -- 普通节点默认可添加
                if info.lobbyNodeName == "LEAGUES" then
                    local canShow, comingSoon = self:checkCurrShowLeagueNode(info)
                    if canShow then
                        data.commingsoon = comingSoon
                        canAdd = true
                    end
                elseif info.lobbyNodeName == "Farm" then
                    local canShow, comingSoon = self:checkCurrShowFarmNode(info)
                    if canShow then
                        data.commingsoon = comingSoon
                        canAdd = true
                    end
                elseif info.lobbyNodeName == "LevelRoad" then
                    local canShow, comingSoon = self:checkCurrShowLevelRoadNode(info)
                    if canShow then
                        data.commingsoon = comingSoon
                        canAdd = true
                    end
                else
                    canAdd = true
                end
            end
            -- csc 2022-03-01 添加互斥处理
            if canAdd then
                canAdd = self:checkExcludeNodeHandle(info)
            end
            if canAdd then
                if info.replace then
                    local data_index = nil
                    for i,v in ipairs(self.m_lobbyBottomNodeInfo) do
                        if v.info.activityName == info.replace then
                            data_index = i
                            break
                        end
                    end
                    if data_index then
                        self.m_lobbyBottomNodeInfo[data_index] = data
                    else
                        self.m_lobbyBottomNodeInfo[tablenums] = data
                    end
                else
                    self.m_lobbyBottomNodeInfo[tablenums] = data
                end
            end
        end
    end
end

function BottomNode:addLobbyBottomNode()
    local uiList = {}
    local layout = ccui.Layout:create()
    layout:setContentSize(120, 120)
    table.insert(uiList, layout)
    -- 这块应该遍历的是 计算出来的节点Node 摆放位置table
    for i = 1, table.nums(self.m_lobbyBottomNodeInfo) do
        local data = self.m_lobbyBottomNodeInfo[i]
        local info = data.info
        local commingsoon = data.commingsoon
        local lobbyNode = nil
        print("------- 节点名称 ---- name " .. info.lobbyNodeName)

        if info.activity then -- 如果是活动节点的话。 需要到 ActivityManager 去处理 （模块化）
            lobbyNode = gLobalActivityManager:InitLobbyNode(info.activityName, commingsoon)
        else
            lobbyNode = self:createLobbyNode(info.luaFileName)
        end
        if lobbyNode then
            lobbyNode:setLogFuncClickInfo(
                {
                    siteType = "Lobby",
                    clickName = info.clickName,
                    site = i
                }
            )
            -- lobbyNode:setPosition(self.m_lobbyBottomNodePos[i])
            -- self:findChild("Node_center"):addChild(lobbyNode)

            local disInfo = self.LOBBYBOTTOM_DISINFO[table.nums(self.m_lobbyBottomNodeInfo)]
            if disInfo then
                lobbyNode:setNodeFontSacle(disInfo.fontScale)
            end

            -- 任务相关节点整合
            if info.lobbyNodeName == "MissionMerge" then
                lobbyNode:setMergeNodeInfo(self.MISSION_MERGE_INFO)
            end

            -- 封装成新数据
            local newData = {
                node = lobbyNode,
                info = info,
                commingsoon = commingsoon
            }
            self.m_lobbyBottomNodeInfo[i] = newData
            self.m_tbBottomNodeKeys["" .. info.lobbyNodeName] = true
            table.insert(uiList, lobbyNode)

            if #uiList == 8 then --添加seeMore按钮
                local seeAllBtn = self:createSeeMoreBtn()
                table.insert(uiList, seeAllBtn)
            end
        end
    end

    if #uiList < 8 then --添加seeMore按钮
        local seeAllBtn = self:createSeeMoreBtn()
        table.insert(uiList, seeAllBtn)
    end

    local layout = ccui.Layout:create()
    table.insert(uiList, layout)

    if #uiList > 0 then
        local width, height = 1200, 300
        local clipNode = cc.ClippingRectangleNode:create(
            {
                x = -width / 2,
                y = 0,
                width = width,
                height = height
            }
        )
        self.m_centerNode:addChild(clipNode)
        
        local circleScrollUI = util_createView("base.CircleScrollUI")
        circleScrollUI:setMargin(5)
        circleScrollUI:setMarginXY(120, 24)
        circleScrollUI:setMaxTopYPercent(0.5)
        circleScrollUI:setTopYHeight(120)
        circleScrollUI:setMaxAngle(12)
        circleScrollUI:setRadius(3100)
        circleScrollUI:setScrollViewOriginDistance(-50)
        circleScrollUI:setUIList(uiList)
        circleScrollUI:setScrollSoundPath("GameNode/sound/BottomNode.mp3")
    
        local scrollWidth = 1130
        circleScrollUI:setDisplaySize(scrollWidth, 120)
        circleScrollUI:setPosition(-scrollWidth / 2, -3070)
        circleScrollUI:setScrollClippingEnabled(false)
        clipNode:addChild(circleScrollUI)
    end
end

function BottomNode:createSeeMoreBtn()
    local seeAllPath = "GameNode/UI_lobby_bottom_loding_2023/ui_lobby_bottom_seeall.png"
    local bOpenDeluxe = globalData.deluexeClubData:getDeluexeClubStatus()
    if bOpenDeluxe then
        seeAllPath = "GameNode/UI_lobby_bottom_loding_2023/ui_lobby_bottom_seeall2.png"
    end
    local seeAllBtn = ccui.Button:create(seeAllPath, seeAllPath)
    local redPoint = util_createSprite("GameNode/ui_lobbyBottom/ui_lobby_bottom_redPoint.png")
    redPoint:addTo(seeAllBtn)
    redPoint:setPosition(56, 48)
    redPoint:setVisible(false)
    self.m_spRedPoint = redPoint
    seeAllBtn:setTitleText("")
    seeAllBtn:setAnchorPoint(0.5, 0.8)
    seeAllBtn:addClickEventListener(function(sender)
        self:showBottomExtraNode()
    end)
    return seeAllBtn
end

function BottomNode:initBottomNodePos()
    -- -- 初始化下面节点的位置
    -- self.m_lobbyBottomNodePos = {}

    -- local centerNode = self:findChild("Node_centerPos")
    -- local centerPos = cc.p(centerNode:getPosition())

    -- -- 传入活动个数 每个node 的大小 中心点坐标
    -- -- 得出一个坐标值的表
    -- local lobbyNum = table.nums(self.m_lobbyBottomNodeInfo)
    -- if lobbyNum > self.m_lobbyBottomMax then
    --     lobbyNum = self.m_lobbyBottomMax
    -- end
    -- local space = self.m_lobbyBottomNodeSize
    -- local disInfo = self.LOBBYBOTTOM_DISINFO[table.nums(self.m_lobbyBottomNodeInfo)]
    -- if disInfo then
    --     space = disInfo.space
    -- end

    -- self.m_lobbyBottomNodePos = util_layoutCenterPosX(lobbyNum, space, centerPos)
    -- local node = self:findChild("node_pos1")
    -- if node and not tolua.isnull(node) then
    --     self.m_lobbyBottomNodePos = {}
    --     for i=1,7 do
    --         local nd = self:findChild("node_pos"..i)
    --         local node_pos = cc.p(nd:getPositionX(),nd:getPositionY())
    --         self.m_lobbyBottomNodePos[i] = node_pos
    --     end
    -- end
end

function BottomNode:createLobbyNode(luaFileName)
    if luaFileName ~= nil then
        local entryNode = util_createFindView("views/Activity_LobbyIcon/" .. luaFileName)
        if not entryNode then
            entryNode = util_createFindView("Activity/" .. luaFileName)
        end
        return entryNode
    end
    return nil
end

function BottomNode:updateLobbyNode()
    -- 刷新节点信息
    for i = table.nums(self.m_lobbyBottomNodeInfo), 1, -1 do
        -- local data = self.m_lobbyBottomNodeInfo[i]
        -- if data.node then
        --     data.node:removeFromParent()
        -- end

        table.remove(self.m_lobbyBottomNodeInfo, i)
    end
    self.m_centerNode:removeAllChildren()
    self:initLobbyBottomNode()
end

-- 专门用来检测 活动节点
function BottomNode:checkCurrShowActivityNode()
    --配置了当前的所有活动
    -- isRunning 代表当前活动有数据，当前等级允许running 这个活动
    -- local canShow = false
    -- 检查最近的
    local checkRecent = false
    local actInfo = nil
    -- 普通活动信息
    local actInfoNormal = nil
    -- 新手期活动数据
    local actInfoNovice = nil
    local comingsoon = false

    --1. 检测当前是否有正在进行时的活动
    for i = 1, #self.ACTIVITY_INFO do
        local act_info = self.ACTIVITY_INFO[i]
        local act_data = G_GetActivityDataByRef(act_info.activityName, true)
        if act_data then
            -- 检测到当前活动是否在活动时间内,不用考虑等级是否到达
            -- canShow = true
            -- actInfo = act_info
            -- break
            if not actInfoNovice and (act_data:isNovice()) then
                if not act_data:isCompleted() then
                    -- 新手期活动，且活动未完成
                    actInfoNovice = act_info
                else
                    -- 已完成判断是否有正在开启的普通活动
                    local actCfg = globalData.GameConfig:getActivityConfigByRef(act_info.activityName, ACTIVITY_TYPE.COMMON)
                    if actCfg then
                        actInfoNormal = act_info
                        comingsoon = true
                    end
                end
            end
            if not actInfoNormal and not act_data:isNovice() then
                actInfoNormal = act_info
            end
        end
    end

    -- 优先取新手期的活动
    if actInfoNovice then
        actInfo = actInfoNovice
        -- canShow = true
    elseif actInfoNormal then
        actInfo = actInfoNormal
        -- canShow = true
    else
        checkRecent = true
    end

    --2. 如果当前没有正在进行时的活动,遍历检测出距离近期时间内会开启的活动 显示coming soon
    local recentActvityData = {}
    if checkRecent then
        -- 遍历近期开启的活动中是否有我们配置好的活动,有的话加出来，设置成coming soon
        for i = 1, #self.ACTIVITY_INFO do
            local act_info = self.ACTIVITY_INFO[i]
            local data = globalData.GameConfig:getRecentActivityConfigByRef(act_info.activityName)
            if data then
                local newData = {
                    act_info = act_info,
                    data = data
                }
                table.insert(recentActvityData, newData)
            end
        end
    end

    --3. 比较当前时间跟近期会开启的活动时间，选取离得最近的活动展示
    local lastTime = nil
    for i = 1, table.nums(recentActvityData) do
        local data = recentActvityData[i].data
        local act_info = recentActvityData[i].act_info
        local starTimer = util_getymd_time(data.p_start)
        if lastTime == nil or (starTimer < lastTime) then
            lastTime = starTimer
            actInfo = act_info
            comingsoon = true
        -- print("---- lasttime "..lastTime.. " starTimer = "..starTimer)
        -- print("p_reference = "..actInfo.p_reference)
        end
    end

    return actInfo, comingsoon
end

-- 专门用来检测 quest节点
function BottomNode:checkCurrShowQuestNode(info)
    local canShow = false
    local comingSoon = false
    if gLobalActivityManager:checktActivityOpen(info.activityName) then
        -- 检测到当前有quest可以添加
        canShow = true
    elseif info.commingSoon then
        comingSoon = true -- 只有活动关闭 但是comming soon 开启的情况下 需要被设置成 true
        canShow = true
    end
    if canShow then
        if self.m_excludeName[info.activityName] then
            canShow = false
        elseif info.exclude then
            self.m_excludeName[info.exclude] = 1
        end
    end
    return canShow, comingSoon
end

-- 专门用来检测 刮刮卡节点
function BottomNode:checkCurrShowScratchCardsNode(info)
    local canShow = false
    local comingSoon = false
    local act_data = G_GetActivityDataByRef(info.activityName, true)
    if act_data and not act_data:isSleeping() then
        -- 检测到当前活动是否在活动时间内
        canShow = true
    end
    return canShow, comingSoon
end

-- 专门用来检测 比赛节点
function BottomNode:checkCurrShowLeagueNode(info)
    local canShow = false
    local comingSoon = false

    -- 比赛正在开启 和 将要开启的类型
    local openTypeInfo = G_GetMgr(G_REF.LeagueCtrl):getOpenTypeInfo()
    if openTypeInfo[1] then
        canShow = true
    elseif openTypeInfo[2] then
        canShow = true
        comingSoon = true
    end

    return canShow, comingSoon
end

-- 专门用来检测 农场
function BottomNode:checkCurrShowFarmNode(info)
    local canShow = false
    local comingSoon = false

    local farmData = G_GetMgr(G_REF.Farm):getRunningData()
    if farmData then
        canShow = true
    end

    return canShow, comingSoon
end

-- 专门用来检测 等级里程碑
function BottomNode:checkCurrShowLevelRoadNode(info)
    local canShow = false
    local comingSoon = false

    local data = G_GetMgr(G_REF.LevelRoad):getRunningData()
    if data then
        canShow = true
    end
    return canShow, comingSoon
end

-- 用来检测普通节点互斥
function BottomNode:checkExcludeNodeHandle(_info)
    local canShow = true
    if self.m_excludeName[_info.lobbyNodeName] then
        canShow = false
    elseif _info.exclude then
        self.m_excludeName[_info.exclude] = 1
    end
    return canShow
end

return BottomNode
