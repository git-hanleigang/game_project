--[[
    --新版每日任务pass主界面 任务领取界面
    csc 2021-06-21
]]
local BaseCollectLayer = require("base.BaseCollectLayer")
local DailyMissionPassRewardLayer = class("DailyMissionPassRewardLayer", BaseCollectLayer)

function DailyMissionPassRewardLayer:ctor()
    DailyMissionPassRewardLayer.super.ctor(self)
    -- 设置横屏csb
    self:setLandscapeCsbName(DAILYPASS_RES_PATH.DailyMissionPass_RewardLayer)
    self:setPortraitCsbName(DAILYPASS_RES_PATH.DailyMissionPass_RewardLayer_Vertical)
end

function DailyMissionPassRewardLayer:initUI(_collectType)
    self.m_bCollectType = _collectType --  区分当前是哪种模式的收集状态 用来确定时间线
    self.m_boxItemList = {}
    DailyMissionPassRewardLayer.super.initUI(self)
end

function DailyMissionPassRewardLayer:initCsbNodes()
    self.m_nodeReward = self:findChild("node_reward")
    self.m_btnCollect = self:findChild("btn_collect")
    self.m_btnDoubleCoins = self:findChild("btn_doubleCoins")
    self.m_btnClose = self:findChild("btn_close")
    
    self.m_nodeBox = self:findChild("node_box")

    self.m_effect_1 = self:findChild("ef_caizi_lizi")
    self.m_effect_2 = self:findChild("ef_caizi_lizi2")

    self.m_effect_1:stopSystem()
    -- 默认停掉粒子
    self.m_effect_2:stopSystem()
    -- 默认停掉粒子
end

function DailyMissionPassRewardLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

-- 重写父类方法
function DailyMissionPassRewardLayer:playShowAction()
    local delayTime = 0
    if self.m_bCollectType ~= "" then
        self.m_nodeBox:setVisible(false)
        local actName = "start"
        delayTime = 1 / 60 * 75
        if self.m_bCollectType == "safebox" then
            actName = "start2"
            self.m_nodeBox:setVisible(true)
            delayTime = 0
        end

        performWithDelay(
            self,
            function()
                self.m_effect_1:resetSystem()
                self.m_effect_2:resetSystem()
            end,
            1 / 60 * 120
        )
        DailyMissionPassRewardLayer.super.playShowAction(self, actName)
    else
        self.m_effect_1:resetSystem()
        self.m_effect_2:resetSystem()
        self:runCsbAction("idle", true, nil, 60)
        DailyMissionPassRewardLayer.super.playShowAction(self)
    end
    --流程简化导致 飞礼包和奖励界面打开了音效重叠了 飞礼包时不播放打开音效
    if delayTime == 0 then
        gLobalSoundManager:playSound(DAILYPASS_RES_PATH.PASS_REWARDLAYER_OPEN_MP3)
    end
end

