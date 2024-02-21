----
local QuestNewChapterStarPrizesLayer = class("QuestNewChapterStarPrizesLayer", BaseLayer)


function QuestNewChapterStarPrizesLayer:getCsbName()
    return QUESTNEW_RES_PATH.QuestNewChapterStarPrizesLayer
end

function QuestNewChapterStarPrizesLayer:initDatas(chapterId,callFun)
    self:setHasGuide(true)
    self.m_chapterId = chapterId
    self.m_callFun = callFun 
    self.m_starsData_Before = G_GetMgr(ACTIVITY_REF.QuestNew):getChapterStarPrizesData(chapterId,true)
    self.m_starNum_before,self.m_maxStarNum = G_GetMgr(ACTIVITY_REF.QuestNew):getChapterPickStars(chapterId,true) 
    G_GetMgr(ACTIVITY_REF.QuestNew):resetChapterStarPrizesRememberData(chapterId)
end

function QuestNewChapterStarPrizesLayer:initCsbNodes()
    self.m_starNodeMap = {}
    for i=1,8 do
        local oneNode = self:findChild("node_star_" .. i)
        if oneNode then
            table.insert(self.m_starNodeMap,oneNode)
        end
    end
    self.m_rewardNodeMap = {}
    for i=1,8 do
        local oneNode = self:findChild("node_" .. i)
        if oneNode then
            table.insert(self.m_rewardNodeMap,oneNode)
        end
    end

    self.m_lb_shuzi = self:findChild("lb_shuzi")
    self.m_bar_star_jindu = self:findChild("bar_star_jindu")
end

function QuestNewChapterStarPrizesLayer:initView()
    self.m_bTouch = true

    local rata = self.m_starNum_before/self.m_maxStarNum *100
    self.m_bar_star_jindu:setPercent(rata)
    self.m_lb_shuzi:setString(self.m_starNum_before)

    self.m_StarRewardMap = {}
    self.m_StarProgressMap = {}
    for i=1,8 do
        local starData = self.m_starsData_Before[i]
        if starData then
            local rewardNode =  self.m_rewardNodeMap[i]
            if rewardNode then
                local starReward = util_createView(QUESTNEW_CODE_PATH.QuestNewChapterStarPrizesRewardNode,{starData = starData,chapterId = self.m_chapterId})
                rewardNode:addChild(starReward)
                util_setCascadeOpacityEnabledRescursion(rewardNode, true)
                self.m_StarRewardMap["reward_"..starData.p_stars] = starReward
            end
            
            local progressNode =  self.m_starNodeMap[i]
            if progressNode then
                local starProgress = util_createView(QUESTNEW_CODE_PATH.QuestNewChapterStarPrizesProgressNode,{starData = starData,type =i%2 +1,chapterId = self.m_chapterId})
                progressNode:addChild(starProgress)
                util_setCascadeOpacityEnabledRescursion(progressNode, true)
                self.m_StarProgressMap["progress_"..starData.p_stars] = starProgress
            end
        end
    end
end

