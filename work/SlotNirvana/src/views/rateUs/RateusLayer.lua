--版本更新
local RateusLayer = class("RateusLayer", BaseLayer)

function RateusLayer:initDatas(openSite, bNotShowRate)
    self.m_openSite = openSite
    self.m_bNotShowRate = bNotShowRate

    local csbName = "RateUs/RateusLayerNew.csb"

    self.m_bUserNewRes = true --使用新版资源
    if self.m_bUserNewRes then
        csbName = "RateUsV2/RateusLayerNew_V2.csb"
        self.m_clickCsbName = "RateUsV2/ClickChooseNode_0"
        self.m_clickStarCsbName = "RateUsV2/ClickChooseNode_bd_0"
    end
    self:setLandscapeCsbName(csbName)
    self:setPauseSlotsEnabled(true)
    self:setName("RateusLayer")
end

function RateusLayer:initUI()
    RateusLayer.super.initUI(self)

    if gLobalSendDataManager.getLogScore then
        --参数 类型 打开位置  页面名称  页面顺序  评分  奖励
        gLobalSendDataManager:getLogScore():sendScoreLog("ViewOpen", self.m_openSite, "RateusLayer", 0)
    end
    if self.m_openSite ~= "SpinWin" then
        self:findChild("btn_later"):setVisible(false)
    end

    -- csc firebase 打点
    if globalFireBaseManager.sendFireBaseLogDirect then
        if globalData.rateUsData.m_rateUsCount == 1 then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.RatingLuckyorNot_1st)
        elseif globalData.rateUsData.m_rateUsCount == 2 then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.RatingLuckyorNot_2nd)
        elseif globalData.rateUsData.m_rateUsCount == 3 then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.RatingLuckyorNot_3rd)
        end
    end
end

