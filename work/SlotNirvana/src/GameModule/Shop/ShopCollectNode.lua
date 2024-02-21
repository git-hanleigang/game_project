---
--[[
    @desc: 每日商城礼物功能
    time:2019-04-15 17:47:28
]]
local ShopCollectNode = class("ShopCollectNode", util_require("base.BaseView"))

ShopCollectNode.m_giftNode = nil

ShopCollectNode.m_checkbonus = nil
ShopCollectNode.m_actionbonus = nil
ShopCollectNode.m_isCollect = nil

ShopCollectNode.m_collectInSp = nil -- collect in 图片
ShopCollectNode.m_collectNowSp = nil
ShopCollectNode.m_leftTimeLb = nil -- 倒计时 lb
ShopCollectNode.m_rewardCoinLb = nil --奖励金币lb
ShopCollectNode.m_doubleSp = nil -- 双倍标识、

ShopCollectNode.m_rewardCoin = nil

function ShopCollectNode:initUI(data)
    self:createCsbNode("Shop_Res/Gift.csb")
    self.btn_layout_option = self:findChild("click_area")
    self.btn_layout_option:setVisible(false)
    self:addClick(self.btn_layout_option)

    -- 更新显示获得金币UI
    self.m_rewardCoinLb = self:findChild("bonusgamecoin")
    local totalWin = globalData.shopRunData:getShpGiftRewardCoins()
    self.m_rewardCoinLb:setString(util_formatCoins(totalWin, 8))
    self:updateLabelSize({label = self.m_rewardCoinLb}, 130)

    self.m_isCollect = false

    self.m_collectInSp = self:findChild("coins")
    self.m_leftTimeLb = self:findChild("daojishi")
    self.m_collectNowSp = self:findChild("collect_now")
    self.m_giftNode = self:findChild("Node_1")

    self.m_doubleSp = self:findChild("x2")
    self.m_doubleSp:setVisible(false)
end
--[[
    @desc: 更新奖励状态
    time:2019-04-18 16:00:38
    @return:
]]
function ShopCollectNode:updateCollectStatus()
    local leftTime = globalData.shopRunData:getShpGiftCD()
    local rewardCoin = globalData.shopRunData:getShpGiftRewardCoins()
    if leftTime == 0 then
        self.m_collectInSp:setVisible(false)
        self.m_leftTimeLb:setVisible(false)
        self.m_collectNowSp:setVisible(true)
        self.m_rewardCoinLb:setVisible(true)
        self.btn_layout_option:setVisible(true)
        self.m_rewardCoinLb:setString(util_formatCoins(rewardCoin, 8))

        self.m_giftNode:stopAllActions()
        self:runCsbAction(
            "animation",
            false,
            function()
                schedule(
                    self.m_giftNode,
                    function()
                        self:runCsbAction("animation", false)
                    end,
                    2.5
                )
            end
        )

        self.m_rewardCoin = rewardCoin
    else
        self.m_giftNode:stopAllActions()
        self.m_collectInSp:setVisible(true)
        self.m_leftTimeLb:setVisible(true)
        self.m_collectNowSp:setVisible(false)
        self.m_rewardCoinLb:setVisible(false)
        self.m_rewardCoin = 0
        self:runCsbAction("idle", false)
        local leftTime = globalData.shopRunData:getShpGiftCD()
        self.m_leftTimeLb:setString(util_count_down_str(leftTime))

        schedule(
            self.m_leftTimeLb,
            function()
                local leftTime = globalData.shopRunData:getShpGiftCD()
                self.m_leftTimeLb:setString(util_count_down_str(leftTime))

                if leftTime == 0 then
                    self.m_leftTimeLb:stopAllActions()
                    self:updateCollectStatus()
                end
            end,
            1
        )
    end
end

function ShopCollectNode:onEnter()
    self:updateCollectStatus()
end

function ShopCollectNode:onExit()
end

