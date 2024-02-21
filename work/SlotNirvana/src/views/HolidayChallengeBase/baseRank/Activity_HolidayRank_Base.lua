-- 集卡 排行榜主界面

local CardRankConfig = require("views.Card.CardRank202301.CardRankConfig")
local BaseRankUI = require("src.baseRank.BaseRankUI")
local Activity_HolidayRank_Base = class("Activity_HolidayRank_Base", BaseRankUI)

function Activity_HolidayRank_Base:ctor()
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    Activity_HolidayRank_Base.super.ctor(self)
end 

function Activity_HolidayRank_Base:initDatas()
    Activity_HolidayRank_Base.super.initDatas(self)
    self:setBgm(self.m_activityConfig.RESPATH.MAIN_BGM_MP3)
end

function Activity_HolidayRank_Base:initUI()
    Activity_HolidayRank_Base.super.initUI(self)
    self:setExtendData("HolidayChallengeRank")
    self.m_lb_time = self:findChild("lb_daojishi")
    self:onTick()
    self.m_btnClose = self:findChild("btn_close")
    self:sendHolidayChallengePopupLog()
end

function Activity_HolidayRank_Base:sendRankRequestAction()
    G_GetMgr(ACTIVITY_REF.HolidayChallenge):sendActionRank()
end

function Activity_HolidayRank_Base:getRefName()
    return ACTIVITY_REF.HolidayChallenge
end

function Activity_HolidayRank_Base:getCsbName()
    return self.m_activityConfig.RESPATH.RANK_LAYER
end

function Activity_HolidayRank_Base:getRankTitlePath()
    return self.m_activityConfig.RESPATH.RANK_TITLE_NODE
end

function Activity_HolidayRank_Base:getUserCellPath()
    return self.m_activityConfig.RESPATH.RANK_PLAYER_ITEM_NODE
end

function Activity_HolidayRank_Base:getRewardCellPath()
    return self.m_activityConfig.RESPATH.RANK_REWARD_ITEM_NODE
end

function Activity_HolidayRank_Base:getCoinMaxLen()
    return 8
end
function Activity_HolidayRank_Base:getRankTimerPath()
    return nil
end

function Activity_HolidayRank_Base:getUserCellSize()
    return cc.size(830, 99)
end

function Activity_HolidayRank_Base:getRewardCellSize()
    return cc.size(830, 99)
end

function Activity_HolidayRank_Base:getTopThreeCellLuaPath()
    local path = "views.HolidayChallengeBase.baseRank.Activity_HolidayRank_BaseTopThreeCell"
    if self.m_activityConfig and self.m_activityConfig.CODE_PATH.RANK_TOP_THREE_NODE then
        path = self.m_activityConfig.CODE_PATH.RANK_TOP_THREE_NODE
    end
    return path
end

function Activity_HolidayRank_Base:getRankEdge()
    local offsetY = -2.5
    if not self.rankListTopY or not self.rankListBottomY then
        local size = self.userList:getSize()
        local posY = self.userList:getPositionY()
        local cell_size = self.myRankCell:getContentSize()
        self.rankListTopY = posY + size.height / 2 - cell_size.height / 2
        self.rankListBottomY = posY - size.height / 2 + cell_size.height / 2 + offsetY
    end
    return self.rankListTopY, self.rankListBottomY
end

function Activity_HolidayRank_Base:onTick()
    local function tick()
        local act_ata = G_GetMgr(ACTIVITY_REF.HolidayChallengeRank):getRunningData()
        if not act_ata then
            if self.schedule_timer then
                self:stopAction(self.schedule_timer)
                self.schedule_timer = nil
            end
            self:closeUI(
                function()
                    -- 打开查看了 玩家信息板子关闭
                    local userMatonLayer = gLobalViewManager:getViewByExtendData("UserInfoMation")
                    if not tolua.isnull(userMatonLayer) then
                        userMatonLayer:closeUI()
                    end
                end
            )
            return
        end
        local left_time = act_ata:getLeftTime()
        if self.m_lb_time then
            local expireAt = act_ata:getExpireAt()
            local leftTime = math.max(expireAt, 0)
            local timeStr, isOver ,isFullDay = util_daysdemaining(leftTime,true)
            self.m_lb_time:setString(timeStr)
        end
        if not left_time or left_time <= 0 then
            if self.schedule_timer then
                self:stopAction(self.schedule_timer)
                self.schedule_timer = nil
            end
            self:closeUI(
                function()
                    -- 打开查看了 玩家信息板子关闭
                    local userMatonLayer = gLobalViewManager:getViewByExtendData("UserInfoMation")
                    if not tolua.isnull(userMatonLayer) then
                        userMatonLayer:closeUI()
                    end
                end
            )
        end
    end

    if not self.schedule_timer then
        self.schedule_timer = util_schedule(self, tick, 1)
    end

    tick()
end

-- 弹框日志
function Activity_HolidayRank_Base:sendHolidayChallengePopupLog()
    -- 发送打点日志
    local entryType = "lobby"
    local curMachineData = globalData.slotRunData.machineData
    if curMachineData then
        entryType = curMachineData.p_name
    end
    if not entryType or entryType == "" then
        entryType = "lobby"
    end
    local type = "Open"
    local pageName = "PushPage"
    local logManager = gLobalSendDataManager:getHolidayChallengeActivity()
    if logManager then
        logManager:sendHolidayChallengePopupLog(type, pageName, entryType)
    end
end

return Activity_HolidayRank_Base

