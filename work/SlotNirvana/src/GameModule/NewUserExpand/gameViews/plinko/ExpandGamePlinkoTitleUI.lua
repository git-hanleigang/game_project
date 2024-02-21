--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-20 16:47:42
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-20 16:48:01
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/plinko/ExpandGamePlinkoTitleUI.lua
Description: 扩圈小游戏 弹珠 标题UI
--]]
local ExpandGamePlinkoConfig = util_require("GameModule.NewUserExpand.config.ExpandGamePlinkoConfig")
local ExpandGamePlinkoTitleUI = class("ExpandGamePlinkoTitleUI", BaseView)

function ExpandGamePlinkoTitleUI:getCsbName()
    return "PlinkoGame/csb/PlinkoGame_Title.csb"
end

function ExpandGamePlinkoTitleUI:initCsbNodes()
    ExpandGamePlinkoTitleUI.super.initCsbNodes(self)

    self.m_lbCoins = self:findChild("lb_coin")
    self.m_alignUIList = {
        {node = self:findChild("sp_coin")},
        {node = self.m_lbCoins, alignX = 5}
    }
end

function ExpandGamePlinkoTitleUI:initUI(_gameData)
    ExpandGamePlinkoTitleUI.super.initUI(self)
    self.m_gameData = _gameData

    -- 累积金币
    self:updateLbCoinsUI()
    
    self:runCsbAction("idle", true)
end

-- 累积金币
function ExpandGamePlinkoTitleUI:updateLbCoinsUI()
    local coinsValue = self.m_gameData:getTotalCoins()
    
    self.m_lbCoins:setString(util_formatCoins(coinsValue, 20))
    self.m_curCoins = coinsValue
    self:updateCoinLbSizeScale() 
end
-- 更新金币size 大小
function ExpandGamePlinkoTitleUI:updateCoinLbSizeScale()
    util_alignCenter(self.m_alignUIList, 0, 1000)
end

function ExpandGamePlinkoTitleUI:lbWinJumCoinsAni(_newCoinsV)
    local subV = _newCoinsV - self.m_curCoins
    local addV = subV / (0.92 * 60)
    util_jumpNumExtra(self.m_lbCoins, self.m_curCoins, _newCoinsV, addV, 1/60, util_getFromatMoneyStr, {20}, nil, nil, util_node_handler(self, self.updateLbCoinsUI), util_node_handler(self, self.updateCoinLbSizeScale))
end
function ExpandGamePlinkoTitleUI:lbCutDownCoinsAni(_newCoinsV)
    local subV = _newCoinsV - self.m_curCoins
    local fallV = subV / (0.92 * 60)
    util_cutDownNum(self.m_lbCoins, self.m_curCoins, _newCoinsV, fallV, 1/60, {30}, nil, nil, util_node_handler(self, self.updateLbCoinsUI), util_node_handler(self, self.updateCoinLbSizeScale))
end

-- spin 掉落金币
function ExpandGamePlinkoTitleUI:playSpinAddCoinsAct()
    -- 帧 120 - 165 -win
    -- 帧 175 - 230 -start
    self:runCsbAction("win", false, function()
        self:runCsbAction("idle", true)
    end, 60)
end

-- 播放金币变动 动画
function ExpandGamePlinkoTitleUI:playCoinChangeAni(_cb)
    performWithDelay(self, _cb, (230-175)/60)
    gLobalSoundManager:playSound(ExpandGamePlinkoConfig.SOUNDS.COIN_CHANGE)

    local coinsValue = self.m_gameData:getTotalCoins()
    if coinsValue > self.m_curCoins then
        self:lbWinJumCoinsAni(coinsValue)
        self:playSpinAddCoinsAct()
        return
    end

    self:lbCutDownCoinsAni(coinsValue)
end

-- 获取金币世界坐标
function ExpandGamePlinkoTitleUI:getCoinsPosW()
    local node = self:findChild("node_coin")
    local posW = node:convertToWorldSpace(cc.p(0, 0))
    return posW
end

return ExpandGamePlinkoTitleUI