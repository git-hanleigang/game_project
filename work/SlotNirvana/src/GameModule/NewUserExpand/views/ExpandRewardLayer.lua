--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-13 17:04:45
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-13 17:04:55
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/views/ExpandRewardLayer.lua
Description: 扩圈系统 通用奖励弹板
--]]
local NewUserExpandConfig = util_require("GameModule.NewUserExpand.config.NewUserExpandConfig")
local ExpandRewardLayer = class("ExpandRewardLayer", BaseLayer)

function ExpandRewardLayer:initDatas(_coins, _cb)
    ExpandRewardLayer.super.initDatas(self)

    self.m_coins = tonumber(_coins) or 0
    self.m_closeCB = _cb

    self:setLandscapeCsbName("NewUser_Expend/Activity/csd/NewUser_Reward.csb")
    self:setPortraitCsbName("NewUser_Expend/Activity/csd/NewUser_Reward_shu.csb")
    self:setPauseSlotsEnabled(true)
    self:setExtendData("ExpandRewardLayer")
    self:setName("ExpandRewardLayer")
    self:setCommonShowSound(NewUserExpandConfig.SOUNDS.REWARD_POP)
end

function ExpandRewardLayer:initView()
    -- 金币
    self:initCoinsUI()
end

-- 金币
function ExpandRewardLayer:initCoinsUI()
    local lbCoins = self:findChild("lb_coin")
    lbCoins:setString(util_formatCoins(self.m_coins, 20))
    local alignUIList = {
        {node = self:findChild("sp_coin")},
        {node = lbCoins, alignX = 5}
    }
    util_alignCenter(alignUIList, 0, 1000)
end

function ExpandRewardLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_collect" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:flyCurrency(function()
            self:closeUI(self.m_closeCB)
        end)
    end
end

function ExpandRewardLayer:flyCurrency(func)
    local btnCollect = self:findChild("btn_collect")
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local curMgr = G_GetMgr(G_REF.Currency)
    if curMgr then
        local flyList = {}
        if self.m_coins > 0 then
            table.insert(flyList, {cuyType = FlyType.Coin, addValue = self.m_coins, startPos = startPos})
        end
        curMgr:playFlyCurrency(flyList, func)
    else
        if self.m_coins <= 0 then
            func()
            return
        end

        local btnCollect = self:findChild("btn_collect")
        gLobalViewManager:pubPlayFlyCoin(startPos, globalData.flyCoinsEndPos, globalData.topUICoinCount, self.m_coins, func)
    end
end

return ExpandRewardLayer