--[[
Author: cxc
Date: 2021-01-11 20:14:10
LastEditTime: 2021-01-19 20:37:07
LastEditors: Please set LastEditors
Description: 常规促销 小游戏 选择哪个已奖励 金币袋 item
FilePath: /SlotNirvana/src/views/sale/LuckyChooseItem.lua
--]]
local LuckyChooseItem = class("LuckyChooseItem", util_require("base.BaseView"))
local LuckyChooseManager = util_require("manager/System/LuckyChooseManager"):getInstance()

local ITEM_STATE = {
    INIT = 1, -- 静态
    OEPN = 2, -- 开启
    UNOPEN = 3, -- 未开启
} 

function LuckyChooseItem:initUI(_idx)
  
    local csbName = "Sale/Bag.csb"
    self:createCsbNode(csbName)

    self.m_idx = _idx
    self.m_canTouch = true

    self.m_nodeNormal = self:findChild("sp_bagNormal") -- 未开启sp
    self.m_spBagMask = self:findChild("sp_bagMask") -- unOpen状态蒙版
    self.m_nodeOpen = self:findChild("sp_bagOpen") -- 开启sp
    self.m_lbMoney = self:findChild("lb_money1") -- 奖励的金钱 lb
    self.m_lbMoneyMask = self:findChild("lb_money_0") -- 奖励的金钱 lb unOpen状态蒙版

    self:updateState(ITEM_STATE.INIT)
end

-- 刷新UI
function LuckyChooseItem:refreshUI(_rewardInfo)
    self.m_canTouch = false
    -- {"coins":495000000,"hit":false}
    _rewardInfo = _rewardInfo or {coins=0, hit=false}
    local state = ITEM_STATE.UNOPEN
    local delayTime = 1.5
    if _rewardInfo.hit then
        state = ITEM_STATE.OPEN
        delayTime = 0
    end

    self.m_lbMoney:setString(util_formatCoins(tonumber(_rewardInfo.coins), 3, nil, nil, true))
    self.m_lbMoneyMask:setString(util_formatCoins(tonumber(_rewardInfo.coins), 3, nil, nil, true))
    performWithDelay(self, function()
        self:updateState(state, _rewardInfo)
    end, delayTime)
end

-- 更新 金钱袋状态
function LuckyChooseItem:updateState(_state, _rewardInfo)

    if _state == ITEM_STATE.INIT then
        -- 初始化状态
        self:runCsbAction("idle", true)
    elseif _state == ITEM_STATE.OPEN then
        -- 开启状态
        self:runCsbAction("star", false, function() 
            self:runCsbAction("idle_star")
            -- 弹出获得的奖励
            performWithDelay(self, function()
                LuckyChooseManager:popCollectCoinLayer(_rewardInfo)
            end, 1)
        end, 60)
    elseif _state == ITEM_STATE.UNOPEN then
        -- 未开启状态
        self:runCsbAction("over", false, function() 
            self:runCsbAction("idle_over")
        end, 60)
    end
    
end

-- 统一点击回调
function LuckyChooseItem:clickFunc(sender)
    if not self.m_canTouch then
        return
    end

    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_touch" then
        self.m_canTouch = false
        LuckyChooseManager:sendGainRewardReq(self.m_idx)
    end
end


return LuckyChooseItem