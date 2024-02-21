--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-08-11 11:15:16
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-08-11 11:17:13
FilePath: /SlotNirvana/src/views/lottery/reward/skipReward/LotteryPerGrandPrizeInfoUI.lua
Description: 乐透 上一期中大奖玩家信息
--]]
local LotteryPerGrandPrizeInfoUI = class("LotteryPerGrandPrizeInfoUI", BaseView)

function LotteryPerGrandPrizeInfoUI:initDatas()
    LotteryPerGrandPrizeInfoUI.super.initDatas(self)

    self.m_data = G_GetMgr(G_REF.Lottery):getData()
end

function LotteryPerGrandPrizeInfoUI:initUI()
    LotteryPerGrandPrizeInfoUI.super.initUI(self)

    -- 中奖人信息
    self:initPlayerInfoUI()

    -- 金币
    self:initCoinsUI()
end

function LotteryPerGrandPrizeInfoUI:getCsbName()
    return "Lottery/csd/Drawlottery/Lottery_Drawlottery_rewards2_show.csb"
end

-- 中奖人信息
function LotteryPerGrandPrizeInfoUI:initPlayerInfoUI()
    local userInfoList = self.m_data:getPreWinUserList()
    local count = math.min(#userInfoList, 2)
    for i=1, count do
        local userInfo = userInfoList[i]
        self:initPlayerInfo(i, userInfo)
    end

    self:runCsbAction("idle_" .. count, true)
end

-- 初始化玩家信息
function LotteryPerGrandPrizeInfoUI:initPlayerInfo(_idx, _userInfo)
    -- 头像
    local nodeHead = self:findChild("node_frame_" .. _idx)
    local fbid = _userInfo:getFbId() 
    local sysHead = _userInfo:getSysHead() 
    local robotHead = _userInfo:getRobotHead() 
    local frameId = _userInfo:getUserFrameId()
    local headSize = cc.size(50, 50)
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbid, sysHead, frameId, robotHead, headSize)
    nodeHead:addChild(nodeAvatar)

    -- 等级
    local level = _userInfo:getUserLevel() 
    local lbLevel = self:findChild("lb_level_" .. _idx)
    lbLevel:setString("LV " .. level)

    -- 名字
    local name = _userInfo:getUserName() 
    local lbName = self:findChild("lb_name_" .. _idx)
    local layerName = self:findChild("layout_name_" .. _idx)
    name = util_getFormatFixSubStr(name, "**")
    lbName:setString(name)
    util_wordSwing(lbName, 1, layerName, 2, 30, 2)
end

-- 金币
function LotteryPerGrandPrizeInfoUI:initCoinsUI()
    local coins = self.m_data:getLastPerGrandPrize()
    local lbCoins = self:findChild("lb_coins")
    lbCoins:setString(util_formatCoins(coins, 20))
    util_scaleCoinLabGameLayerFromBgWidth(lbCoins, 670, 1)
    util_alignCenter(
        {
            {node = self:findChild("sp_coins")},
            {node = lbCoins, alignX = 5, alignY = -3}
        }
    )
end

return LotteryPerGrandPrizeInfoUI