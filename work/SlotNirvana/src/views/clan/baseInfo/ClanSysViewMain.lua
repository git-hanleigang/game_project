--[[
Author: cxc
Date: 2021-02-03 14:22:11
LastEditTime: 2021-07-26 17:32:47
LastEditors: Please set LastEditors
Description: 公会主界面
FilePath: /SlotNirvana/src/views/clan/baseInfo/ClanSysViewMain.lua
--]]
local ClanSysViewMain = class("ClanSysViewMain", util_require("base.BaseView"))
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanSysViewMain:initUI(_homeView)
    local csbName = "Club/csd/Main/ClubSysMain.csb"
    self:createCsbNode(csbName)

    self.m_homeView = _homeView
    self.m_clanData = ClanManager:getClanData()
    self.m_bubbleTip = {}

    self.m_taskLeftTime = 0
    self.m_challengeActLeftTime = 0
    self.m_schedule = schedule(self, handler(self, self.onSecUpdate), 1)

    self.m_bFinishClanTask = false -- 公会点数是不是满了

    self.m_preMyPoints = -1
    self.m_preTeamPoints = -1

    -- 隐藏气泡
    local spBubbleP = self:findChild("sp_qipao1")
    local spBubbleK = self:findChild("sp_qipao2")
    self:changeBubbleGZorder(spBubbleP)
    spBubbleP:setVisible(false)
    spBubbleK:setVisible(false)

    -- 触摸mask
    local touchMask = self:findChild("touch_mask")
    touchMask:setContentSize(display.size)
    touchMask:setScale(10)
    self:addClick(touchMask)
    touchMask:setSwallowTouches(false)

    self:updateUI()
    self.m_bInit = true
end

function ClanSysViewMain:onEnter()
    self:registerListener()
      
    self:playCsbIdleAction()
end

function ClanSysViewMain:updateUI()
    local taskData = self.m_clanData:getTaskData() or {}
    local myPoints = taskData.myPoints or 0
    local curPoints = taskData.current or 0
    
    -- node_personalrewards 个人奖励
    if myPoints > self.m_preMyPoints then
        self:updatePersonalUI()
    end
    -- node_keyprocess 解锁进度(公会任务)
    if curPoints > self.m_preTeamPoints then
        self:updateClanTaskProgUI()
    end
    -- node_mission --任务(挑战活动)
    self:updateActRushUI()

    self.m_preMyPoints = myPoints
    self.m_preTeamPoints = curPoints
end

-- node_personalrewards 个人奖励
function ClanSysViewMain:updatePersonalUI()
    local rewardList = self.m_clanData:getTaskRewardList() -- 阶段奖励
    dump(rewardList)
    local myCurRewardInfo = rewardList[1] -- 我当前可以领取的阶段奖励信息 默认第一个
    local taskData = self.m_clanData:getTaskData() or {}
    -- 当前 宝箱 和距离下个 宝箱的点数
    local nextGearPoints = 0
    for i=1,6 do
        local rewardInfo = rewardList[i]
        if rewardInfo then
            -- 可以领取 
            if rewardInfo.isCanCollect then
                myCurRewardInfo = rewardInfo
            elseif nextGearPoints == 0 then
                nextGearPoints = rewardInfo.points or 0
            end
        end 
    end

    -- 个人点数
    local myPoints = taskData.myPoints or 0
    local lbMyPoints = self:findChild("font_baoxiangprocess_num")
    lbMyPoints:setString(util_getFromatMoneyStr(myPoints))
    util_scaleCoinLabGameLayerFromBgWidth(lbMyPoints, 68)

    -- 奖励
    for i = 1, 6 do
        local rewardInfo = rewardList[i]
        if rewardInfo then
            self:initBoxRewardByIdx(i, rewardInfo, myCurRewardInfo)
        end
    end

    -- 当前可领取的宝箱奖励
    self:initCurRewardUI(myCurRewardInfo)
end

