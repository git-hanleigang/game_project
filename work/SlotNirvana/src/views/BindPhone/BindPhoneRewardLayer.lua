--[[
    FB奖励
]]

local BindPhoneRewardLayer = class("BindPhoneRewardLayer", BaseLayer)
local ShopItem = require("data.baseDatas.ShopItem")

function BindPhoneRewardLayer:ctor()
    BindPhoneRewardLayer.super.ctor(self)

    self.m_isShowActionEnabled = false
    self.m_isHideActionEnabled = false

    self:setLandscapeCsbName("Dialog/FB_signreward.csb")
end

function BindPhoneRewardLayer:initCsbNodes()
    self.m_node_reward = self:findChild("NodeReward") -- 奖励节点
    self.m_sp_ImgCoin = self:findChild("sp_coin3") -- 金币图标
    self.m_lb_coins = self:findChild("lb_font1") -- 金币
    self.m_btn_collect = self:findChild("btn_collect") -- 领取按钮
end

function BindPhoneRewardLayer:initDatas()
    local _data = G_GetMgr(G_REF.BindPhone):getBindData()
    if _data then
        self.m_coins = _data:getCoins()
        self.m_itmes = _data:getBindRewardItems()
    end
end

function BindPhoneRewardLayer:initView()
    -- 更新金币
    self:updateCoinNum()

    self:setExtendData("BindPhoneRewardLayer")
end

function BindPhoneRewardLayer:updateCoinNum()
    local coinStr = util_formatMoneyStr(self.m_coins)

    self.m_lb_coins:setString(coinStr)

    local uiList = {
        {node = self.m_sp_ImgCoin},
        {node = self.m_lb_coins, alignX = 20}
    }
    util_alignCenter(uiList)
end

function BindPhoneRewardLayer:onShowedCallFunc()
    self:runCsbAction(
        "show",
        false,
        function()
            self:runCsbAction("idle", true, nil, 60)
        end,
        60
    )
end

function BindPhoneRewardLayer:onClickMask()
    self:onClickCollect()
end

function BindPhoneRewardLayer:onClickCollect()
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
    -- 添加loading
    -- gLobalViewManager:addLoadingAnima(false, 1)

    self:successCallFun()
end

function BindPhoneRewardLayer:clickFunc(_sander)
    self:onClickCollect()
end

function BindPhoneRewardLayer:successCallFun()
    self:flyCoins()
end

function BindPhoneRewardLayer:failedCallFun()
    gLobalViewManager:showReConnect()
end

function BindPhoneRewardLayer:flyCoins()
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

function BindPhoneRewardLayer:closeSelf()
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

-- function BindPhoneRewardLayer:registerListener()
--     BindPhoneRewardLayer.super.registerListener(self)
--     gLobalNoticManager:addObserver(
--         self,
--         function(target, param)
--             if param then
--                 self:successCallFun()
--             else
--                 self:failedCallFun()
--             end
--         end,
--         ViewEventType.NOTIFY_FB_SIGN_REWARD
--     )
-- end

return BindPhoneRewardLayer