function RateusLayer:initView()
    self.m_node_rateStar = self:findChild("node_rateStar")
    self.m_node_feedCoins = self:findChild("node_feedCoins")
    self.m_node_feedNoCoins = self:findChild("node_feedNoCoins")
    self.m_node_rateUs = self:findChild("node_rateUs")
    self.m_node_rateUs:setVisible(false)
    local nodeRateUs2 = self:findChild("node_rateUs_B")
    if nodeRateUs2 then
        nodeRateUs2:setVisible(false)
        if globalData.constantData.RATE_US_LAYER_USE_NEW_FIVE_DESC_RES then
            -- rateus弹板 使用新版 资源 5分描述
            self.m_node_rateUs = nodeRateUs2
        end
    end
    self.m_Node_suggest = self:findChild("Node_suggest")
    self.m_node_feedReward = self:findChild("node_feedReward")
    self.m_node_feedNoReward = self:findChild("node_feedNoReward")
    self.m_node_clickJump = self:findChild("node_settingClick")
    self.m_node_grand = self:findChild("node_grand")

    if self.m_openSite == "GrandWin" then
        -- GrandWin 触发的点位 显示 m_node_grand
        self:setViewVisible(false, false, false, false, false, false, false, true)
        self.m_node_clickJump:setVisible(false)
    elseif self.m_bNotShowRate then
        self:setViewVisible(false, false, false, false, false, false, false, false)
        self.m_node_clickJump:setVisible(true)
    else
        self.m_node_clickJump:setVisible(false)
        self:setViewVisible(true, false, false, false, false, false, false, false)
        self.m_chooseView = util_createView("views.rateUs.ClickChooseNode", self.m_clickCsbName, self.m_clickStarCsbName, 5)

        self:findChild("starNode"):addChild(self.m_chooseView)
    end

    if self.m_bUserNewRes then
        -- 按钮 2秒后显示
        local btnClose = self:findChild("btn_close1")
        btnClose:setOpacity(0)
        btnClose:setTouchEnabled(false) 
        local actionList = {}
        actionList[#actionList + 1] = cc.DelayTime:create(2)
        actionList[#actionList + 1] = cc.FadeTo:create(1, 255)
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            btnClose:setTouchEnabled(true) 
        end)
        btnClose:runAction(cc.Sequence:create(actionList))
    end

    self:runCsbAction("idle")
end

function RateusLayer:onShowedCallFunc()
    if self.m_openSite == "GrandWin" then
        self:runCsbAction("idle", true, nil, 30)
    elseif not self.m_bNotShowRate then
        self:runCsbAction("idle", true, nil, 30)
        self.m_chooseView:initData(
            function(index)
                if gLobalSendDataManager.getLogScore then
                    --参数 类型 打开位置  页面名称  页面顺序  评分  奖励
                    gLobalSendDataManager:getLogScore():sendScoreLog("Finish", self.m_openSite, "RateusLayer", 1, index)
                end
                self.m_score = index
                if index > 4 then
                    self:showHighStar(index)
                else
                    self:showLowStar(index)
                end

                -- cxc 2023年12月11日14:45:12 点击不同星 延长 评分弹板 被动弹出CD
                G_GetMgr(G_REF.OperateGuidePopup):clickRateUsStarCount(self.m_score)
            end,
            function()
                -- elseif sBtnName == "btn_close1" or sBtnName == "btn_later" then
                self:findChild("btn_close1"):setEnabled(false)
                self:findChild("btn_later"):setEnabled(false)
            end
        )
    end
end

function RateusLayer:showHighStar(index)
    if gLobalSendDataManager.getLogScore then
        --参数 类型 打开位置  页面名称  页面顺序  评分  奖励
        gLobalSendDataManager:getLogScore():sendScoreLog("Finish", self.m_openSite, "RateusLayer", "G1", index)
    end
    self:setViewVisible(false, false, false, true, false, false, false, false)
    self:findChild("btn_close1"):setEnabled(true)
    self:findChild("btn_later"):setEnabled(true)
end

function RateusLayer:showLowStar(index)
    if globalData.rateUsData.m_isgetReward then
        if gLobalSendDataManager.getLogScore then
            gLobalSendDataManager:getLogScore():sendScoreLog("Finish", self.m_openSite, "RateusLayer", "D1", index)
        end
        --star   feedCoins  feedNoCoins rateus  suggest reward Noreward
        self:setViewVisible(false, false, true, false, false, false, false, false)
        self:findChild("btn_close1"):setEnabled(true)
        self:findChild("btn_later"):setEnabled(true)
    else
        self:sendResultServer(
            "",
            0,
            globalData.rateUsData.m_version,
            self.m_score,
            function(coins)
                if gLobalSendDataManager.getLogScore then
                    gLobalSendDataManager:getLogScore():sendScoreLog("Finish", self.m_openSite, "RateusLayer", "D1", index, coins)
                end
                local icon = self:findChild("icon1")
                if icon then
                    local lbsCoins = self:findChild("lbs_coins")
                    lbsCoins:setString(util_formatCoins(coins, 12))
                    -- local cont = lbsCoins:getContentSize()
                    -- icon:setPositionX(lbsCoins:getPositionX() - cont.width / 2 - 40)
                    self:setViewVisible(false, false, true, false, false, false, false, false)
                    self:findChild("btn_close1"):setEnabled(true)
                    self:findChild("btn_later"):setEnabled(true)

                    local uiList = {}
                    table.insert(uiList,{node = icon})
                    table.insert(uiList,{node = lbsCoins, alignY = 1, alignX = 5})
                    util_alignCenter(uiList)
                end
            end
        )
    end
end

function RateusLayer:setViewVisible(starV, feedCoinsV, feedNoCoinsV, rateUsV, suggestV, feedRewardV, feedNoRewardV, grandV)
    self.m_node_rateStar:setVisible(starV)
    self.m_node_feedCoins:setVisible(feedCoinsV)
    self.m_node_feedNoCoins:setVisible(feedNoCoinsV)
    self.m_node_rateUs:setVisible(rateUsV)
    self.m_Node_suggest:setVisible(suggestV)
    self.m_node_feedReward:setVisible(feedRewardV)
    self.m_node_feedNoReward:setVisible(feedNoRewardV)
    if self.m_node_grand then
        self.m_node_grand:setVisible(grandV)
    end
end

function RateusLayer:clickFunc(sender)
    -- if self.isClick then
    --     return
    -- end
    -- self.isClick = true
    local sBtnName = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    self:clickBtn(sBtnName)
    performWithDelay(
        self,
        function()
            -- self.isClick = false
        end,
        0.3
    )
end

function RateusLayer:clickBtn(sBtnName)
    if sBtnName == "btn_yes" or sBtnName == "btn_rateUs" then
        if gLobalSendDataManager.getLogScore then
            --参数 类型 打开位置  页面名称  页面顺序  评分  奖励
            gLobalSendDataManager:getLogScore():sendScoreLog("SendFinsih", self.m_openSite, "RateusLayer", "G2")
        end
        globalData.rateUsData.m_isFirstOpen = true
        globalData.rateUsData:setRateUs(true)
        globalData.rateUsData:checkNetWork()
        -- csc firebase 打点
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.RatingSure)
        end
        self:closeUI(
            function()
                -- ios 新版评论逻辑
                if device.platform == "ios" then
                    globalData.rateUsData:iOSOpenRateUsViewV2(self.m_openSite)
                elseif device.platform == "android" then
                    -- globalData.skipForeGround = true
                    -- xcyy.GameBridgeLua:rateUsForSetting()
                    globalData.rateUsData:androidOpenRateUsViewV2(self.m_openSite)
                end
            end
        )
    elseif sBtnName == "btn_grandYes" then 
        -- grand 触发的 不需要记录 评论过啥的 状态
        self:closeUI(
            function()
                -- ios 新版评论逻辑
                if device.platform == "ios" then
                    globalData.rateUsData:iOSOpenRateUsViewV2(self.m_openSite)
                elseif device.platform == "android" then
                    globalData.rateUsData:androidOpenRateUsViewV2(self.m_openSite)
                end
            end
        )
    elseif sBtnName == "btn_feedYes" or sBtnName == "btn_feedNoCoinsyes" then
        -- self:setViewVisible(false,false,false,false,true,false,false, false)
        -- 先添加遮罩层
        -- gLobalViewManager:addLoadingAnima()
        globalData.newMessageNums = nil
        globalData.skipForeGround = true
        -- 更改为弹出aihelp 问卷调查 界面
        globalPlatformManager:openAIHelpRobot()
        -- performWithDelay(
        --     self,
        --     function()
        --         -- 需要延迟2s之后再让弹出成功
        --         gLobalViewManager:removeLoadingAnima()
        --         self:sendSuggest() -- 默认直接是点击了send 发送建议 文本修改为 aihelp feedback
        --     end,
        --     2
        -- )
        if gLobalSendDataManager.getLogScore then
            --参数 类型 打开位置  页面名称  页面顺序  评分  奖励
            gLobalSendDataManager:getLogScore():sendScoreLog("Finish", self.m_openSite, "RateusLayer", "D2")
        end
        self:closeUI()
    elseif sBtnName == "btn_feedNo" or sBtnName == "btn_feedNoCoinsno" then
        if gLobalSendDataManager.getLogScore then
            --参数 类型 打开位置  页面名称  页面顺序  评分  奖励
            gLobalSendDataManager:getLogScore():sendScoreLog("Suspend", self.m_openSite, "RateusLayer")
        end
        self:closeUI()
    elseif sBtnName == "btn_sendSuggest" then
        self:sendSuggest()
    elseif sBtnName == "btn_collect" then
        self:setButtonLabelDisEnabled("btn_collect", false)
        if gLobalSendDataManager.getLogScore then
            --参数 类型 打开位置  页面名称  页面顺序  评分  奖励
            gLobalSendDataManager:getLogScore():sendScoreLog("Reward", self.m_openSite, "RateusLayer", "D4")
        end
        self:showFlyCoins()
    elseif sBtnName == "btn_close1" or sBtnName == "btn_later" then
        if gLobalSendDataManager.getLogScore then
            --参数 类型 打开位置  页面名称  页面顺序  评分  奖励
            gLobalSendDataManager:getLogScore():sendScoreLog("Suspend", self.m_openSite, "RateusLayer")
        end
        self:closeUI()
    end
