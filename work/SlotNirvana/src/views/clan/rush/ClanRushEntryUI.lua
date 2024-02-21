--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-06-27 16:12:01
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-06-27 18:16:45
FilePath: /SlotNirvana/src/views/clan/rush/ClanRushEntryUI.lua
Description: 公会rush 入口
--]]
local ClanRushEntryUI = class("ClanRushEntryUI", BaseView)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanRushEntryUI:initDatas()
    ClanRushEntryUI.super.initDatas(self)

    local clanData = ClanManager:getClanData()
    self.m_rushData = clanData:getTeamRushData()
    self.m_curTaskData = self.m_rushData:getCurTaskData()
    -- 集卡新手期 不显示 rush
    self.m_bCardNovice = CardSysManager:isNovice()

    gLobalNoticManager:addObserver(self, "onRecieveRushInfoEvt", ClanConfig.EVENT_NAME.RECIEVE_TEAM_RUSH_SUCCESS) -- 接收到公会rush信息成功
    gLobalNoticManager:addObserver(self, "onDealGuideLogicEvt", ClanConfig.EVENT_NAME.NOTIFY_RUSH_DEAL_GUIDE) -- 通知rush进行新手引导处理
end

-- 初始化节点
function ClanRushEntryUI:initCsbNodes()
    self.m_nodeCommonSoon = self:findChild("node_loading")
    self.m_nodeAct = self:findChild("node_rush")

    self.m_lbTaskIdx = self:findChild("lb_taskSeqIdx")
    self.m_spTaskIcon = self:findChild("sp_taskIcon")
    self.m_spProg = self:findChild("sp_prog")
    self.m_lbProg = self:findChild("lb_prog")
    self.m_lbLeftTime = self:findChild("txt_time_1")
    self.m_spProgSize = self.m_spProg:getContentSize()
end

function ClanRushEntryUI:getCsbName()
    return "Club/csd/Rush/node_rush_entry.csb"
end

function ClanRushEntryUI:initUI()
    ClanRushEntryUI.super.initUI(self)

    self:updateUI()
end

function ClanRushEntryUI:updateUI()
    self:clearScheduler()

    -- 更新活动commonsoon显隐
	self:updateCommonSoonVisible()
    -- 活动基本信息UI
    self:updateRushInfoUI()
end

-- 更新活动commonsoon显隐
function ClanRushEntryUI:updateCommonSoonVisible()
    local bRunning = self.m_rushData:isRunning()

    self.m_nodeCommonSoon:setVisible(not bRunning or self.m_bCardNovice)
    self.m_nodeAct:setVisible(bRunning and not self.m_bCardNovice)
end

-- 活动基本信息UI
function ClanRushEntryUI:updateRushInfoUI()
    local bRunning = self.m_rushData:isRunning()
    if not bRunning or self.m_bCardNovice then
        return
    end

    if not self.m_bActIdle then
        self:runCsbAction("idle", true)
        self.m_bActIdle = true
    end

    self:updateLeftTimeUI()
    self.m_scheduler = schedule(self, handler(self, self.updateLeftTimeUI), 1)
    -- 任务 奖励气泡
    self:updateBubbleUI()
    -- 任务 阶段
    self:updateSeqUI()
    -- 任务 进度
    self:updateProgUI()
    -- 任务 图标
    self:updateTaskIconUI()
    -- 任务 奖励图标
    self:updateGiftIconUI()
end

function ClanRushEntryUI:updateLeftTimeUI()
    local expireAt = self.m_rushData:getExpireAt()
    local leftTimeStr, bOver = util_daysdemaining(expireAt)
    if bOver then
        -- self:updateUI()
        self:clearScheduler()
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.CLAN_ENTRY_REFRESH)
        return
    end
    
    self.m_lbLeftTime:setString(leftTimeStr)
end

