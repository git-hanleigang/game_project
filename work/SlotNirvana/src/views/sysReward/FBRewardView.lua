--[[
    FB奖励
]]
local FBSignRewardManager = require("manager.System.FBSignRewardManager"):getInstance()
local FBRewardView = class("FBRewardView", BaseLayer)
local ShopItem = require "data.baseDatas.ShopItem"

function FBRewardView:ctor()
    FBRewardView.super.ctor(self)

    self.m_isShowActionEnabled = false
    self.m_isHideActionEnabled = false

    self:setLandscapeCsbName("Dialog/FB_signreward.csb")
end

function FBRewardView:initCsbNodes()
    self.m_node_reward = self:findChild("NodeReward") -- 奖励节点
    self.m_sp_ImgCoin = self:findChild("sp_coin3") -- 金币图标
    self.m_lb_coins = self:findChild("lb_font1") -- 金币
    self.m_btn_collect = self:findChild("btn_collect") -- 领取按钮
end

function FBRewardView:initDatas()
    self.m_coins = globalData.FBRewardData:getCoins()
    self.m_itmes = globalData.FBRewardData:getItems()
end

function FBRewardView:initView()
    -- 更新金币
    self:updateCoinNum()

    self:setExtendData("FBRewardView")
end

function FBRewardView:updateCoinNum()
    local coinStr = util_formatMoneyStr(self.m_coins)

    self.m_lb_coins:setString(coinStr)

    local uiList = {
        {node = self.m_sp_ImgCoin},
        {node = self.m_lb_coins, alignX = 20}
    }
    util_alignCenter(uiList)
end

function FBRewardView:onShowedCallFunc()
    self:runCsbAction(
        "show",
        false,
        function()
            self:runCsbAction("idle", true, nil, 60)
        end,
        60
    )
end

function FBRewardView:onClickMask()
    self:onClickCollect()
end

function FBRewardView:onClickCollect()
    if self.m_isTouch then
        return
    end
    self.m_isTouch = true
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    --检查联网状态
    if gLobalSendDataManager:checkShowNetworkDialog() then
        self:failedCallFun()
        return
    end
    -- --添加loading
    gLobalViewManager:addLoadingAnima(false, 1)
    -- 发送消息
    FBSignRewardManager:sendReward()
end

function FBRewardView:clickFunc(_sander)
    self:onClickCollect()
end

function FBRewardView:successCallFun()
    print("Cool测试～～～～～领取奖励成功")
    globalData.signInfo.fbReward = globalData.userRunData.fbUdid
    gLobalSendDataManager:getNetWorkFeature():sendActionLoginReward(globalData.signInfo)
    self:flyCoins()
end

function FBRewardView:failedCallFun()
    print("Cool测试～～～～～领取奖励失败")
    gLobalViewManager:showReConnect()
end

function FBRewardView:flyCoins()
    local callback = function()
        if not tolua.isnull(self) then
            self:closeSelf()
        end
    end

    if self.m_coins > 0 then
        local endPos = globalData.flyCoinsEndPos
        local coinsNode = self.m_btn_collect
        local startPos = coinsNode:getParent():convertToWorldSpace(cc.p(coinsNode:getPosition()))
        local baseCoins = globalData.topUICoinCount
        local rewardCoins = self.m_coins
        gLobalViewManager:pubPlayFlyCoin(startPos, endPos, baseCoins, rewardCoins, callback)
    else
        callback()
    end
end

function FBRewardView:closeSelf()
    self:runCsbAction(
        "over",
        false,
        function()
            self:closeUI(
                function()
                    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                end
            )
        end,
        60
    )
end

function FBRewardView:registerListener()
    FBRewardView.super.registerListener(self)
    gLobalNoticManager:addObserver(
        self,
        function(target, param)
            if param then
                self:successCallFun()
            else
                self:failedCallFun()
            end
        end,
        ViewEventType.NOTIFY_FB_SIGN_REWARD
    )
end

return FBRewardView
