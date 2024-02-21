--[[
    FB奖励
]]
local BindPhoneUserInfoRewardLayer = class("BindPhoneUserInfoRewardLayer", BaseLayer)
local ShopItem = require("data.baseDatas.ShopItem")

function BindPhoneUserInfoRewardLayer:ctor()
    BindPhoneUserInfoRewardLayer.super.ctor(self)
    self:setLandscapeCsbName("Dialog/PhoneBindReward.csb")
end

function BindPhoneUserInfoRewardLayer:initCsbNodes()
    self.m_sp_ImgCoin = self:findChild("coin_dollar") -- 金币图标
    self.m_lb_coins = self:findChild("m_lb_reward") -- 金币
    self.m_btn_collect = self:findChild("btn_collect") -- 领取按钮
end

function BindPhoneUserInfoRewardLayer:initDatas()
    local _data = G_GetMgr(G_REF.BindPhone):getBindData()
    if _data then
        self.m_coins = _data:getCoins()
        self.m_itmes = _data:getBindRewardItems()
    end
end

function BindPhoneUserInfoRewardLayer:initView()
    -- 更新金币
    self:updateCoinNum()

    self:setExtendData("BindPhoneUserInfoRewardLayer")
end

function BindPhoneUserInfoRewardLayer:updateCoinNum()
    local coinStr = util_formatMoneyStr(self.m_coins)

    self.m_lb_coins:setString(coinStr)

    local uiList = {
        {node = self.m_sp_ImgCoin},
        {node = self.m_lb_coins, alignX = 20}
    }
    util_alignCenter(uiList)
end

function BindPhoneUserInfoRewardLayer:playShowAction()
    BindPhoneUserInfoRewardLayer.super.playShowAction(self, "show")
end

function BindPhoneUserInfoRewardLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function BindPhoneUserInfoRewardLayer:onClickMask()
    self:onClickCollect()
end

function BindPhoneUserInfoRewardLayer:onClickCollect()
    if self.m_isTouch then
        return
    end
    self.m_isTouch = true
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    -- 检查联网状态
    if gLobalSendDataManager:checkShowNetworkDialog() then
        self:failedCallFun()
        return
    end

    self:successCallFun()
end

function BindPhoneUserInfoRewardLayer:clickFunc(_sander)
    self:onClickCollect()
end

function BindPhoneUserInfoRewardLayer:successCallFun()
    self:flyCoins()
end

function BindPhoneUserInfoRewardLayer:failedCallFun()
    gLobalViewManager:showReConnect()
end

function BindPhoneUserInfoRewardLayer:flyCoins()
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

function BindPhoneUserInfoRewardLayer:closeSelf()
    self:closeUI(
        function()
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end
    )
end

return BindPhoneUserInfoRewardLayer