function DailyMissionPassRewardLayer:updateView(_params, spot)
    self.m_flyCoins = tonumber(_params.coins)
    self.m_flyGems = tonumber(_params.gems)
    self.m_params = _params
    self.m_currCollectType = _params.collectType
    self.m_flowerCoins = _params.flowerCoins

    -- 创建奖励道具
    local propList = {}
    if _params.items then
        propList = clone(_params.items)
    end
    if _params.coins and _params.coins > 0 then
        propList[#propList + 1] = gLobalItemManager:createLocalItemData("Coins", tonumber(_params.coins), {p_limit = 3})
    end
    if spot and spot == 1 then
        local item = {}
        item.p_activityId = "400001"
        item.p_buff = 0
        item.p_description = "水壶"
        item.p_expireAt = 1672559999000
        item.p_icon = "Reward_pot"
        item.p_id = 880302
        item.p_item = 0
        item.p_limit = 6
        item.p_num = 1
        item.p_mark = {2}
        item.p_type = "Item"
        table.insert(propList, item)
    end
    if #propList > 0 then
        local itemList = {}
        for i = 1, #propList do
            -- 处理一下角标显示
            local itemData = propList[i]

            if itemData.p_icon == "PassCoupon20" then
                self.m_hasCoupon = true
                self.m_couponItem = clone(itemData)
            end

            if itemData.getItemInfo then
                local itemInfo = itemData:getItemInfo()
                if itemInfo and itemInfo.p_id == BoxSystemConfig.itemId then
                    table.insert(self.m_boxItemList, itemData)
                end
            end

            local newItemNode = gLobalItemManager:createRewardNode(itemData, ITEM_SIZE_TYPE.REWARD_BIG)
            if newItemNode then -- csc 2021-11-28 18:00:06 修复如果邮件里包含的道具如果不存在报错的情况
                gLobalDailyTaskManager:setItemNodeByExtraData(itemData, newItemNode)
                itemList[#itemList + 1] = gLobalItemManager:createOtherItemData(newItemNode, 1)
            end
        end
        local size = cc.size(850, 350)
        local scale = self:getUIScalePro()
        if globalData.slotRunData.isPortrait then
            size = cc.size(850, 400)
            scale = 0.84
        end
        --默认大小
        local listView = gLobalItemManager:createRewardListView(itemList, size)
        -- local node = gLobalItemManager:addPropNodeList(propList, ITEM_SIZE_TYPE.REWARD, 1, 128, false)
        listView:setScale(scale)
        self.m_nodeReward:addChild(listView)
        self.m_coinsItem = listView:findCell("Coins")
    end

    self:hideDoubleBtn(false)

    if self.m_params.missionType == gLobalDailyTaskManager.MISSION_TYPE.DAILY_MISSION then
        -- 每日任务界面进来的时候，才判断是否有广告
        -- 广告打点
        if self:hasAD() and self.m_coinsItem ~= nil then
            self:logADPush()
            self:hideDoubleBtn(true)
        end
    end
end

function DailyMissionPassRewardLayer:hasAD()
    if globalData.adsRunData:isPlayRewardForPos(PushViewPosType.DoubleMission) then
        return true
    end
    return false
end

-- 看完广告后双倍奖励
function DailyMissionPassRewardLayer:autoShowADReward()
    -- 播放金币双倍动画
    -- self.m_bInAction = true
    self:_addBlockMask()
    -- 播放音效
    local audioId = nil
    if self.m_isSound then
        audioId = gLobalSoundManager:playSound("Sounds/coinIncrease.mp3")
    end
    local coinsLabelNode = self.m_coinsItem.m_lb_select
    local startCoins = tonumber(self.m_flyCoins) --
    self.m_addCoins = startCoins * 2
    local spendTime = 1 / 60
    util_jumpNumExtra(
        coinsLabelNode,
        startCoins,
        self.m_addCoins,
        startCoins * 0.05,
        spendTime,
        util_formatCoins,
        {3},
        nil,
        nil,
        function()
            if audioId then
                gLobalSoundManager:stopAudio(audioId, true)
            end
            if self.m_isSound then
                gLobalSoundManager:playSound("Sounds/coinIncreaseEnd.mp3")
            end
            -- self.m_bInAction = false
            self:_removeBlockMask()
        end
    )
end

function DailyMissionPassRewardLayer:hideDoubleBtn(_flag)
    self.m_btnDoubleCoins:setVisible(_flag)
    self.m_btnClose:setVisible(_flag)
    self.m_btnCollect:setVisible(not _flag)
end
-------<日志>--------------------------------------------------------------
function DailyMissionPassRewardLayer:logADPush()
    gLobalSendDataManager:getLogAds():createPaySessionId()
    gLobalSendDataManager:getLogAds():setOpenSite(PushViewPosType.DoubleMission)
    gLobalSendDataManager:getLogAds():setOpenType("TapOpen")
    globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = PushViewPosType.DoubleMission})

    gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.DoubleMission)
    gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
    gLobalSendDataManager:getLogAdvertisement():setType("Incentive")
    gLobalSendDataManager:getLogAdvertisement():setadType("Push")
    gLobalSendDataManager:getLogAdvertisement():sendAdsLog()
