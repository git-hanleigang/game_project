---
--[[
    @desc: 每日商城礼物功能
]]
local ShopFreeCoinsNode=class("ShopFreeCoinsNode",util_require("base.BaseView"))

ShopFreeCoinsNode.m_isCollect = nil
ShopFreeCoinsNode.m_rewardCoin = nil

function ShopFreeCoinsNode:initUI(data)

    self:createCsbNode(SHOP_RES_PATH.FreeCoinsNode)
    self:updateView()
end

function ShopFreeCoinsNode:initCsbNodes()
    
    self.m_nodeCollectCD = self:findChild("node_collectCd")
    self.m_nodeCollectNow = self:findChild("node_collectNow")

    self.m_rewardCoinLb = self:findChild("lb_coins")
    self.m_leftTimeLb = self:findChild("lb_time")

    self.m_touchPanel = self:findChild("click_area")
    self:addClick(self.m_touchPanel)
end

function ShopFreeCoinsNode:updateView()
    local totalWin = globalData.shopRunData:getShpGiftRewardCoins()
    self.m_rewardCoinLb:setString(util_formatCoins(totalWin,8))
    self:updateLabelSize({label = self.m_rewardCoinLb}, 130)

    self.m_isCollect = false

    self:updateCollectStatus()
end

-- 更新状态
function ShopFreeCoinsNode:updateCollectStatus()
    local leftTime = globalData.shopRunData:getShpGiftCD()
    local rewardCoin = globalData.shopRunData:getShpGiftRewardCoins()
    if leftTime == 0 then

        self.m_nodeCollectCD:setVisible(false)
        self.m_nodeCollectNow:setVisible(true)
        self.m_touchPanel:setVisible(true)
        self.m_rewardCoinLb:setString(util_formatCoins(rewardCoin,8))

        -- self:runCsbAction("animation",false,function (  )

        --     schedule(self.m_giftNode , function (  )
        --         self:runCsbAction("animation",false)
        --     end , 2.5)

        -- end)

        self.m_rewardCoin = rewardCoin
    else
        self.m_nodeCollectCD:setVisible(true)
        self.m_nodeCollectNow:setVisible(false)
        self.m_rewardCoin = 0
        -- self:runCsbAction("idle",false)
        self:checkCdTimer()
    end

end


function ShopFreeCoinsNode:clickFunc(sender)
    if self.m_isCollect == true then
        return
    end
    self.m_isCollect = true
    local name = sender:getName()
    if name == "click_area" then
        self:sendCollectMsg()

        -- 引导打点：免费领取商店金币-4.点击领取金币
        if gLobalSendDataManager:getLogGuide():isGuideBegan(9) then
            gLobalSendDataManager:getLogGuide():sendGuideLog(9, 4)
        end
    end
    
    
end
--[[
    @desc: 发送金币收集消息
]]
function ShopFreeCoinsNode:sendCollectMsg( )
    --检查联网状态
    if gLobalSendDataManager:checkShowNetworkDialog() then
        return
    end
    self.m_touchPanel:setVisible(false)
    -- --添加loading
    gLobalViewManager:addLoadingAnima()

    gLobalSendDataManager:getNetWorkFeature():sendActionShopBonus(self.m_rewardCoin, false, 0,function(target,resData)
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

        if self == nil or self.flyBonusGameCoins == nil then
            return -- 做界面关闭时 网络消息才返回的情况
        end
        local flyBonusGameCoinsCallFunc = function(  )
            
            if not tolua.isnull(self) then
                globalData.shopRunData.shopRewardTime = 0

                performWithDelay(self,function (  )
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,
                                                        globalData.userRunData.coinNum)
                end,1)
    
                -- if gLobalSendDataManager.getLogFeature ~= nil then
                --     gLobalSendDataManager:getLogFeature():sendShopGiftLog(self.m_rewardCoin)
                -- end
                self:updateCollectStatus()
            end
          
        end

        self:flyBonusGameCoins(flyBonusGameCoinsCallFunc)


    end, function()
        if self == nil or self.flyBonusGameCoins == nil then
            return -- 做界面关闭时 网络消息才返回的情况
        end
        gLobalViewManager:removeLoadingAnima()
        --弹窗
        gLobalViewManager:showReConnect()
        if self.m_isCollect then
            self.m_isCollect = false
        end
    end)
end

function ShopFreeCoinsNode:flyBonusGameCoins(func)
    local endPos = globalData.flyCoinsEndPos
    local startPos = self:findChild("sp_giftIcon"):getParent():convertToWorldSpace(cc.p(self:findChild("sp_giftIcon"):getPosition()))
    local baseCoins = globalData.topUICoinCount 

    local view = gLobalViewManager:pubPlayFlyCoin(startPos,endPos,baseCoins,self.m_rewardCoin,function ()
        if func then
            func()
        end
        if self.m_isCollect then
            self.m_isCollect = false
        end
    end)

end


----------- 定时器 ----------- 
function ShopFreeCoinsNode:checkCdTimer()
    if self.m_checkCdTimerAction ~= nil then
        self:stopAction(self.m_checkCdTimerAction)
        self.m_checkCdTimerAction = nil
    end
    self.m_checkCdTimerAction =
        util_schedule(
        self,
        function()
            self:updateCdTime()
        end,
        1
    )
    self:updateCdTime()
end

function ShopFreeCoinsNode:updateCdTime()
    local leftTime = globalData.shopRunData:getShpGiftCD()
    self.m_leftTimeLb:setString(util_count_down_str(leftTime))

    if leftTime == 0 then
        self:stopAction(self.m_checkCdTimerAction)
        self:updateCollectStatus()
    end
end


function ShopFreeCoinsNode:onExit()
    if self.buffAction ~= nil then
        self:stopAction(self.buffAction)
        self.buffAction = nil
    end
    if self.m_checkCdTimerAction ~= nil then
        self:stopAction(self.m_checkCdTimerAction)
        self.m_checkCdTimerAction = nil
    end
    ShopFreeCoinsNode.super.onExit(self)
end

return ShopFreeCoinsNode