-- 任务 奖励气泡
function ClanRushEntryUI:updateBubbleUI()
    if not self.m_bubbleView then
        local parent = self:findChild("node_bubble")
        local view = util_createView("views.clan.rush.ClanRushRewardBubble", self.m_curTaskData)
        parent:addChild(view)
        self.m_bubbleView = view
    else
        self.m_bubbleView:updateUI(self.m_curTaskData)
    end
end

-- 任务 阶段
function ClanRushEntryUI:updateSeqUI()
    local curIdx = self.m_rushData:getCurTaskIdx()
    local count = self.m_rushData:getTaskListCount()
    self.m_lbTaskIdx:setString(curIdx .. "/" .. count)
end
-- 任务 进度
function ClanRushEntryUI:updateProgUI()
    local curCount = self.m_curTaskData:getCurCount()
    local needCount = self.m_curTaskData:getNeedCount()
    self.m_lbProg:setString(curCount .. "/" .. needCount)

    local progress = 0
    if needCount > 0 then
        progress = curCount / needCount
    end
    self.m_spProg:setContentSize(self.m_spProgSize.width * progress, self.m_spProgSize.height)
end
-- 任务 图标
function ClanRushEntryUI:updateTaskIconUI()
    local imgPath = self.m_curTaskData:getTaskIconPath()
    if imgPath == self.m_imgPath then
        return
    end
    self.m_imgPath = imgPath
    ClanManager:changeTeamRushTaskIcon(self.m_spTaskIcon, imgPath)
end
-- 任务 奖励图标
function ClanRushEntryUI:updateGiftIconUI()
    if not self.m_giftView then
        local nodeGift = self:findChild("node_gift")
        self.m_giftView = util_createView("views.clan.rush.ClanRushTaskGiftUI", true)
        nodeGift:addChild(self.m_giftView)
    end
    local curIdx = self.m_curTaskData:getTaskIdx()
    local bFinish = self.m_curTaskData:checkTaskFinish()
    self.m_giftView:updateUI(curIdx, bFinish)
end

-- 清楚定时器
function ClanRushEntryUI:clearScheduler()
    if self.m_scheduler then
        self:stopAction(self.m_scheduler)
        self.m_scheduler = nil
    end
end

function ClanRushEntryUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_rushEntry" then
        ClanManager:popTeamRushMainLayer()
    elseif name == "btn_gift" and self.m_bubbleView then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_bubbleView:switchBubbleVisible()
    end
end

-- 接收到公会rush信息成功evt
function ClanRushEntryUI:onRecieveRushInfoEvt()
    if self.m_bCardNovice then
        return
    end
    
    local clanData = ClanManager:getClanData()
    self.m_rushData = clanData:getTeamRushData()
    self.m_curTaskData = self.m_rushData:getCurTaskData()

    self:updateUI()
    if self.m_bCheckGuideLogic then
        self:checkPopTeamTaskReportLayer()
    end
end

-- 处理 引导逻辑
function ClanRushEntryUI:onDealGuideLogicEvt()
    self.m_bCheckGuideLogic = true
    local bRunning = self.m_rushData:isRunning()
    if not bRunning or self.m_bCardNovice then
        return
    end

    local bFinish = globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.clanFirstEnterRush.id) -- 第一次进入公会rush
    if bFinish then
        -- 新完成 任务弹出 公会Rush新任务提示弹板
        self:checkPopTeamTaskReportLayer()
        return
    end

    globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.clanFirstEnterRush)
    -- globalData.NoviceGuideFinishList[#globalData.NoviceGuideFinishList + 1] = NOVICEGUIDE_ORDER.clanFirstEnterRush.id 

    local guideNodeList = {self}
    ClanManager:showGuideLayer(NOVICEGUIDE_ORDER.clanFirstEnterRush.id, guideNodeList)
end

-- 检测新完成 任务弹出 公会Rush新任务提示弹板
function ClanRushEntryUI:checkPopTeamTaskReportLayer()
    local bCompleteCurTask = self.m_rushData:isCompleteCurTask()
    if not bCompleteCurTask then
        return
    end

    ClanManager:ClanRushTaskReportLayer()
end

return ClanRushEntryUI