-- 阶段宝箱UI
function ClanSysViewMain:initBoxRewardByIdx(_idx, _rewardInfo, _curRewardInfo)
    local nodeBox = self:findChild("node_baoxiang" .. _idx)
    if not nodeBox then
        return
    end
    local chest_data = G_GetMgr(ACTIVITY_REF.TeamChestLoading):getRunningData()

    -- 宝箱
    local nodeRewardParent = self:findChild("baoxiang" .. _idx)
    if chest_data then
        local sp_new = nodeBox:getChildByName("sp_new")
        if sp_new then
            sp_new:setVisible(true)
        end
    end
    local boxView = nodeRewardParent:getChildByName("ClanBoxReward")
    if not boxView then
        boxView = util_createView("views.clan.baseInfo.ClanBoxReward", _idx)
        boxView:addTo(nodeRewardParent)
    end
    boxView:checkPlayAni(_idx == (_curRewardInfo.level + 1))

    -- 当前阶段点数
    local lbPoints = nodeBox:getChildByName("font_clubchestpoints") 
    lbPoints:setVisible(true) 
    lbPoints:setString(util_getFromatMoneyStr(tonumber(_rewardInfo.points) or 0))
    util_scaleCoinLabGameLayerFromBgWidth(lbPoints, 64) 
    local lbPointsBase = nodeBox:getChildByName("font_basechest")
    lbPointsBase:setVisible(false)

    -- 增加奖励气泡
    if not self.m_bubbleTip[_idx] then
        local view = util_createView("views.clan.baseInfo.ClanBoxRewardBubbleTip", _rewardInfo)
        local refNode = self:findChild("btn_box" .. _idx)
        local refPosW = refNode:convertToWorldSpaceAR(cc.p(0,60))
        local refPosL = nodeBox:convertToNodeSpaceAR(refPosW)
        view:addTo(nodeBox)
        view:move(refPosL.x ,refPosL.y)
        if _idx == 6 and view then
            view:setScale(0.75)
        end
        self.m_bubbleTip[_idx] = view
    end

    -- 进度
    local percent = 0
    if _curRewardInfo.level > _rewardInfo.level then
        percent = 100
    elseif _curRewardInfo.level == _rewardInfo.level then
        percent = self:getCurPhasePointsProg()
    end
    local progBar = self:findChild("LoadingBar_" .. _idx)
    if progBar then
        progBar:setPercent(percent)
    end
end

-- 当前宝箱的奖励UI
function ClanSysViewMain:initCurRewardUI(_rewardInfo)
    if not _rewardInfo then
        return
    end
    
    -- 金币
    local lbCoins = self:findChild("font_coin") -- 金币
    lbCoins:setString(util_formatCoins(tonumber(_rewardInfo.coins), 30))
    util_alignCenter(
        {
            {node = self:findChild("sp_coinIcon")},
            {node = lbCoins, alignX = 5}
        }
    )

    -- 宝箱图片
    local nodeCurBox = self:findChild("node_boxBig") 
    nodeCurBox:removeChildByName("ClanBoxReward")
    local boxView = util_createView("views.clan.baseInfo.ClanBoxReward", _rewardInfo.level)
    if _rewardInfo.level == 6 then
        boxView:setScale(0.7)
    end
    boxView:addTo(nodeCurBox) 
    
    -- 道具列表
    local nodeReward = self:findChild("node_rewards") -- cur奖励
    nodeReward:removeChildByName("NodeRewards")
    local sourceW = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP) + 10
    local items = {}
    for _idx, _item in ipairs(_rewardInfo.items) do
        if _item and _item.p_icon ~= "Coins" then
            table.insert(items, _rewardInfo.items[_idx])
        end
    end
    local shopItemUI = gLobalItemManager:addPropNodeList(items, ITEM_SIZE_TYPE.TOP, 1, sourceW)
    if shopItemUI then
         shopItemUI:setName("NodeRewards")
         shopItemUI:addTo(nodeReward)
         if #items > 6 then
            shopItemUI:setScale(0.8)
         end
    end

    -- 宝箱文本显示
    local nodeBox = self:findChild("node_baoxiang" .. _rewardInfo.level)
    local lbPoints = nodeBox:getChildByName("font_clubchestpoints") -- 当前阶段点数
    local lbPointsBase = nodeBox:getChildByName("font_basechest")
    local spClubIcon = nodeBox:getChildByName("sp_clubIcon")
    lbPoints:setVisible(false)
    lbPointsBase:setVisible(true)
    spClubIcon:setVisible(false)
end

-- node_keyprocess 解锁进度(公会任务)
function ClanSysViewMain:updateClanTaskProgUI()
    local taskData = self.m_clanData:getTaskData() or {}

    local curPoints = taskData.current or 0
    local totalPoints = taskData.total or 0

    -- 进度文本    
    local lbProg = self:findChild("font_keyprocess")
    lbProg:setString(util_getFromatMoneyStr(curPoints) .. "/" .. util_getFromatMoneyStr(totalPoints))

    -- 进度bar
    local percent = 0
    if totalPoints > 0 then
        percent = math.floor(curPoints / totalPoints * 100)
    end
    local progBar = self:findChild("bar_keyprocess1")
    local progBar_ef = self:findChild("bar_keyprocess2")
    progBar:setPercent(percent)
    progBar_ef:setPercent(percent)

    if curPoints >= totalPoints then 
        self.m_bFinishClanTask = true
    end

    -- 倒计时
    self.m_taskLeftTime = self.m_clanData:getClanLeftTime()
    self:updateClanTaskLeftTimeUI()