function QuestNewChapterStarPrizesLayer:playShowAction()
    local userDefAction = function(callFunc)
        self:runCsbAction(
            "start",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    QuestNewChapterStarPrizesLayer.super.playShowAction(self, userDefAction)
end

function QuestNewChapterStarPrizesLayer:onShowedCallFunc()
    self.m_bTouch = false
    self:runCsbAction("idle", true, nil, 60)
    self:checkCurrentStarPrizes()
end

function QuestNewChapterStarPrizesLayer:checkCurrentStarPrizes()
    self.m_starsData = G_GetMgr(ACTIVITY_REF.QuestNew):getChapterStarPrizesData(self.m_chapterId)
    self.m_starNum = G_GetMgr(ACTIVITY_REF.QuestNew):getChapterPickStars(self.m_chapterId)
    if self.m_starNum > self.m_starNum_before then
        self:doProgress()
    else
        self:checkHasStarMetersRewardToGain()
    end
end

function QuestNewChapterStarPrizesLayer:doProgress()
    self.m_doingProgress  = true
    self.m_beginNum = self.m_starNum_before + 0.5
    self.activityAction = util_schedule(self,function()
        self:updateProgress()
    end,0.1)
    self:updateProgress()
end

function QuestNewChapterStarPrizesLayer:updateProgress()
    if self.m_beginNum >= self.m_starNum then
        if self.activityAction ~= nil then
            self:stopAction(self.activityAction)
            self.activityAction = nil
            self.m_doingProgress  = false
        end
        local rata = self.m_beginNum/self.m_maxStarNum *100
        self.m_lb_shuzi:setString("" .. math.floor(self.m_beginNum))
        self.m_bar_star_jindu:setPercent(rata)
        local starReward = self.m_StarRewardMap["reward_"..self.m_beginNum]
        if starReward then
            starReward:doUnlockAct(function ()
                self:checkHasStarMetersRewardToGain()
            end)
        else
            self:checkHasStarMetersRewardToGain()
        end
    else
        local rata = self.m_beginNum/self.m_maxStarNum *100
        self.m_lb_shuzi:setString("" .. math.floor(self.m_beginNum))
        self.m_bar_star_jindu:setPercent(rata)
    
        local starReward = self.m_StarRewardMap["reward_"..self.m_beginNum]
        if starReward then
            starReward:doUnlockAct(nil)
        end
        local starProgress = self.m_StarProgressMap["progress"..self.m_beginNum]
        if starProgress then
            starProgress:doUnlockAct(nil)
        end
        self.m_beginNum = self.m_beginNum + 0.5
    end
end

function QuestNewChapterStarPrizesLayer:checkGetReward()
    local willGainReward =  false
    self.m_willGainRewardStarArray = {}
    self.m_willGainReward = {coin = 0,items = {}}
    for i=1,8 do
        local starData = self.m_starsData[i]
        if starData then
            if starData.p_stars <= self.m_starNum and not starData.p_collected then
                willGainReward =  true
                self.m_willGainReward.coin = self.m_willGainReward.coin + starData.p_coins
                if #starData.p_items > 0 then
                    table.insert(self.m_willGainReward.items,starData.p_items[1])
                end
                table.insert( self.m_willGainRewardStarArray, starData.p_stars)
            end
        end
    end
    if willGainReward then
        self:showRewardLayer()
    end
end

function QuestNewChapterStarPrizesLayer:showRewardLayer()
    local callBack = function ()
        if not tolua.isnull(self) then
            self:afterGainStarReward()
        end
    end
    local rewardView = util_createView(QUESTNEW_CODE_PATH.QuestNewMapRewardLayer,{type = 1,reward = self.m_willGainReward,callBack = callBack,chapterId = self.m_chapterId})
    if rewardView then
        gLobalViewManager:showUI(rewardView, ViewZorder.ZORDER_UI)
    end
end

function QuestNewChapterStarPrizesLayer:afterGainStarReward()
    for i,star in ipairs( self.m_willGainRewardStarArray) do
        local starProgress = self.m_StarProgressMap["progress_"..star]
        if starProgress then
            starProgress:doCompleteAct(function ()
                local starReward = self.m_StarRewardMap["reward_"..star]
                if starReward then
                    starReward:changeToCompleted()
                end
            end)
        end
    end
end

function QuestNewChapterStarPrizesLayer:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_close" then
        if self.m_bTouch or self.m_doingProgress then
            return
        end
        self.m_bTouch = true
        self:closeUI(function ()
            if  self.m_callFun then
                self.m_callFun()
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWQUEST_STARLAYER_CLOSE)
        end)
    end
end

function QuestNewChapterStarPrizesLayer:checkHasStarMetersRewardToGain()
    local chapterData = G_GetMgr(ACTIVITY_REF.QuestNew):getChapterDataByChapterId(self.m_chapterId)
    if chapterData:checkHasStarMetersRewardToGain() then
        if self.m_doingProgress then
            return 
        end
        self:checkGetReward()
    end
end

return QuestNewChapterStarPrizesLayer