function ShopCollectNode:clickFunc(sender)
    if globalNoviceGuideManager:isNoobUsera() then
    --如果新手期未完成引导不能点击购买商品
    -- if not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.shopReward2.id) then
    --     if not globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.shopReward2) then
    --         return
    --     else
    --         self.m_inGuide = true
    --     end
    -- end
    end

    if self.m_isCollect == true then
        return
    end
    self.m_isCollect = true
    self:sendCollectMsg()

    -- 引导打点：免费领取商店金币-4.点击领取金币
    if gLobalSendDataManager:getLogGuide():isGuideBegan(9) then
        gLobalSendDataManager:getLogGuide():sendGuideLog(9, 4)
    end
    -- if globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.shopReward2) then
    -- end

    if not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.shopReward.id) then
        globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.shopReward)
    end
    if not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.shopReward2.id) then
        globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.shopReward2)
    end
end
--[[
    @desc: 发送金币收集消息
    author:{author}
    time:2018-12-03 16:47:17
    @return:
]]
function ShopCollectNode:sendCollectMsg()
    -- body
    --检查联网状态
    if gLobalSendDataManager:checkShowNetworkDialog() then
        return
    end

    self.btn_layout_option:setVisible(false)

    -- if gLobalSendDataManager:getLogFeature().sendUIActionLog then
    --     gLobalSendDataManager:getLogFeature():sendUIActionLog("StoreGuide","ClickGift",self.m_inGuide)
    -- end
    -- --添加loading
    gLobalViewManager:addLoadingAnima()

    gLobalSendDataManager:getNetWorkFeature():sendActionShopBonus(
        self.m_rewardCoin,
        false,
        0,
        function(target, resData)
            if globalFireBaseManager.sendFireBaseLogDirect then
                globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.Free_ShopGift)
            end
            -- 更新shop  gift 信息
            local giftData = cjson.decode(resData.result)
            globalData.shopRunData:syncShopGift(giftData)
            if giftData.extend and giftData.extend.highLimit then -- 解析高倍场数据
                globalData.syncDeluexeClubData(giftData.extend.highLimit)
            end
            gLobalViewManager:removeLoadingAnima()
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_HOURLY_REWARD)

            if self.m_inGuide then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GUIDE_LUCKYSTAMP)
            end
            globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.shopReward2)
            if self == nil or self.flyBonusGameCoins == nil then
                return -- 做界面关闭时 网络消息才返回的情况
            end
            local flyBonusGameCoinsCallFunc = function()
                if not tolua.isnull(self) then
                    globalData.shopRunData.shopRewardTime = 0

                    performWithDelay(
                        self,
                        function()
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                        end,
                        1
                    )

                    -- if gLobalSendDataManager.getLogFeature ~= nil then
                    --     gLobalSendDataManager:getLogFeature():sendShopGiftLog(self.m_rewardCoin)
                    -- end
                    self:updateCollectStatus()
                end
            end

            self:flyBonusGameCoins(flyBonusGameCoinsCallFunc)
        end,
        function()
            if self == nil or self.flyBonusGameCoins == nil then
                return -- 做界面关闭时 网络消息才返回的情况
            end
            self.btn_layout_option:setVisible(true)
            gLobalViewManager:removeLoadingAnima()
            --弹窗
            gLobalViewManager:showReConnect()
            if self.m_isCollect then
                self.m_isCollect = false
            end
        end
    )
end
--[[
    @desc: 飞金币
    author:{author}
    time:2018-11-29 15:58:18
    @return:
]]
function ShopCollectNode:flyBonusGameCoins(func)
    local endPos = globalData.flyCoinsEndPos
    local startPos = self:findChild("Node_1"):getParent():convertToWorldSpace(cc.p(self:findChild("Node_1"):getPosition()))
    local baseCoins = globalData.topUICoinCount

    local view =
        gLobalViewManager:pubPlayFlyCoin(
        startPos,
        endPos,
        baseCoins,
        self.m_rewardCoin,
        function()
            if self.m_isCollect then
                self.m_isCollect = false
            end
            if func then
                func()
            end
            globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.shopTips)
        end
    )
end

return ShopCollectNode
