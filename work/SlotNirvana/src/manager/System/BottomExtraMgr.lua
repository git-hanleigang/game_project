--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-07-16 14:53:43
]]
local BottomExtraMgr = class("BottomExtraMgr", BaseSingleton)

local EXTRABOTTOM_CONFIG = {
    -- 扩展按钮具体配置信息
    --[[
        说明 这里是一个顺序表，
        id  代表排序 越小越靠前
        lobbyNodeName 代表节点的名称
        open 代表可这个节点是否能够显示
        activity  代表当前这个是不是活动 false 代表是常驻点位 直接显示添加  true -- 是活动相关，需要判断是否能添加
        activityName 对应服务器上面的活动名称  *** 这个必须跟服务器配置的相同 要用来做判断
        luaFileName 对应的lua文件名称
        commingSoon 活动如果结束了 是否要创建comming soon 状态继续停留在bottom上。（不区分返回大厅的操作）
        exclude 互斥判断 -- 如果A 配置了互斥 B 那么A存在的时候 ，B就不能出现
        ....

        具体逻辑判断为 遍历这张info 表 , 最终得到一个 m_table 作为 bottomNode 最终显示的数据table
    ]]
    [1] = {
        id = 1,
        lobbyNodeName = "DailyBonus",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "LobbyBottom_DailyBonusNode",
        commingSoon = false,
        exclude = "",
        clickName = "DailyBonus"
    },
    [3] = {
        id = 2,
        lobbyNodeName = "LOTTERY",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "LobbyBottom_LotteryNode",
        commingSoon = false,
        exclude = "",
        clickName = "Lottery"
    },
    [7] = {
        id = 3,
        lobbyNodeName = "Deluex",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "Activity_DeluexeNormalNode",
        commingSoon = false,
        exclude = "",
        clickName = "Club",
        mgrLua = "manager.Activity.ActivityDeluxeManager"
    },
    [4] = {
        id = 4,
        lobbyNodeName = "",
        open = true,
        activity = true,
        activityName = ACTIVITY_REF.BingoRush,
        luaFileName = "Activity_BingoRushLobbyNode",
        commingSoon = false,
        exclude = ""
    },
    [5] = {
        id = 5,
        lobbyNodeName = "Clan",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "LobbyBottom_ClanNode",
        commingSoon = false,
        exclude = "",
        clickName = "Team",
        mgrLua = "manager.System.ClanManager"
    },
    [6] = {
        id = 6,
        lobbyNodeName = "Inbox",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "LobbyBottom_InboxExtra",
        commingSoon = false,
        exclude = "",
        clickName = "Inbox",
        mgrLua = "GameModule.Inbox.controller.InboxManager"
    },
    -- [2] = {id = 7, lobbyNodeName = "GEMS", open = true, activity = false, activityName = "", luaFileName = "LobbyBottom_GemsNode", commingSoon = false, exclude = ""},
    [2] = {
        id = 7,
        lobbyNodeName = "VIP",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "LobbyBottom_VIPNode",
        commingSoon = false,
        exclude = "",
        clickName = "Vip"
    },
    [8] = {
        id = 8,
        lobbyNodeName = "DailyMission",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "LobbyBottom_DailyMissionNode",
        commingSoon = false,
        exclude = "",
        clickName = "Mission",
        mgrLua = "manager.System.DailyTaskManager"
    },
    [9] = {
        id = 9,
        lobbyNodeName = "Challenge",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "LobbyBottom_ChallengeNode",
        commingSoon = false,
        exclude = "",
        clickName = "Challenge",
        mgrLua = "activities.Activity_LuckyChallenge.controller.LuckyChallengeManager"
    },
    [10] = {
        id = 10,
        lobbyNodeName = "QuestNewUser",
        open = true,
        activity = true,
        activityName = "Activity_QuestNewUser",
        luaFileName = "Activity_QuestNewUser",
        commingSoon = false,
        exclude = "Activity_Quest",
        clickName = "Quest"
    },
    [11] = {
        id = 11,
        lobbyNodeName = "Quest",
        open = true,
        activity = true,
        activityName = "Activity_Quest",
        luaFileName = "Activity_Quest",
        commingSoon = true,
        exclude = "",
        clickName = "Quest"
    },
    [12] = {
        id = 12,
        lobbyNodeName = "Activity",
        open = true,
        activity = true,
        activityName = "",
        luaFileName = "",
        commingSoon = true,
        exclude = "",
        clickName = ""
    },
    [13] = {
        id = 13,
        lobbyNodeName = "LEAGUES",
        open = true,
        activity = false,
        activityName = ACTIVITY_REF.League,
        luaFileName = "LobbyBottom_LeagueNode",
        commingSoon = true,
        exclude = "",
        clickName = "Leagues"
    },
    [14] = {
        id = 14,
        lobbyNodeName = "ScratchCards",
        open = true,
        activity = true,
        activityName = ACTIVITY_REF.ScratchCards,
        luaFileName = "Activity_ScratchCards",
        commingSoon = false,
        exclude = "",
        clickName = "ScratchCards"
    },
    -- [15] = {
    --     id = 15,
    --     lobbyNodeName = "Farm",
    --     open = true,
    --     activity = false,
    --     activityName = "Farm",
    --     luaFileName = "LobbyBottom_FarmNode",
    --     commingSoon = false,
    --     exclude = "",
    --     clickName = "Farm"
    -- },
    [15] = {
        id = 15,
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
    [16] = {
        id = 16,
        lobbyNodeName = "QuestNew",
        open = true,
        activity = true,
        activityName = "Activity_QuestNew",
        luaFileName = "Activity_QuestNew",
        commingSoon = false,
        exclude = "",
        clickName = "QuestNew",
    }, 
    [17] = {
        id = 17,
        lobbyNodeName = "MonthlyCard",
        open = true,
        activity = false,
        activityName = "",
        luaFileName = "LobbyBottom_MonthlyCard",
        commingSoon = false,
        exclude = "",
        clickName = "MonthlyCard",
    },
    [18] = {
        id = 18,
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

local ACTIVITY_INFO = {
    [1] = {
        activityName = ACTIVITY_REF.Bingo,
        luaFileName = "Activity_Bingo",
        clickName = "Bingo"
    },
    [2] = {
        activityName = ACTIVITY_REF.RichMan,
        luaFileName = "Activity_RichMan",
        clickName = "RichMan"
    },
    [3] = {
        activityName = ACTIVITY_REF.WorldTrip,
        luaFileName = "Activity_WorldTrip",
        clickName = "WorldTrip"
    },
    [4] = {
        activityName = ACTIVITY_REF.DinnerLand,
        luaFileName = "Activity_DinnerLand",
        clickName = "DinnerLand"
    },
    [5] = {
        activityName = ACTIVITY_REF.Blast,
        luaFileName = "Activity_Blast",
        clickName = "Blast"
    },
    [6] = {
        activityName = ACTIVITY_REF.Word,
        luaFileName = "Activity_Word",
        clickName = "Word"
    },
    [7] = {
        activityName = ACTIVITY_REF.CoinPusher,
        luaFileName = "Activity_CoinPusher",
        clickName = "CoinPusher"
    },
    [8] = {
        activityName = ACTIVITY_REF.DiningRoom,
        luaFileName = "Activity_DiningRoom",
        clickName = "DiningRoom"
    },
    [9] = {
        activityName = ACTIVITY_REF.Redecor,
        luaFileName = "Activity_Redecor",
        clickName = "Redecor"
    },
    [10] = {
        activityName = ACTIVITY_REF.Poker,
        luaFileName = "Activity_Poker",
        clickName = "Poker"
    },
    [11] = {
        activityName = ACTIVITY_REF.NewCoinPusher, 
        luaFileName = "Activity_NewCoinPusher", 
        clickName = "NewCoinPusher"
    },
    [12] = {
        activityName = ACTIVITY_REF.PipeConnect, 
        luaFileName = "Activity_PipeConnect", 
        clickName = "PipeConnect"
    },
    [13] = {
        activityName = ACTIVITY_REF.OutsideCave, 
        luaFileName = "Activity_OutsideCave", 
        clickName = "OutsideCave"
    },
    [14] = {
        activityName = ACTIVITY_REF.EgyptCoinPusher, 
        luaFileName = "Activity_EgyptCoinPusher", 
        clickName = "EgyptCoinPusher"
    },
}

--[[
    info -- 配置表信息
    commingsoon :  true false
]]
-- function BottomExtraMgr:ctor()
--     BottomExtraMgr.super.ctor(self)
-- end

function BottomExtraMgr:clearInfos()
    self.m_excludeName = {}
    -- 节点信息 组装数据 data
    self.m_lobbyBottomNodeInfo = {}

    self.m_hasRedPoint = false
end

function BottomExtraMgr:initInfos()
    self:clearInfos()
    -- 初始化节点信息
    self:initLobbyBottomNodeInfo()
    -- 根据节点的顺序排序一下
    table.sort(
        self.m_lobbyBottomNodeInfo,
        function(a, b)
            return tonumber(a.info.id) < tonumber(b.info.id)
        end
    )
end

function BottomExtraMgr:getInfos()
    return self.m_lobbyBottomNodeInfo
end

function BottomExtraMgr:checkRedTip(tbIgnore)
    local isChange, hasRedPoint = false, false
    -- 忽略列表
    tbIgnore = tbIgnore or {}
    for _, _value in ipairs(self.m_lobbyBottomNodeInfo) do
        local _mgr = _value.mgr
        local _bottomKey = _value.info.lobbyNodeName or ""
        if (not tbIgnore[_bottomKey]) and _mgr and _mgr.getLobbyBottomNum then
            local _num = _mgr:getLobbyBottomNum()
            if _num > 0 then
                hasRedPoint = true
                break
            end
        end
    end
    if self.m_hasRedPoint ~= hasRedPoint then
        isChange = true
        self.m_hasRedPoint = hasRedPoint
    end

    return isChange, self.m_hasRedPoint
end

--加载配置信息
function BottomExtraMgr:initLobbyBottomNodeInfo()
    for i = 1, #EXTRABOTTOM_CONFIG do
        local data = {}
        local info = clone(EXTRABOTTOM_CONFIG[i])
        local tablenums = table.nums(self.m_lobbyBottomNodeInfo) + 1
        if info.open then
            data.info = info
            data.commingsoon = false
            if (info.mgrLua or "") ~= "" then
                data.mgr = require(info.mgrLua):getInstance()
            end
            if info.activity then
                local canAdd = false
                -- 活动开启或者 comming soon 状态开启 都把活动添显示出来
                -- csc 2020年08月21日 修改为遍历查找当前能显示的活动
                if info.lobbyNodeName == "Activity" then
                    local newData, comingSoon = self:checkCurrShowActivityNode()
                    if newData then
                        -- 赋值两个值
                        data.info.activityName = newData.activityName
                        data.info.luaFileName = newData.activityName
                        data.info.clickName = newData.clickName

                        data.mgr = G_GetMgr(newData.activityName)
                        data.commingsoon = comingSoon
                        self.m_lobbyBottomNodeInfo[tablenums] = data
                    end
                else
                    if info.lobbyNodeName == "ScratchCards" then
                        local canShow, comingSoon = self:checkCurrShowScratchCardsNode(info)
                        if canShow then
                            data.commingsoon = comingSoon
                            self.m_lobbyBottomNodeInfo[tablenums] = data
                        end
                    else
                        if info.lobbyNodeName == "Quest" then
                            if G_GetMgr(ACTIVITY_REF.QuestNew):isRunning() then
                                info.commingSoon = false
                            end
                        end
                        local canShow, comingSoon = self:checkCurrShowQuestNode(info)
                        if canShow then
                            data.mgr = G_GetMgr(ACTIVITY_REF.Quest)
                            data.commingsoon = comingSoon
                            self.m_lobbyBottomNodeInfo[tablenums] = data
                        end
                    end
                end
            else
                if info.lobbyNodeName == "LEAGUES" then
                    local canShow, comingSoon = self:checkCurrShowLeagueNode(info)
                    if canShow then
                        data.commingsoon = comingSoon
                        self.m_lobbyBottomNodeInfo[tablenums] = data
                    end
                elseif info.lobbyNodeName == "DeluxeGame" then
                    local gameInfo = globalDeluxeManager:getDeluxeGameInfo()
                    data.info.activityName = gameInfo.actRef
                    data.info.lobbyNodeName = gameInfo.lobbyEntryNodeName
                    data.info.luaFileName = gameInfo.lobbyEntryLuaName
                    self.m_lobbyBottomNodeInfo[tablenums] = data
                elseif info.lobbyNodeName == "Farm" then
                    local canShow, comingSoon = self:checkCurrShowFarmNode(info)
                    if canShow then
                        data.commingsoon = comingSoon
                        self.m_lobbyBottomNodeInfo[tablenums] = data
                    end
                elseif info.lobbyNodeName == "LevelRoad" then
                    local canShow, comingSoon = self:checkCurrShowLevelRoadNode(info)
                    if canShow then
                        data.commingsoon = comingSoon
                        self.m_lobbyBottomNodeInfo[tablenums] = data
                    end
                else
                    self.m_lobbyBottomNodeInfo[tablenums] = data
                end
            end
        end
    end
end

-- 专门用来检测 活动节点
function BottomExtraMgr:checkCurrShowActivityNode()
    --配置了当前的所有活动
    -- isRunning 代表当前活动有数据，当前等级允许running 这个活动
    local canShow = false
    local actInfo = nil
    -- 普通活动信息
    local actInfoNormal = nil
    -- 新手期活动数据
    local actInfoNovice = nil
    local comingsoon = false

    --1. 检测当前是否有正在进行时的活动
    for i = 1, #ACTIVITY_INFO do
        local act_info = ACTIVITY_INFO[i]
        local act_data = G_GetActivityDataByRef(act_info.activityName, true)
        if act_data then
            -- 检测到当前活动是否在活动时间内,不用考虑等级是否到达
            -- canShow = true
            -- actInfo = act_info
            -- break
            if not actInfoNovice and (act_data:isNovice() and not act_data:isCompleted()) then
                actInfoNovice = act_info
            elseif not actInfoNormal and not act_data:isNovice() then
                actInfoNormal = act_info
            end
        end
    end

    -- 优先取新手期的活动
    if actInfoNovice then
        actInfo = actInfoNovice
        canShow = true
    elseif actInfoNormal then
        actInfo = actInfoNormal
        canShow = true
    end

    --2. 如果当前没有正在进行时的活动,遍历检测出距离近期时间内会开启的活动 显示coming soon
    local recentActvityData = {}
    if canShow == false then
        -- 遍历近期开启的活动中是否有我们配置好的活动,有的话加出来，设置成coming soon
        for i = 1, #ACTIVITY_INFO do
            local act_info = ACTIVITY_INFO[i]
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
function BottomExtraMgr:checkCurrShowQuestNode(info)
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
function BottomExtraMgr:checkCurrShowScratchCardsNode(info)
    local canShow = false
    local comingSoon = false
    local act_data = G_GetActivityDataByRef(info.activityName, true)
    if act_data and not act_data:isSleeping() then
        -- 检测到当前活动是否在活动时间内
        canShow = true
    end
    -- if not canShow then
    --     local data = globalData.GameConfig:getRecentActivityConfigByRef(info.activityName)
    --     if data then
    --         canShow = true
    --         comingSoon = true
    --     end
    -- end
    return canShow, comingSoon
end

-- 专门用来检测 比赛节点
function BottomExtraMgr:checkCurrShowLeagueNode(info)
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
function BottomExtraMgr:checkCurrShowFarmNode(info)
    local canShow = false
    local comingSoon = false

    local farmData = G_GetMgr(G_REF.Farm):getRunningData()
    if farmData then
        canShow = true
    end

    return canShow, comingSoon
end

-- 专门用来检测 等级里程碑
function BottomExtraMgr:checkCurrShowLevelRoadNode(info)
    local canShow = false
    local comingSoon = false

    local data = G_GetMgr(G_REF.LevelRoad):getRunningData()
    if data then
        canShow = true
    end
    return canShow, comingSoon
end

return BottomExtraMgr
