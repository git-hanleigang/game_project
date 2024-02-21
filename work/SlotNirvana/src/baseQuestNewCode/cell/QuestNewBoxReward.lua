-- Created by jfwang on 2019-05-21.
-- Quest任务完成界面
---- FIX IOS 139

local ShopItem = util_require("data.baseDatas.ShopItem")
local QuestBoxReward = class("QuestBoxReward", BaseLayer)

function QuestBoxReward:initDatas(rewardData)
    self.rewardData = rewardData
    -- self:mergePlistInfos(QUEST_PLIST_PATH.QuestBoxReward)
    self:setLandscapeCsbName(QUEST_RES_PATH.QuestBoxReward)
    self:setExtendData("QuestBoxReward")
end

function QuestBoxReward:initCsbNodes()
    self.sp_coins = self:findChild("sp_coins")
    self.lb_coins = self:findChild("lb_coins")
    self.node_reward = self:findChild("node_reward")
    self.btn_collect = self:findChild("btn_collect")
end

function QuestBoxReward:initView()
    if not self.rewardData then
        return
    end

    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not questConfig then
        return
    end

    local jackpotPool = 0
    if questConfig and questConfig.m_lastBoxJackpot then
        jackpotPool = questConfig.m_lastBoxJackpot
    end
    --金币处理
    if self.rewardData.p_coins and self.rewardData.p_coins > 0 then
        --quest活动倍数加成
        local buffmul = 1
        if self.rewardData.p_multiple then
            buffmul = tonumber(self.rewardData.p_multiple)
        end
        local totalCoins = tonumber(self.rewardData.p_coins) * buffmul + jackpotPool
        self.lb_coins:setString(util_formatCoins(totalCoins, 9))
        util_alignCenter({{node = self.sp_coins}, {node = self.lb_coins}})
    end

    local uiList = {}
    if self.rewardData.p_items and table.nums(self.rewardData.p_items) > 0 then
        for _, item_data in ipairs(self.rewardData.p_items) do
            local itemNode = gLobalItemManager:createRewardNode(item_data, ITEM_SIZE_TYPE.REWARD)
            if itemNode then
                self.node_reward:addChild(itemNode)
                table.insert(uiList, {node = itemNode})
            end
        end
    end
    util_alignCenter(uiList)
end

function QuestBoxReward:playShowAction()
    QuestBoxReward.super.playShowAction(self, "show")
end

function QuestBoxReward:playHideAction()
    QuestBoxReward.super.playHideAction(self, "over")
end

function QuestBoxReward:onShowedCallFunc()
    self:runCsbAction("idleframe", true)
end

function QuestBoxReward:onKeyBack()
    self:dropBoxCard()
end

function QuestBoxReward:onClickMask()
    self:dropBoxCard()
end

-- 弹窗动画
function QuestBoxReward:playShowAction()
    local userDefAction = function(callFunc)
        gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
        self:runCsbAction(
            "show",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    QuestBoxReward.super.playShowAction(self, userDefAction)
end

function QuestBoxReward:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

-- 隐藏动画
function QuestBoxReward:playHideAction()
    local userDefAction = function(callFunc)
        gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
        self:runCsbAction(
            "over",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    QuestBoxReward.super.playHideAction(self, userDefAction)
end

function QuestBoxReward:clickFunc(sender)
    local name = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "btn_collect" then
        self:dropBoxCard()
    end
end

function QuestBoxReward:dropBoxCard()
    if self.m_isDropBoxCard then
        return
    end
    self.m_isDropBoxCard = true

    local checkOpenCTSView = function(_bNotDropCards)
        if G_GetMgr(ACTIVITY_REF.HolidayChallenge):getHasTaskCompleted() then
            local taskType = G_GetMgr(ACTIVITY_REF.HolidayChallenge).TASK_TYPE.QUEST
            G_GetMgr(ACTIVITY_REF.HolidayChallenge):chooseCreatePopLayer(taskType)
        end
    end
    if CardSysManager:needDropCards("Quest Wheel Award") == true then
        CardSysManager:doDropCards("Quest Wheel Award", checkOpenCTSView)
    elseif CardSysManager:needDropCards("Quest Box Award") == true then
        CardSysManager:doDropCards("Quest Box Award", checkOpenCTSView)
    else
        checkOpenCTSView(true)
    end
    self:flyCoins()
end

function QuestBoxReward:flyCoins()
    local endPos = globalData.flyCoinsEndPos
    local startPos = self.btn_collect:getParent():convertToWorldSpace(cc.p(self.btn_collect:getPosition()))
    local baseCoins = globalData.topUICoinCount
    local rewardCoins = globalData.userRunData.coinNum - baseCoins

    local flyOverFunc = function()
        self:closeUI()
    end
    gLobalViewManager:pubPlayFlyCoin(startPos, endPos, baseCoins, rewardCoins, flyOverFunc)
end

function QuestBoxReward:closeUI()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)

    QuestBoxReward.super.closeUI(
        self,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_RUSH_ENTERY_UPDATE)
        end
    )
end

return QuestBoxReward
