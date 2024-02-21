--[[
Author: dinghansheng dinghansheng@luckxcyy.com
Date: 2022-06-10 15:23:45
LastEditors: dinghansheng dinghansheng@luckxcyy.com
LastEditTime: 2022-06-10 15:24:56
FilePath: /SlotNirvana/src/views/lottery/other/LotteryTicketRandomNumberCell.lua
Description: 乐透 一键选号 号码界面
--]]
local LotteryTicketRandomNumberCell = class("LotteryTicketRandomNumberCell",BaseView)

function LotteryTicketRandomNumberCell:initDatas(_data)
    if not _data then
        return 
    end

    self.m_data = _data

end

function LotteryTicketRandomNumberCell:getCsbName()
    return "Lottery/csd/Lottery_Ticket_list_number.csb"
end

function LotteryTicketRandomNumberCell:initUI()
    LotteryTicketRandomNumberCell.super.initUI(self)
    -- 初始化球
    for idx=1, 6 do
        local parent = self:findChild("node_ball_" .. idx)
        local item = self:createShowBallItem(0, idx == 6)
        parent:addChild(item)
        item:setVisible(false)
    end
    
end

function LotteryTicketRandomNumberCell:updateUI(_data)

    -- 一键选号号码
    local numberList = string.split(_data or "", "-") 
    for idx=1, 6 do
        local number = tonumber(numberList[idx]) or 0
        local parent = self:findChild("node_ball_" .. idx)
        local item = parent:getChildByName("node_show_ball")

        item:setVisible(number>0)
        item:updateNumberUI(number)
        item:playIdleAct()
    end
end

-- 创建 只供展示的球
function LotteryTicketRandomNumberCell:createShowBallItem(_number, _bRed)
    local view = util_createView("views.lottery.base.LotteryBall", {number = _number, bRed = _bRed})
    view:setName("node_show_ball")
    return view
end

return LotteryTicketRandomNumberCell
