--[[
Author: cxc
Date: 2021-12-15 14:15:16
LastEditTime: 2021-12-15 14:15:17
LastEditors: your name
Description: 乐透 结算后弹出的上一期中头像信息
FilePath: /SlotNirvana/src/views/lottery/other/LotteryPerGrandPrizeInfoLayer.lua
--]]
local LotteryPerGrandPrizeInfoLayer = class("LotteryPerGrandPrizeInfoLayer", BaseLayer)

function LotteryPerGrandPrizeInfoLayer:ctor(_maxCoins)
    LotteryPerGrandPrizeInfoLayer.super.ctor(self)
   
    self.m_data = G_GetMgr(G_REF.Lottery):getData()
    self.m_maxCoins = _maxCoins

    self:setPauseSlotsEnabled(true) 
    self:setKeyBackEnabled(true)
    self:setExtendData("LotteryPerGrandPrizeInfoLayer")
    self:setLandscapeCsbName("Lottery/csd/Lottery_tanban_show.csb")
end

-- 初始化节点
function LotteryPerGrandPrizeInfoLayer:initCsbNodes()
    LotteryPerGrandPrizeInfoLayer.super.initCsbNodes(self)

    self.m_lbCoins = self:findChild("lb_coin_num")
    self.m_lbPreiod = self:findChild("lb_time")
    self.m_nodePlayer1 = self:findChild("node_player_1")
    self.m_nodePlayer2 = self:findChild("node_player_2")
    self.m_nodePlayerOnly = self:findChild("node_player_only")

    -- 新增优化 显示中奖玩家的美金
    self.m_lbDollar = self:findChild("lb_dollar")
    self.m_lbDollar:setVisible(false)
end

-- 初始化界面显示
function LotteryPerGrandPrizeInfoLayer:initView()
    LotteryPerGrandPrizeInfoLayer.super.initView(self)

    -- 期号
    local lastPeriod = self.m_data:getLastTimeNumber()
    self.m_lbPreiod:setString(lastPeriod .. " LOTTERY")

    -- 中奖人信息
    local userInfoList = self.m_data:getPreWinUserList()
    for i=1, 2 do
        local userInfo = userInfoList[i]
        if userInfo then
            self:initPlayerInfo(i, userInfo)
        end
        if i == 1 and userInfo then
            self:initPlayerInfo(nil, userInfo)
        end
    end

    -- 金币
    local coins = self.m_data:getLastPerGrandPrize()
    --服务器现在发的是总的钱不是平分后的，不用✖️2
    --coins = coins * #userInfoList
    self.m_lbCoins:setString(util_formatCoins(coins, 20))
    util_scaleCoinLabGameLayerFromBgWidth(self.m_lbCoins, 724)

    -- 显示上一期头奖玩家的美刀
    local lastPerGrandUsd = self.m_data:getLastPerGrandPrizeUsd()
    if lastPerGrandUsd and lastPerGrandUsd ~= 0 then
        self.m_lbDollar:setVisible(true)
        self.m_lbDollar:setString("Grand Prize Worth $" .. tostring(lastPerGrandUsd))
    end

    local csbActNameList = {"idle3", "idle2", "idle1"}
    self:runCsbAction(csbActNameList[#userInfoList+1], true)
end

-- 初始化玩家信息
function LotteryPerGrandPrizeInfoLayer:initPlayerInfo(_idx, _userInfo)
    local refNode = self.m_nodePlayerOnly
    if _idx == 1 then
        refNode = self.m_nodePlayer1
    elseif _idx == 2 then
        refNode = self.m_nodePlayer2
    end

    local nodePlayer = util_createView("views.lottery.other.LotteryUserInfoView", _userInfo)
    refNode:addChild(nodePlayer)
end


function LotteryPerGrandPrizeInfoLayer:clickFunc(sender)
    local name = sender:getName()
    
    if name == "btn_close" then
        sender:setTouchEnabled(false)
        self:closeUI()
    end
end

function LotteryPerGrandPrizeInfoLayer:closeUI()
    local callFunc = function()
        if self.m_maxCoins > 0 then
            G_GetMgr(G_REF.Lottery):showCollectRewardLayer(self.m_maxCoins)
        else
            --弹失败的弹板
            G_GetMgr(G_REF.Lottery):showRewardTipsLayer()
        end
    end
    
    LotteryPerGrandPrizeInfoLayer.super.closeUI(self, callFunc)
end

return LotteryPerGrandPrizeInfoLayer
