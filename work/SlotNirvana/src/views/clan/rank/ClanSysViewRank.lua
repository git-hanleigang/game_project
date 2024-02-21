--[[
Author: cxc
Date: 2022-02-21 17:25:47
LastEditTime: 2022-02-21 17:25:48
LastEditors: cxc
Description: 公会 排行 主界面
FilePath: /SlotNirvana/src/views/clan/rank/ClanSysViewRank.lua
--]]
local ClanSysViewRank = class("ClanSysViewRank", BaseView)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ChatConfig = require("data.clanData.ChatConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

-- tag 按钮 enum
local BTN_TAG = {
    RANKING = 1,
    REWARDS = 2,
}

function ClanSysViewRank:initDatas()
    ClanSysViewRank.super.initDatas(self)

    self.m_clanData = ClanManager:getClanData()
    self.m_rankData = self.m_clanData:getClanRankData()

    self.m_signList = {}
    self.m_rankMemberRewardList = {}
end

function ClanSysViewRank:initUI()
    ClanSysViewRank.super.initUI(self)
    
    -- 剩余时间
    self:updateLeftTimeUI()
    self.m_leftTimeScheduler = schedule(self, handler(self, self.updateLeftTimeUI), 1)
    -- tag 按钮state
    self:updateTagState()
    
    self:updateRankInfoUI()
    self:runCsbAction("idle", true) 
end 

-- tag 按钮state
function ClanSysViewRank:updateTagState(_tag)
    self.m_chooseTag = _tag or BTN_TAG.RANKING
    self.m_btnRank:setEnabled(self.m_chooseTag ~= BTN_TAG.RANKING)
    self.m_btnReward:setEnabled(self.m_chooseTag ~= BTN_TAG.REWARDS)

    self.m_listVRanking:setVisible(self.m_chooseTag == BTN_TAG.RANKING)
    self.m_listVRewards:setVisible(self.m_chooseTag == BTN_TAG.REWARDS)
end

function ClanSysViewRank:updateRankInfoUI()
    -- 奖励
    self:updateRankRewardUI()
    -- 排行榜
    self:updateRankListUI()
end

function ClanSysViewRank:initCsbNodes()
    self.m_lbLeftTime = self:findChild("lb_daojishi") -- 倒计时
    self.m_Particle = self:findChild("Particle_1")
    self.m_btnRank = self:findChild("btn_rank")
    self.m_btnReward = self:findChild("btn_reward")
    self.m_listVRanking = self:findChild("listView_ranking")
    self.m_listVRanking:removeAllItems()
	self.m_listVRanking:setTouchEnabled(true)
    self.m_listVRanking:setScrollBarEnabled(false)
    
    self.m_listVRewards = self:findChild("listView_rewards")
    self.m_listVRewards:removeAllItems()
	self.m_listVRewards:setTouchEnabled(true)
    self.m_listVRewards:setScrollBarEnabled(false)
end

function ClanSysViewRank:getCsbName()
    return "Club/csd/RANK/ClubSysRank.csb"
end

----------------------------- 奖励 -----------------------------
function ClanSysViewRank:updateRankRewardUI()
    -- 段位icon描述
    self:updateRankIconDescUI()
    -- 本公会奖励
    self:updateSelfRewardUI()
end

-- 段位icon描述
function ClanSysViewRank:updateRankIconDescUI()
    local spRankIcon = self:findChild("sp_rank_icon")
    local lbRankDesc = self:findChild("lb_rank_id")

    local selfRankInfo = self.m_clanData:getSelfClanRankInfo() 
    local iconPath = ClanManager:getRankDivisionIconPath(selfRankInfo.division)
    util_changeTexture(spRankIcon, iconPath)
    local desc = ClanManager:getRankDivisionDesc(selfRankInfo.division)
    lbRankDesc:setString(desc)
end

-- 本公会奖励
function ClanSysViewRank:updateSelfRewardUI()
    local spLine = self:findChild("sp_line")
    local nodeRankRewards = self:findChild("node_rankRewards")

    local lbCoins = self:findChild("lb_shuzi")
    local spAdd = self:findChild("sp_add")
    local nodeReward = self:findChild("node_reward")
    nodeRankRewards:setVisible(false)
    spLine:setVisible(false)
    nodeReward:removeAllChildren() 
    local selfRankInfo = self.m_rankData:getMyRankInfo()
    local rewardData = self.m_rankData:getRankRewardDataByRank(selfRankInfo:getRank())
    local coins = 0 
    local itemList = {}
    if rewardData then
        coins = rewardData:getCoins()
        itemList = rewardData:getRewardNoCoinsList()
    end

    if coins <= 0 and #itemList <= 0 then
        spLine:setVisible(true)
    else
        nodeRankRewards:setVisible(true)
    end

    lbCoins:setString(util_formatCoins(coins, 20))
    local width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP)
    local itemNode = gLobalItemManager:addPropNodeList(itemList, ITEM_SIZE_TYPE.TOP, 1, width, true)
	nodeReward:addChild(itemNode)
    spAdd:setVisible(#itemList>0)
    local alignUIList = {
        {node = self:findChild("sp_coins")},
        {node = lbCoins, alignX = 5},
        {node = spAdd, alignX = 5},
        {node = nodeReward, alignX = 5, size = cc.size(#itemList * width, width), alignY = 4}
    }
    util_alignCenter(alignUIList)
end
----------------------------- 奖励 -----------------------------

----------------------------- 排行榜 -----------------------------
-- 公会排行
function ClanSysViewRank:updateRankListUI()
    local rankList = self.m_rankData:getRankDataList()
    if #rankList <= 0 then
        return
    end

    self:addRankCellUI(self.m_listVRanking, ClanConfig.RankUpDownEnum.UP, 0)
    self:addRankCellUI(self.m_listVRanking, ClanConfig.RankUpDownEnum.UNCHANGED, 1)
    self:addRankCellUI(self.m_listVRanking, ClanConfig.RankUpDownEnum.DOWN, 2)
    self.m_listVRanking:jumpToTop() 
end

function ClanSysViewRank:addRankCellUI(_listView, _type, _idx)
    local rankList = {}
    if _type == ClanConfig.RankUpDownEnum.UP then
        rankList = self.m_rankData:getRankUpList()
    elseif _type == ClanConfig.RankUpDownEnum.DOWN then
        rankList = self.m_rankData:getRankDownList()
    elseif _type == ClanConfig.RankUpDownEnum.UNCHANGED then
        rankList = self.m_rankData:getRankUnchangedList()
    end
    
    if #rankList <= 0 then
        return
    end

    local layout = _listView:getChildByName("layout".._idx)
    local cellView
    if layout then
        cellView = layout:getChildByName("ClanRankCellContainerUI")
    else
        layout = ccui.Layout:create()
        layout:setName("layout".._idx)
        layout:setTouchEnabled(false)
        cellView = util_createView("views.clan.rank.ClanRankCellContainerUI")
        cellView:setName("ClanRankCellContainerUI")
        layout:addChild(cellView)
        _listView:pushBackCustomItem(layout)
    end
    cellView:updateUI(_type, rankList, _listView:getContentSize().width)

    local size = cellView:getContentSize()
    if _type == ClanConfig.RankUpDownEnum.DOWN then
        cellView:setPositionY(size.height)
    end
    layout:setContentSize(size)
end

-- 本公会成员贡献排行
function ClanSysViewRank:updateMemberRewardListUI()
    local cellViewList = self.m_listVRewards:getItems()
    for i=1, #self.m_rankMemberRewardList do
        local data = self.m_rankMemberRewardList[i]
        self:refreshRankRewardCellUI(i-1, data)
    end
    if #cellViewList > #self.m_rankMemberRewardList then
        self:delOverRankRewardListViewItem(#self.m_rankMemberRewardList+1, #cellViewList)
    end

    self.m_listVRewards:jumpToTop() 
end

function ClanSysViewRank:refreshRankRewardCellUI(_idx, _data)
    local layout = self.m_listVRewards:getItem(_idx)
    local cellView
    if layout then
        cellView = layout:getChildByName("ClanRankMemberCell")
    else
        layout = ccui.Layout:create()
        cellView = util_createView("views.clan.rank.ClanRankMemberCell")
        cellView:setName("ClanRankMemberCell")
        layout:addChild(cellView)
        layout:setContentSize(cc.size(844,72))
        cellView:move(844*0.5, 72*0.5)
        self.m_listVRewards:pushBackCustomItem(layout)
    end
    cellView:updateUI(_data)
end
-- 删除listView溢出的 节点
function ClanSysViewRank:delOverRankRewardListViewItem(_startIdx, _endIdx)
    for i=_startIdx, _endIdx do
        self.m_listVRewards:removeItem(i-1) 
    end
end
----------------------------- 排行榜 -----------------------------

----------------------------- 倒计时 -----------------------------
function ClanSysViewRank:updateLeftTimeUI()
    local expireAt = self.m_rankData:getRankExpireAt()
    if expireAt == -1 then
        self.m_lbLeftTime:setString("LOADING TIME")
        return
    end
    local leftTimeStr, bOver = util_daysdemaining(tonumber(expireAt) / 1000, true)
    if bOver then
        self:clearScheduler()
        return
    end
    
    self.m_lbLeftTime:setString("END IN: " .. leftTimeStr)
end
----------------------------- 倒计时 -----------------------------

function ClanSysViewRank:onEnter()
    -- 引导逻辑
    performWithDelay(self, handler(self, self.dealGuideLogic), 0)
    -- 注册事件
    self:registerListener()
end

function ClanSysViewRank:clickFunc(sender)
    local name = sender:getName()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    
    if name == "btn_rankIcon" then
        -- 段位icon
        ClanManager:showRankBenifitLayer()
    elseif name == "btn_info" then
        -- 查看所有段位 奖励
        ClanManager:popCurDivisionRankRewardInfoLayer()
    elseif name == "btn_legend" then
        -- 最强工会 
        ClanManager:sendeRankTopListDataReq()
    elseif name == "btn_rank" then
        -- 公会排行
        self:updateTagState(BTN_TAG.RANKING)
        ClanManager:sendClanRankReq()
    elseif name == "btn_reward" then
        -- 公会各成员奖励
        self:updateTagState(BTN_TAG.REWARDS)
        ClanManager:sendMemberRankRewardListReq()
    end
end

-- 处理 引导逻辑
function ClanSysViewRank:dealGuideLogic()
    if tolua.isnull(self) then
        return
    end
    
    local bFinish = globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.clanFirstEnterRank.id) -- 第一次进入公会主页
    if bFinish then
        return
    end

    globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.clanFirstEnterRank)

    local nodeRank = self:findChild("Node_rank") -- 所有排名
    local nodeReward = self:findChild("Node_rewards") -- 奖励
    local btnTopTeam = self:findChild("btn_legend") -- 最强公会按钮
    local nodeBenifitEntry = self:findChild("sp_rank_di") -- 权益入口
    local guideNodeList = {nodeRank, nodeReward, btnTopTeam, nodeBenifitEntry}
    ClanManager:showGuideLayer(NOVICEGUIDE_ORDER.clanFirstEnterRank.id, guideNodeList)
end

-- 接收到公会排行信息
function ClanSysViewRank:onRecieveRankInfoEvt()
    self.m_clanData = ClanManager:getClanData()
    self.m_rankData = self.m_clanData:getClanRankData()

    self:updateRankInfoUI()
end

-- 接收到公会成员排名信息
function ClanSysViewRank:onRecieveRankMemberRewardsEvt()
    self.m_rankMemberRewardList = self.m_clanData:getClanMemberList()

    self:updateMemberRewardListUI()
end

-- 请求最强工会排行信息成功
function ClanSysViewRank:onRecieveTopRankEvt()
    ClanManager:popTopRankTeamListLayer()
end

--玩家退出或被踢更新 成员数据
function ClanSysViewRank:deleteMemberByUdidEvt(_udid)
    local itemViewList = self.m_listVRewards:getItems()
    for i=1, #itemViewList do
        local layout = itemViewList[i]
        local cellView = layout:getChildByName("ClanRankMemberCell")
        local memberData = cellView:getData()
        if cellView and memberData:getUdid() == _udid then
            self.m_listVRewards:removeItem(i-1)
            break
        end
    end
end

-- 注册事件
function ClanSysViewRank:registerListener(  )
    gLobalNoticManager:addObserver(self, "onRecieveRankInfoEvt", ClanConfig.EVENT_NAME.RECIEVE_TEAM_RANK_INFO_SUCCESS) -- 接收到公会排行信息
    gLobalNoticManager:addObserver(self, "onRecieveRankMemberRewardsEvt", ClanConfig.EVENT_NAME.RECIEVE_MEMBER_RANK_REWARD_SUCCESS) -- 请求本公会各玩家排行奖励成功
    gLobalNoticManager:addObserver(self, "onRecieveTopRankEvt", ClanConfig.EVENT_NAME.RECIEVE_TEAM_TOP_RANK_LIST_SUCCESS) -- 请求最强工会排行信息成功
    gLobalNoticManager:addObserver(self, "deleteMemberByUdidEvt", ChatConfig.EVENT_NAME.DELETE_DATABASE_MEMBER) --玩家退出或被踢更新 成员数据

    -- -- 关闭公会
    gLobalNoticManager:addObserver(self, function()
        if self.m_Particle then
            self.m_Particle:setVisible(false)
        end
        self:clearScheduler()
    end, ClanConfig.EVENT_NAME.CLOSE_CLAN_HOME_VIEW) 
end

-- 清楚定时器
function ClanSysViewRank:clearScheduler()
    if self.m_leftTimeScheduler then
        self:stopAction(self.m_leftTimeScheduler)
        self.m_leftTimeScheduler = nil
    end
end

function ClanSysViewRank:updateUI()
    if self.m_chooseTag ~= BTN_TAG.REWARDS then
        return
    end

    local lastReqMemDataType = self.m_clanData:getLastReqMemDataType()
    if lastReqMemDataType == "ClanUser"  then
        self:onRecieveRankMemberRewardsEvt()
    end
end

return ClanSysViewRank