end
--
function RateusLayer:showFlyCoins()
    --发送成功
    local btnCollect = self:findChild("btn_collect")
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local endPos = globalData.flyCoinsEndPos
    local baseCoins = globalData.topUICoinCount
    local rewardCoins = globalData.userRunData.coinNum - baseCoins

    gLobalViewManager:pubPlayFlyCoin(
        startPos,
        endPos,
        baseCoins,
        rewardCoins,
        function()
            if not tolua.isnull(self) then
                performWithDelay(
                    self,
                    function()
                        if not tolua.isnull(self) then
                            self:closeUI(
                                function()
                                end
                            )
                        end
                    end,
                    globalData.rateUsData.p_closeTime
                )
            end
        end
    )
end

function RateusLayer:sendResultServer(str, type, version, score, callback)
    gLobalSendDataManager:getNetWorkFeature():sendActionUserComment(
        str,
        type,
        version,
        score,
        function(isSucc, addCoins)
            if tolua.isnull(self) then
                return
            end
            if isSucc then
                if callback then
                    callback(addCoins)
                end
            else
                --发送失败
                gLobalViewManager:showReConnect()
            end
        end
    )
end

-- 将方法单提出来
function RateusLayer:sendSuggest()
    -- local str = self:findChild("lbs_input"):getString()
    local str = "aihelp form feedback"
    local type = 1
    if globalData.rateUsData.m_isgetReward then
        type = 3
    end
    if gLobalSendDataManager.getLogScore then
        --参数 类型 打开位置  页面名称  页面顺序  评分  奖励
        gLobalSendDataManager:getLogScore():sendScoreLog("SendFinsih", self.m_openSite, "RateusLayer", "D3")
    end
    self:sendResultServer(
        str,
        type,
        globalData.rateUsData.m_version,
        self.m_score,
        function(coins)
            if globalData.rateUsData.m_isgetReward then
                globalData.rateUsData:setRateUs(true)
                globalData.rateUsData:checkNetWork()
                self:setViewVisible(false, false, false, false, false, false, true, false)
                performWithDelay(
                    self,
                    function()
                        self:closeUI()
                    end,
                    2
                )
            else
                globalData.rateUsData:setRateUsGetReward(true)
                globalData.rateUsData:setRateUs(true)
                globalData.rateUsData:checkNetWork()
                local icon = self:findChild("icon2")
                if icon then
                    local lbsCoins = self:findChild("lbs_coins2")
                    lbsCoins:setString(util_formatCoins(coins, 12))
                    -- local cont = lbsCoins:getContentSize()
                    -- icon:setPositionX(lbsCoins:getPositionX() - cont.width / 2 - 40)
                    self:setViewVisible(false, false, false, false, false, false, true, false)

                    local uiList = {}
                    table.insert(uiList,{node = icon})
                    table.insert(uiList,{node = lbsCoins, alignY = 2, alignX = 6})
                    util_alignCenter(uiList)
                end
            end
        end
    )
end

return RateusLayer