end
-- node_keyprocess 解锁进度 倒计时
function ClanSysViewMain:updateClanTaskLeftTimeUI()
    local expireAt  = self.m_clanData:getClanTaskExpireAt()
    local lbTime = self:findChild("font_time")
    local timeStr = util_daysdemaining(expireAt, true)
    lbTime:setString(timeStr)
end

-- node_mission 任务(挑战活动)
function ClanSysViewMain:updateActRushUI(_isInit)
    if self.m_bInit and not _isInit then
        return
    end
    local parent = self:findChild("node_rush")
    parent:removeAllChildren()

    local clanData = ClanManager:getClanData()
    local rushData = clanData:getTeamRushData()
    local isRushRunning = rushData:isRunning()
    local duelData = clanData:getClanDuelData()
    local isDuelRunning = duelData:isRunning()        
    if isDuelRunning then
        local view = util_createView("views.clan.duel.ClanDuelEntryUI")
        view:addTo(parent)
    else
        local view = util_createView("views.clan.rush.ClanRushEntryUI")
        view:addTo(parent)
    end
end

function ClanSysViewMain:onSecUpdate()
    if self.m_taskLeftTime > 0 then
        self.m_taskLeftTime = self.m_taskLeftTime - 1
        self:updateClanTaskLeftTimeUI(self.m_taskLeftTime)
    end
end

-- 改变气泡显隐
function ClanSysViewMain:changeBubbleTipVisible(_nodeName)
    if self.m_actRunning then
        return
    end

    self.m_actRunning = true

    local spBubble1 = self:findChild("sp_qipao1")
    local spBubble2 = self:findChild("sp_qipao2")
    local actNode = self:findChild("node_personalrewards")
    actNode:stopAllActions()

    local dealNode = _nodeName == "sp_qipao1" and spBubble1 or spBubble2

    local visibleNode = nil
    if spBubble1:isVisible() then
        visibleNode = spBubble1
    elseif spBubble2:isVisible() then
        visibleNode = spBubble2
    end

    local showDealNode = function()
        dealNode:setVisible(true)
        self:runCsbAction("start", false, function()
            performWithDelay(actNode, function()
                self:changeBubbleTipVisible(_nodeName)
            end, 3)
            self:runCsbAction("idle")
            self.m_actRunning = false
        end, 60)
    end

    if visibleNode then
        self:runCsbAction("over", false, function()
            visibleNode:setVisible(false)
            if visibleNode == dealNode then
                self.m_actRunning = false
                self:playCsbIdleAction()
                return
            end

            showDealNode()
        end, 60)    
    else
        showDealNode()
    end

end

function ClanSysViewMain:hideBubbleTipVisible()
    local spBubble1 = self:findChild("sp_qipao1")
    local spBubble2 = self:findChild("sp_qipao2")
    local actNode = self:findChild("node_personalrewards")
    actNode:stopAllActions() 
    self.m_actRunning = false 
    if not spBubble1:isVisible() and not spBubble2:isVisible() then
        return
    end

    spBubble1:setVisible(false)
    spBubble2:setVisible(false)
    self:playCsbIdleAction()
end

-- 播放 静态 act
function ClanSysViewMain:playCsbIdleAction()
    local csbName = "idle2"
    if self.m_bFinishClanTask then
        -- 公会点数满了 播放另一个
        csbName = "idle3"
    end
    
    self:runCsbAction(csbName, true)
end

function ClanSysViewMain:clickFunc(sender)
    local name = sender:getName()
    if name ~= "touch_mask" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    end

    if name == "btn_info1" then
        -- 个人奖励 规则按钮
        self:changeBubbleTipVisible("sp_qipao2")
    elseif name == "btn_info2" then
        -- 解锁进度 规则按钮
        self:changeBubbleTipVisible("sp_qipao1")
    elseif name == "touch_mask" then
        -- 隐藏 tip
        self:hideBubbleTipVisible()
        -- 隐藏box tip
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.HIDE_OTHER_BUBBLE_TIP_VIEW)
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.HIDE_RUSH_GIT_BUBBLE_TIP)
    elseif string.find(name, "btn_box") then
        local idx = string.sub(name, -1)
        local view = self.m_bubbleTip[tonumber(idx)]
        if view then
            view:switchShowState()
        end
    end
