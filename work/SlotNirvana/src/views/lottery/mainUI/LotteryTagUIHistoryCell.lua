--[[
Author: your name
Date: 2021-11-18 22:10:53
LastEditTime: 2021-11-18 22:11:44
LastEditors: your name
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/views/lottery/mainUI/LotteryTagUIHistoryCell.lua
--]]
local LotteryTagUIHistoryCell = class("LotteryTagUIHistoryCell", BaseView)

function LotteryTagUIHistoryCell:initUI()
    LotteryTagUIHistoryCell.super.initUI(self)

    -- 初始化球
    for idx=1, 6 do
        local parent = self:findChild("node_ball_" .. idx)
        local item = self:createShowBallItem(0, idx == 6)
        parent:addChild(item)
        item:setVisible(false)
    end
end

-- 初始化节点
function LotteryTagUIHistoryCell:initCsbNodes()
    self.m_lbTime = self:findChild("lb_time")
    self.m_lbWinnerCount = self:findChild("lb_winner")
end


function LotteryTagUIHistoryCell:getCsbName()
    return "Lottery/csd/MainUI/Lottery_MainUI_History_result.csb"
end

function LotteryTagUIHistoryCell:updateUI(_data, _idx)
    -- 时间
    local time = string.gsub(_data.period,"-",".")
    self.m_lbTime:setString(time or "")
    -- 中奖人数
    local personCount = _data.personCount or 0
    self.m_lbWinnerCount:setString(personCount)

    -- 中间号码
    local numberList = string.split(_data.hitNumber or "", "-") 
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
function LotteryTagUIHistoryCell:createShowBallItem(_number, _bRed)
    local view = util_createView("views.lottery.base.LotteryBall", {number = _number, bRed = _bRed})
    view:setName("node_show_ball")
    return view
end

return LotteryTagUIHistoryCell