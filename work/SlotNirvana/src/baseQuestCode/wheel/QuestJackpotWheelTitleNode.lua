--top jackpot 节点
local QuestJackpotWheelTitleNode = class("QuestJackpotWheelTitleNode", BaseView)

function QuestJackpotWheelTitleNode:initUI(data)
    self.m_isInWheel = false
    local csbPath = QUEST_RES_PATH.QuestJackpotMainTitleNode
    if data and data.inWheel then
        self.m_isInWheel = true
        csbPath = QUEST_RES_PATH.QuestJackpotWheelTitleNode
    end
    self:createCsbNode(csbPath)
    self.m_activityData =  G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    self:initView()
end

function QuestJackpotWheelTitleNode:initCsbNodes()
    local lb_mini  = self:findChild("lb_mini")
    local lb_major = self:findChild("lb_major")
    local lb_grand = self:findChild("lb_grand")
    self.m_topCoinsShowNodeArray = {lb_mini,lb_major,lb_grand}

    local lb_major_lock = self:findChild("lb_major_lock")
    local lb_grand_lock = self:findChild("lb_grand_lock")
    self.m_topCoinsShowNodeArray_lock = {nil,lb_major_lock,lb_grand_lock}

    local node_lock_major = self:findChild("node_lock_major")
    local node_lock_grand = self:findChild("node_lock_grand")
    if node_lock_major then
        local difficulty =  G_GetMgr(ACTIVITY_REF.Quest):getCurDifficulty()
        node_lock_major:setVisible(true)
        node_lock_grand:setVisible(true)
        if difficulty == 2 then
            node_lock_major:setVisible(false)
            node_lock_grand:setVisible(true)
        elseif difficulty == 3 then
            node_lock_major:setVisible(false)
            node_lock_grand:setVisible(false)
        end
    end
end

function QuestJackpotWheelTitleNode:initView()
    self:initGoldTimer()
    self:runCsbAction("idle", true, nil, 60)
end

function QuestJackpotWheelTitleNode:updateCoins(type)
    local coinsNum = G_GetMgr(ACTIVITY_REF.Quest):getRuningGoldByType(type) 
    local lable = self.m_topCoinsShowNodeArray[type]
    local lable_1 = self.m_topCoinsShowNodeArray_lock[type]
    if lable then
        lable:setString(util_getFromatMoneyStr(coinsNum))
        if self.m_isInWheel then
            util_scaleCoinLabGameLayerFromBgWidth(lable, 200, 1)
        else
            util_scaleCoinLabGameLayerFromBgWidth(lable, 150, 1)
        end
    end
    if lable_1 then
        lable_1:setString(util_getFromatMoneyStr(coinsNum))
        if self.m_isInWheel then
            util_scaleCoinLabGameLayerFromBgWidth(lable_1, 200, 1)
        else
            util_scaleCoinLabGameLayerFromBgWidth(lable_1, 150, 1)
        end
    end
end

function QuestJackpotWheelTitleNode:initGoldTimer()
    local updateFun = function(isInit)
        if self.m_activityData:isCanShowRunGold() then
            G_GetMgr(ACTIVITY_REF.Quest):updateQuestGoldIncrease(false)
            for i = 1, 3 do
                self:updateCoins(i)
            end
        end
    end
    updateFun(true)
    schedule(
        self,
        function()
            updateFun()
        end,
        0.1
    )
end

function QuestJackpotWheelTitleNode:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_info" then
        G_GetMgr(ACTIVITY_REF.Quest):showJackpotRuleLayer()
    end
end

function QuestJackpotWheelTitleNode:playHitAct(hitJackpotType)
    if hitJackpotType < 2 then
        return
    end
    local act_Name = "mini"
    if hitJackpotType == 3 then
        act_Name = "major"
    elseif hitJackpotType == 4 then
        act_Name = "grand"
    end
    self:runCsbAction(act_Name,true)
end

return QuestJackpotWheelTitleNode
