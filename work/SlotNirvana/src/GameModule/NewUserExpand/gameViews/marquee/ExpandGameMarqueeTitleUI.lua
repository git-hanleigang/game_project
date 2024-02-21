--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-10 14:10:33
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-10 14:10:44
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/marquee/ExpandGameMarqueeTitleUI.lua
Description: 扩圈小游戏 跑马灯 标题UI
--]]
local ExpandGameMarqueeConfig = util_require("GameModule.NewUserExpand.config.ExpandGameMarqueeConfig")
local ExpandGameMarqueeTitleUI = class("ExpandGameMarqueeTitleUI", BaseView)

function ExpandGameMarqueeTitleUI:getCsbName()
    return "MarqueeGame/csb/MarqueeGame_Title.csb"
end

function ExpandGameMarqueeTitleUI:initCsbNodes()
    ExpandGameMarqueeTitleUI.super.initCsbNodes(self)

    self.m_lbCoins = self:findChild("lb_coin")
    self.m_alignUIList = {
        {node = self:findChild("sp_coin")},
        {node = self.m_lbCoins, alignX = 5}
    }

    self.m_nodeBuff = self:findChild("node_buff")
end

function ExpandGameMarqueeTitleUI:initUI(_gameData)
    ExpandGameMarqueeTitleUI.super.initUI(self)
    self.m_gameData = _gameData

    -- 累积金币
    self:updateLbCoinsUI()
    
    -- 积累成倍buff
    self:updateBuffUI()
    self:runCsbAction("idle", true)
end

-- 累积金币
function ExpandGameMarqueeTitleUI:updateLbCoinsUI()
    local coinsValue = self.m_gameData:getTotalCoins()
    if self.m_bOverCoins then
        coinsValue = self.m_bOverCoins
    end
    
    self.m_lbCoins:setString(util_formatCoins(coinsValue, 20))
    self.m_curCoins = coinsValue
    self:updateCoinLbSizeScale() 
end
-- 更新金币size 大小
function ExpandGameMarqueeTitleUI:updateCoinLbSizeScale()
    util_alignCenter(self.m_alignUIList, 0, 1000)
end

function ExpandGameMarqueeTitleUI:lbWinJumCoinsAni(_newCoinsV)
    local subV = _newCoinsV - self.m_curCoins
    local addV = subV / (0.92 * 60)
    util_jumpNumExtra(self.m_lbCoins, self.m_curCoins, _newCoinsV, addV, 1/60, util_getFromatMoneyStr, {20}, nil, nil, util_node_handler(self, self.updateLbCoinsUI), util_node_handler(self, self.updateCoinLbSizeScale))
end
function ExpandGameMarqueeTitleUI:lbCutDownCoinsAni(_newCoinsV)
    local subV = _newCoinsV - self.m_curCoins
    local fallV = subV / (0.92 * 60)
    util_cutDownNum(self.m_lbCoins, self.m_curCoins, _newCoinsV, fallV, 1/60, {30}, nil, nil, util_node_handler(self, self.updateLbCoinsUI), util_node_handler(self, self.updateCoinLbSizeScale))
    gLobalSoundManager:playSound(ExpandGameMarqueeConfig.SOUNDS.COINS_DOWN)
end

-- spin 掉落金币
function ExpandGameMarqueeTitleUI:playSpinAddCoinsAct(_cb)
    -- 帧 120 - 165 -win
    -- 帧 175 - 230 -start
    self:runCsbAction("start", false, function()
        if _cb then
            _cb()
        end
        self:runCsbAction("idle", true)
    end, 60)
end

-- 播放金币变动 动画
function ExpandGameMarqueeTitleUI:playCoinChangeAni(_cb)
    performWithDelay(self, _cb, (230-175)/60)

    -- 更新积累成倍buff
    self:updateBuffUI()

    local coinsValue = self.m_gameData:getTotalCoins()
    if coinsValue > self.m_curCoins then
        self:lbWinJumCoinsAni(coinsValue)
        self:playSpinAddCoinsAct()
        return
    end

    self:lbCutDownCoinsAni(coinsValue)
end

-- 小游戏结束 收集金币动画
function ExpandGameMarqueeTitleUI:playOverCollectCoinsAni(_rewardCoins, _cb)
    _rewardCoins = tonumber(_rewardCoins) or 0
    local coinsValue = self.m_gameData:getTotalCoins()
    if _rewardCoins > coinsValue then
        self:runCsbAction("buff", false, _cb, 60)
        performWithDelay(self, function()
            self.m_bOverCoins = _rewardCoins
            self.m_nodeBuff:setVisible(false)
            self:lbWinJumCoinsAni(_rewardCoins)
        end, (290-206)/60)
        return
    end

    performWithDelay(self, _cb, 0)
end

-- 积累成倍buff
function ExpandGameMarqueeTitleUI:updateBuffUI()
    if not self.m_buffView then
        local view = util_createView("GameModule.NewUserExpand.gameViews.marquee.ExpandGameMarqueeTitleBuffUI")
        self.m_nodeBuff:addChild(view)
        self.m_buffView = view
    end

    local buffMulSum = self.m_gameData:getTotalMulSum()
    self.m_buffView:updateUI(buffMulSum)
end

-- 获取金币世界坐标
function ExpandGameMarqueeTitleUI:getCoinsPosW()
    local node = self:findChild("node_coin")
    local posW = node:convertToWorldSpace(cc.p(0, 0))
    return posW
end

-- 获取buff世界坐标
function ExpandGameMarqueeTitleUI:getBuffPosW()
    local posW = self.m_nodeBuff:convertToWorldSpace(cc.p(0, 0))
    return posW
end

return ExpandGameMarqueeTitleUI