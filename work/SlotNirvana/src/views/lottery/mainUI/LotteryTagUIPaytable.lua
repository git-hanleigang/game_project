--[[
Author: your name
Date: 2021-11-18 20:51:28
LastEditTime: 2021-11-18 20:52:06
LastEditors: your name
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/views/lottery/mainUI/LotteryTagUIPaytable.lua
--]]
local LotteryTagUIPaytable = class("LotteryTagUIPaytable", BaseView)

function LotteryTagUIPaytable:initUI()
    LotteryTagUIPaytable.super.initUI(self)
    
    self.m_data = G_GetMgr(G_REF.Lottery):getData()
    self:initView()
end

function LotteryTagUIPaytable:getCsbName()
    return "Lottery/csd/MainUI/Lottery_MainUI_Paytable.csb"
end

-- 初始化节点
function LotteryTagUIPaytable:initCsbNodes()
    self.m_lbCoin = self:findChild("lb_coin_number")
    self.m_nodeSpine = self:findChild("node_spine")
end

function LotteryTagUIPaytable:initView()
    -- 大奖池滚动金币
    G_GetMgr(G_REF.Lottery):registerCoinAddComponent(self.m_lbCoin, 440)

    local coinsList = self.m_data:getPayTableCoinsList()
    for i=1, 8 do
        local lbCoins = self:findChild("lb_reward_" .. i)
        local coinCount = coinsList[i]
        if lbCoins and coinCount then
            lbCoins:setString(util_formatCoins(coinCount, 20))
        end
    end

    -- spinNode
    -- local spineNode = util_spineCreate("Lottery/spine/chaopiaoren/chaopiaoren", true, true)
    -- self.m_nodeSpine:addChild(spineNode)
    -- spineNode:setScale(1.2)
    -- util_spinePlay(spineNode, "idle2", true)
    self:runCsbAction("idle",true)
end

function LotteryTagUIPaytable:initSpineUI()
    LotteryTagUIPaytable.super.initSpineUI(self)

    -- spinNode
    local spineNode = util_spineCreate("Lottery/spine/chaopiaoren/chaopiaoren", true, true, 1)
    self.m_nodeSpine:addChild(spineNode)
    spineNode:setScale(1.2)
    util_spinePlay(spineNode, "idle2", true)
end

return LotteryTagUIPaytable