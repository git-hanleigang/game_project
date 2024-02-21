--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-10 18:22:23
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-10 20:08:10
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/marquee/machine/MarqueeRewardBigItemUI.lua
Description: 扩圈小游戏 跑马灯 道具Big
--]]
local ExpandGameMarqueeConfig = util_require("GameModule.NewUserExpand.config.ExpandGameMarqueeConfig")
local MarqueeRewardBigItemUI = class("MarqueeRewardBigItemUI", BaseView)

function MarqueeRewardBigItemUI:initDatas(_mainView)
    MarqueeRewardBigItemUI.super.initDatas(self)

    self.m_mainView = _mainView
end

function MarqueeRewardBigItemUI:getCsbName()
    return "MarqueeGame/csb/MarqueeGame_Show_reward.csb"
end

function MarqueeRewardBigItemUI:updateType(_rewardData)
    self:runCsbAction("idle")

    if not _rewardData then
        self:setVisible(false)
        return
    end

    self:setVisible(true)
    local rewardType = _rewardData:getRewardType()
    -- 道具背景
    self:updateBgUI(rewardType)

    -- 道具显隐
    local nodeContent = self:findChild("node_show_reward")
    for _, _node in pairs(nodeContent:getChildren()) do
        local nodeName = _node:getName()
        _node:setVisible(nodeName == ExpandGameMarqueeConfig.TYPE_NODE_NAME[rewardType])
    end

    -- 道具详情UI
    if ExpandGameMarqueeConfig.TYPE_NODE_NAME[rewardType] == "node_coin" then
        -- 金币
        self:updateCoinLbUI(_rewardData)
    elseif ExpandGameMarqueeConfig.TYPE_NODE_NAME[rewardType] == "node_X" then
        -- 成倍
        self:updateMulLbUI(_rewardData)
    end
end

-- 道具背景
function MarqueeRewardBigItemUI:updateBgUI(_rewardType)
    local spBg = self:findChild("sp_bg")
    local path = string.format("MarqueeGame/ui/show_di/MarqueeGame_show_%s.png", ExpandGameMarqueeConfig.TYPE_BG_IDX[_rewardType])
    util_changeTexture(spBg, path)
end

-- 金币
function MarqueeRewardBigItemUI:updateCoinLbUI(_rewardData)
    local rewardType = _rewardData:getRewardType()
    local coinsV = _rewardData:getValue()

    local lbSmall = self:findChild("lb_coin_small")
    local lbBig = self:findChild("lb_coin_big")
    lbSmall:setString(util_formatCoins(coinsV, 3))
    lbBig:setString(util_formatCoins(coinsV, 3))

    lbSmall:setVisible(rewardType == "B")
    lbBig:setVisible(rewardType == "A")
end

-- 成倍
function MarqueeRewardBigItemUI:updateMulLbUI(_rewardData)
    local lbMul = self:findChild("lb_X")
    local mulV = _rewardData:getValue()

    lbMul:setString("X"..mulV)
end

function MarqueeRewardBigItemUI:playChooseAni(_cb, _rewardData)
    _cb = _cb or function() end
    self:updateType(_rewardData)
    if not _rewardData then
        performWithDelay(self, _cb, 0.1)
        return
    end

    local rewardType = _rewardData:getRewardType()
    local nodeName = ExpandGameMarqueeConfig.TYPE_NODE_NAME[rewardType]
    local node = self:findChild(nodeName)
    if not node or not node:isVisible() then
        performWithDelay(self, _cb, 0.1)
        return
    end

    if nodeName == "node_boom" then
        -- 炸弹类型播动画
        self:runCsbAction("start", false, _cb, 60)
        gLobalSoundManager:playSound(ExpandGameMarqueeConfig.SOUNDS.BOOM)
    elseif nodeName == "node_coin" then
        -- 金币放大 飞到 金币栏
        self:createCoinFlyAni(_cb, _rewardData)
        self.m_mainView:playCaidaiAni()
        gLobalSoundManager:playSound(ExpandGameMarqueeConfig.SOUNDS.FLY_COINS)
    elseif nodeName == "node_X" then
        -- 成倍奖励 飞到 标题 buff栏
        self:createBuffFlyAni(_cb, _rewardData)
        self.m_mainView:playCaidaiAni()
        gLobalSoundManager:playSound(ExpandGameMarqueeConfig.SOUNDS.FLY_DOUBLE)
    else
        performWithDelay(self, _cb, 0.1)
    end

end

-- 金币放大 飞到 金币栏
function MarqueeRewardBigItemUI:createCoinFlyAni(_cb, _rewardData)
    local startPos = self:convertToWorldSpace(cc.p(0, 0)) 
    self.m_mainView:playCoinFlyAni(startPos, _cb, _rewardData)
end

-- 成倍buff放大 飞到 标题 buff栏
function MarqueeRewardBigItemUI:createBuffFlyAni(_cb, _rewardData)
    local startPos = self:convertToWorldSpace(cc.p(0, 0)) 
    self.m_mainView:playBuffFlyAni(startPos, _cb, _rewardData)
end


function MarqueeRewardBigItemUI:hideBgUI()
    local spBg = self:findChild("sp_bg")
    spBg:setVisible(false)
end
function MarqueeRewardBigItemUI:hideCoinBgUI()
    local spCoinsBg = self:findChild("sp_coins")
    spCoinsBg:setVisible(false)
end


return MarqueeRewardBigItemUI