end

function DailyMissionPassRewardLayer:logADClick()
    gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.DoubleMission)
    gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
    gLobalSendDataManager:getLogAds():createPaySessionId()
    gLobalSendDataManager:getLogAds():setOpenSite(PushViewPosType.DoubleMission)
    gLobalSendDataManager:getLogAds():setOpenType("TapOpen")
    globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = PushViewPosType.DoubleMission}, nil, "click")
end

function DailyMissionPassRewardLayer:onClickMask()
    self:onCollect()
end

function DailyMissionPassRewardLayer:onCollect()
    -- if self.m_bTouch then
    --     return
    -- end
    -- if self.m_bInAction then
    --     return
    -- end

    -- self:collectAction()
    -- self.m_bTouch = true

    local btnCollect = self:findChild("btn_collect")
    local addCoins = math.max((self.m_addCoins or 0), tonumber(self.m_flyCoins or 0))
    local addGems = tonumber(self.m_flyGems or 0)
    DailyMissionPassRewardLayer.super.onCollect(self, addCoins, btnCollect,addGems)
end

function DailyMissionPassRewardLayer:collectCallback()
    self:closeFunc()
end

function DailyMissionPassRewardLayer:clickFunc(_sender)
    local name = _sender:getName()

    if name == "btn_collect" or name == "btn_close" then
        self:onCollect()
    elseif name == "btn_doubleCoins" then
        -- 看广告
        _sender:setTouchEnabled(false)
        performWithDelay(
            self,
            function()
                _sender:setTouchEnabled(true)
            end,
            0.5
        )
        if self:hasAD() then
            gLobalViewManager:addLoadingAnima()
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:logADClick()
            gLobalAdsControl:playRewardVideo(PushViewPosType.DoubleMission)
        else
            self:closeFunc()
        end
    end
end

-- function DailyMissionPassRewardLayer:collectAction()
--     if not self.m_flyCoins or self.m_flyCoins == 0 then
--         self:closeFunc()
--         return
--     end
--     local btnCollect = self:findChild("btn_collect")
--     local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
--     local view = gLobalViewManager:getFlyCoinsView()
--     view:pubShowSelfCoins(true) -- 不要做纠错处理
--     view:pubPlayFlyCoin(startPos, globalData.flyCoinsEndPos, globalData.topUICoinCount, self.m_flyCoins, handler(self, self.closeFunc))
-- end

function DailyMissionPassRewardLayer:setClose()
    if self.m_flowerCoins then
        local item = {}
        local coin_item = gLobalItemManager:createLocalItemData("Coins", tonumber(self.m_flowerCoins), {p_limit = 3})
        table.insert(item, coin_item)
        local cb = function()
        end
        local view = util_createView("views.FlowerCode.FlowerRewardLayer", item, cb, tonumber(self.m_flowerCoins), true, 3)
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

