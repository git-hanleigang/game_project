--[[
Author: your name
Date: 2021-11-18 20:23:49
LastEditTime: 2021-11-18 20:23:50
LastEditors: your name
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/views/lottery/mainUI/LotteryTagUIYoursCell.lua
--]]

local LotteryYoursCell = util_require("views.lottery.base.LotteryYoursCell")
local LotteryTagUIYoursCell = class("LotteryTagUIYoursCell", LotteryYoursCell)

function LotteryTagUIYoursCell:getCsbName()
    return "Lottery/csd/MainUI/Lottery_MainUI_Yours_ticket.csb"
end

-- 初始化节点
function LotteryTagUIYoursCell:initCsbNodes()
    LotteryTagUIYoursCell.super.initCsbNodes(self)

    self.m_lbOrder = self:findChild("lb_xuhao")
end

function LotteryTagUIYoursCell:updateView()
    LotteryTagUIYoursCell.super.updateView(self)

    self.m_lbOrder:setString(self.m_order)
    util_scaleCoinLabGameLayerFromBgWidth(self.m_lbOrder, 55)
end

function LotteryTagUIYoursCell:playSweepEffect()
    self:checkCsbActionExists()
    self:runCsbAction("idle1")
    local lotteryData = G_GetMgr(G_REF.Lottery):getData()
    local list = lotteryData:getYoursList()
    G_GetMgr(G_REF.Lottery):setChooseNumTag(#list)

end

return LotteryTagUIYoursCell