end

-- 清楚定时器
function ClanSysViewMain:clearScheduler()
    if self.m_schedule then
        self:stopAction(self.m_schedule)
        self.m_schedule = nil
    end
end

-- 处理 引导逻辑
function ClanSysViewMain:dealGuideLogic()
    local bFinish = globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.clanFirstEnterMain.id) -- 第一次进入公会主页
    if bFinish then
        -- 弹出 开启宝箱时间变化提示弹板
        -- ClanManager:popOpenTimeChangeLayer()
        if self.m_clanData:getUserIdentity() == ClanConfig.userIdentity.LEADER then
            self:checkFirstNewEditPanelGuide()
            return
        end
        -- 检查 公会rush 新手引导
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.NOTIFY_RUSH_DEAL_GUIDE)
        return
    end

    globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.clanFirstEnterMain)
    globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.clanFirstCheckNewEditMain) -- 老公会才需要看新版修改公会信息界面
    globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.clanFirstCheckNewEditPanel) -- 老公会才需要看新版修改公会信息界面
    -- globalData.NoviceGuideFinishList[#globalData.NoviceGuideFinishList + 1] = NOVICEGUIDE_ORDER.clanFirstEnterMain.id 

    local nodeBaseInfo = self.m_homeView:findChild("node_info") -- 公会基本信息按钮
    local nodeTeamPoints = self:findChild("node_keyprocess") -- 公会points 解锁进度 底板
    local nodePerPoints = self:findChild("node_currentbaoxiang") -- 个人points 进度 底板
    local nodePerBox = self:findChild("node_baoxiangprocess") -- 个人points 宝箱奖励
    local guideNodeList = {nodeBaseInfo, nodeTeamPoints, nodePerPoints, nodePerBox}
    ClanManager:showGuideLayer(NOVICEGUIDE_ORDER.clanFirstEnterMain.id, guideNodeList)
end
function ClanSysViewMain:checkFirstNewEditPanelGuide()
    local bFinish = globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.clanFirstCheckNewEditMain.id) -- 老公会才需要看新版修改公会信息界面
    if bFinish then
        -- 检查 公会rush 新手引导
        gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.NOTIFY_RUSH_DEAL_GUIDE)
        return
    end
    
    globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.clanFirstCheckNewEditMain) -- 老公会才需要看新版修改公会信息界面
    local nodeBaseInfo = self.m_homeView:findChild("node_info") -- 公会基本信息按钮
    ClanManager:showGuideLayer(NOVICEGUIDE_ORDER.clanFirstCheckNewEditMain.id, {nodeBaseInfo})
end

-- 获取 距离下一档位的进度
function ClanSysViewMain:getCurPhasePointsProg()
    local taskData = self.m_clanData:getTaskData() -- 任务数据
    if not taskData then
        return 0
    end
    
    local prog = 0
    if taskData.totalStepEnergy > 0 and taskData.curStepEnergy > 0 then
        prog = math.floor(taskData.curStepEnergy / taskData.totalStepEnergy * 100)
    end

    return math.min(prog, 100)
end

-- 注册事件
function ClanSysViewMain:registerListener()
    gLobalNoticManager:addObserver(self, function()
        self.m_clanData = ClanManager:getClanData()
        if self.m_clanData:isClanMember() then
            self:updateUI()
        end
    end, ClanConfig.EVENT_NAME.RECIEVE_CLAN_INFO_DATA)

    -- 关闭公会
    gLobalNoticManager:addObserver(self, function(self, param)
        -- 清楚定时器
        self:clearScheduler()
    end, ClanConfig.EVENT_NAME.CLOSE_CLAN_HOME_VIEW)

    -- 入口刷新 rush or duel
    gLobalNoticManager:addObserver(self, function()
        self:updateActRushUI(true)
    end, ClanConfig.EVENT_NAME.CLAN_ENTRY_REFRESH) -- 公会对决倒计时结束
end

function ClanSysViewMain:changeBubbleGZorder(_node)
    if not _node then
        return
    end 

    _node:setGlobalZOrder(1)
    local children = _node:getChildren()
    for _, child in ipairs(children) do
        child:setGlobalZOrder(1)
    end
end

return ClanSysViewMain