function DailyMissionPassRewardLayer:closeFunc()
    local catFoodList = self.m_params.catFoodList
    local propsBagList = self.m_params.propsBagList

    local lotteryList = self.m_params.lotteryList

    local giftPickBonusList = self.m_params.giftPickBonusList
    local duckShotNewGame = G_GetMgr(ACTIVITY_REF.DuckShot):getNewCreateGameData("BattlePassCollect")
    local pinBallGoNewGame = G_GetMgr(ACTIVITY_REF.PinBallGo):getNewGameDataBySource("BattlePassCollect")

    local boxInfo = {
        index = self.m_params.level,
        type = self.m_params.boxType,
        collectAll = self.m_params.collectAll,
        safeBox = self.m_params.safeBox
    }
    local nextPassFunc = function()
        -- 如果有高倍场体验卡
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_COLLECT_REWARD_OVER, {rewardInfo = boxInfo})
        if not tolua.isnull(self) then
            self:closeUI(
                function()
                    local itemNum = #self.m_boxItemList
                    if itemNum > 0 then
                        local boxItem = self.m_boxItemList[1]
                        local boxNum = boxItem.p_num or 0
                        local data = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
                        local expireAt = data.p_expireAt or 0
                        local groupName = "Pass|".. boxItem.p_icon .. "|" .. expireAt
                        G_GetMgr(G_REF.BoxSystem):showBoxCollectLayer(groupName, nil, boxNum)
                        self.m_boxItemList = {}
                    end
                end
            )
            self:setClose()
        end
    end

    local data = {
        missionType = self.m_params.missionType,
        addExp = self.m_params.addExp,
        refresh = true
    }
    local missionType = self.m_params.missionType
    local luckyMissionItems = self.m_params.luckyMissionItems
    local seasonMissionItems = self.m_params.seasonMissionItems

    local nextFunc = function()
        local overFunc = function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_COLLECT_OVER, data)
            if not tolua.isnull(self) then
                self:closeUI()
                self:setClose()
            end
        end
        if gLobalAdChallengeManager:isShowMainLayer() then
            gLobalAdChallengeManager:showMainLayer(
                function()
                    overFunc()
                end
            )
        else
            overFunc()
        end
    end
    
    -- 掉落快速点击小游戏道具
    local piggyClickerGameFunc = function()
        local overFunc = function()
            if self.m_currCollectType == gLobalDailyTaskManager.COLLECT_TYPE.MISSION_TYPE then
                nextFunc()
            else
                nextPassFunc()
            end
        end
        local piggyClickerData = G_GetMgr(ACTIVITY_REF.PiggyClicker):getData()
        if not piggyClickerData then
            overFunc()
            return
        end

        local bDropNew = piggyClickerData:checkIsGainNewGame()
        local newGameData = piggyClickerData:getNewGameData()
        if not bDropNew or not newGameData then
            overFunc()
            return
        end

        G_GetMgr(ACTIVITY_REF.PiggyClicker):showGameDropItemLayer(newGameData, overFunc)
    end

    local duckShotFunc = function()
        if table.nums(duckShotNewGame) > 0 then
            G_GetMgr(ACTIVITY_REF.DuckShot):showPlayTipLayer(piggyClickerGameFunc)
        elseif table.nums(pinBallGoNewGame) > 0 then
            G_GetMgr(ACTIVITY_REF.PinBallGo):showPlayTipLayer(piggyClickerGameFunc)
        else
            piggyClickerGameFunc()
        end
    end  

    local deluxeCardFunc = function()
        -- 如果有高倍场体验卡
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM, duckShotFunc)
    end

    local couponChallengeFunc = function()
        --砸锤子送优惠券
        local data = G_GetMgr(ACTIVITY_REF.CouponChallenge):getRunningData()
        if data and data:isPopupsNum() then
            local view = G_GetMgr(ACTIVITY_REF.CouponChallenge):showMainLayer()
            if view then
                view:setOverFunc(duckShotFunc)
            else
                duckShotFunc()
            end
        else
            duckShotFunc()
        end
    end

    local popHolidayPassProgressLayer = function()
        local mgr = G_GetMgr(ACTIVITY_REF.HolidayPass)
        if mgr then
            local view = mgr:showProgressLayer({overFunc = couponChallengeFunc})
            if not view then
                couponChallengeFunc()
            end
        else
            couponChallengeFunc()
        end
    end

    local lotteryFunc = function()
        if lotteryList and next(lotteryList) then
            local callFunc = function()
                popHolidayPassProgressLayer()
            end
            G_GetMgr(G_REF.Lottery):showTicketView(nil, callFunc, #lotteryList)
        else
            popHolidayPassProgressLayer()
        end
    end

    local giftPickBonusLayer = function(_giftPickBonusCallFunc)
        -- 通过道具数量，从数据中
        if giftPickBonusList and #(giftPickBonusList or {}) > 0 then
            local gPickMgr = G_GetMgr(G_REF.GiftPickBonus)
            if gPickMgr and gPickMgr.showConfirmLayer then
                self.m_csbNode:setVisible(false)
                local ui =
                    gPickMgr:showConfirmLayer(
                    function()
                        _giftPickBonusCallFunc()
                    end
                )
                if ui == nil then
                    _giftPickBonusCallFunc()
                end
            end
        else
            _giftPickBonusCallFunc()
        end
    end

    local popNextLayer = function()
        if self.m_currCollectType == gLobalDailyTaskManager.COLLECT_TYPE.MISSION_TYPE then
            -- csc 2021-10-18 新增pass任务也能完成聚合挑战
            local taskType = G_GetMgr(ACTIVITY_REF.HolidayChallenge).TASK_TYPE.MISSION
            if missionType == gLobalDailyTaskManager.MISSION_TYPE.SEASON_MISSION then
                taskType = G_GetMgr(ACTIVITY_REF.HolidayChallenge).TASK_TYPE.PASS
            end
            -- 有猫粮弹出猫粮
            if catFoodList and next(catFoodList) then
                -- 有合成福袋弹出猫粮
                -- 有合成福袋弹出猫粮
                local catManager = G_GetMgr(ACTIVITY_REF.DeluxeClubCat)
                catManager:popCatFoodRewardPanel(
                    catFoodList,
                    function()
                        G_GetMgr(ACTIVITY_REF.HolidayChallenge):dailyTaskCollectOver(
                            taskType,
                            function()
                                giftPickBonusLayer(
                                    function()
                                        lotteryFunc()
                                    end
                                )
                            end
                        )
                    end
                )
            elseif propsBagList and next(propsBagList) then
                local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
                mergeManager:popMergePropsBagRewardPanel(
                    propsBagList,
                    function()
                        -- 用来处理界面所有流程操作完毕之后要做的事情
                        if missionType == gLobalDailyTaskManager.MISSION_TYPE.DAILY_MISSION then
                            G_GetMgr(ACTIVITY_REF.HolidayChallenge):dailyTaskCollectOver(
                                taskType,
                                function()
                                    G_GetMgr(ACTIVITY_REF.BattleMatch):doCheckShowActivityLayer(
                                        function()
                                            giftPickBonusLayer(
                                                function()
                                                    lotteryFunc()
                                                end
                                            )
                                        end,
                                        false
                                    )
                                end
                            )
                        else
                            giftPickBonusLayer(
                                function()
                                    lotteryFunc()
                                end
                            )
                        end
                    end
                )
            else
                G_GetMgr(ACTIVITY_REF.HolidayChallenge):dailyTaskCollectOver(
                    taskType,
                    function()
                        G_GetMgr(ACTIVITY_REF.BattleMatch):doCheckShowActivityLayer(
                            function()
                                giftPickBonusLayer(
                                    function()
                                        lotteryFunc()
                                    end
                                )
                            end,
                            false
                        )
                    end
                )
            end
        else
            giftPickBonusLayer(
                function()
                    deluxeCardFunc()
                end
            )
        end
    end

    -- pass 神秘宝箱
    local popBoxLayer = function()
        local itemNum = #self.m_boxItemList
        if itemNum > 0 then
            local boxItem = self.m_boxItemList[1]
            local boxNum = boxItem.p_num or 0
            local isDropDeluxeCard = globalDeluxeManager:checkPopExperienceCard()
            if boxNum > 0 and isDropDeluxeCard then
                local data = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
                if data then
                    local expireAt = data.p_expireAt or 0
                    local groupName = "Pass|".. boxItem.p_icon .. "|" .. expireAt
                    local isPop = G_GetMgr(G_REF.BoxSystem):showBoxCollectLayer(groupName, popNextLayer, boxNum)
                    self.m_boxItemList = {}
                    if not isPop then
                        popNextLayer()
                    end
                else
                    popNextLayer()
                end
            else
                popNextLayer()
            end
        else
            popNextLayer()
        end
    end

    -- pass 折扣 
    local popPassCouponLayer = function ()
        if self.m_hasCoupon then
            local passCouponLayer = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_BuyCouponRewardLayer, self.m_couponItem, popBoxLayer)
            gLobalViewManager:showUI(passCouponLayer, ViewZorder.ZORDER_UI)
        else
            popBoxLayer()
        end
    end

    -- 检测当前是否有 dailymissionRush .SeasonMissionRush
    local popRushRewardLayer = function()
        if self.m_currCollectType == gLobalDailyTaskManager.COLLECT_TYPE.MISSION_TYPE then
            if luckyMissionItems or seasonMissionItems then
                local activityData = nil
                local itemsData = nil
                if missionType == gLobalDailyTaskManager.MISSION_TYPE.DAILY_MISSION then
                    activityData = G_GetMgr(ACTIVITY_REF.DailyMissionRush):getData()
                    itemsData = luckyMissionItems
                else
                    activityData = G_GetMgr(ACTIVITY_REF.SeasonMissionRush):getData()
                    itemsData = seasonMissionItems
                end
                gLobalDailyTaskManager:createRushRewardLayer(
                    activityData,
                    itemsData,
                    function()
                        popPassCouponLayer()
                    end
                )
            else
                popPassCouponLayer()
            end
        else
            popPassCouponLayer()
        end
    end

    local nextDropFunc = function()
        if CardSysManager:needDropCards("GLORY PASS") == true then
            gLobalNoticManager:addObserver(
                self,
                function(sender, func)
                    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                    popRushRewardLayer()
                end,
                ViewEventType.NOTIFY_CARD_SYS_OVER
            )
            CardSysManager:doDropCards("GLORY PASS")
        elseif CardSysManager:needDropCards("Pass") == true then
            gLobalNoticManager:addObserver(
                self,
                function(sender, func)
                    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                    popRushRewardLayer()
                end,
                ViewEventType.NOTIFY_CARD_SYS_OVER
            )
            CardSysManager:doDropCards("Pass")

        elseif CardSysManager:needDropCards("Mission") == true then
            gLobalNoticManager:addObserver(
                self,
                function(sender, func)
                    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                    popRushRewardLayer()
                end,
                ViewEventType.NOTIFY_CARD_SYS_OVER
            )
            CardSysManager:doDropCards("Mission")
        else
            popRushRewardLayer()
        end
    end
    if CardSysManager:needDropCards("LuckyMission") then
        gLobalNoticManager:addObserver(
            self,
            function(sender, func)
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                nextDropFunc()
            end,
            ViewEventType.NOTIFY_CARD_SYS_OVER
        )
        CardSysManager:doDropCards("LuckyMission")
    else
        nextDropFunc()
    end
end

function DailyMissionPassRewardLayer:onEnter()
    DailyMissionPassRewardLayer.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not tolua.isnull(self) then
                if params[1] == "success" and self.m_coinsItem then
                    self:hideDoubleBtn(false)
                    self.m_isSound = true
                    self:autoShowADReward()
                else
                    self.m_btnDoubleCoins:setTouchEnabled(true)
                end
            end
        end,
        ViewEventType.NOTIFY_ADS_DOUBLEMISSION
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not tolua.isnull(self) then
                self:hideDoubleBtn(false)
                -- 自动收集
                -- self.m_bInAction = true
                -- self:collectAction()
                self:onCollect()
            end
        end,
        ViewEventType.NOTIFY_ADS_DOUBLEMISSION_FAILE
    )
end

return DailyMissionPassRewardLayer
