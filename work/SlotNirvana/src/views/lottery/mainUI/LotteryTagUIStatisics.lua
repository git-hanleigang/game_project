--[[
Author: your name
Date: 2021-11-18 20:51:28
LastEditTime: 2021-11-18 20:52:06
LastEditors: your name
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/views/lottery/mainUI/LotteryTagUIStatisics.lua
--]]
local LotteryTagUIStatisics = class("LotteryTagUIStatisics", BaseView)

function LotteryTagUIStatisics:initUI()
    LotteryTagUIStatisics.super.initUI(self)
    self.m_data = G_GetMgr(G_REF.Lottery):getData()
    self.m_statisicsList = self.m_data:getStatisticsInfo() 

    self:initView()

    self:runCsbAction("idle", true)
end

function LotteryTagUIStatisics:getCsbName()
    return "Lottery/csd/MainUI/Lottery_MainUI_Statisics.csb"
end

-- 初始化节点
function LotteryTagUIStatisics:initCsbNodes()
    self.m_lbOrder = self:findChild("lb_xuhao")
end

function LotteryTagUIStatisics:initView()
    -- most
    local mostNumberStr = self.m_statisicsList[1] or ""
    local mostNumberList = string.split(mostNumberStr, "-")
    local orderMostNumberNodeList = {}
    for idx=1, #mostNumberList do
        local item = self:createBallItem(mostNumberList[idx], idx > 5)
        local parent = self:findChild("node_most_ball_" .. idx)
        parent:addChild(item)
        if idx > 5 then
            table.insert(orderMostNumberNodeList, parent)
        end
    end
    self:alginCenterNumber(orderMostNumberNodeList)

    -- least
    local leastNumberStr = self.m_statisicsList[2] or ""
    local leastNumberList = string.split(leastNumberStr, "-")
    local orderLeastNumberNodeList = {}
    for idx=1, #leastNumberList do
        local item = self:createBallItem(leastNumberList[idx], idx > 5)
        local parent = self:findChild("node_least_ball_" .. idx)
        parent:addChild(item)
        if idx > 5 then
            table.insert(orderLeastNumberNodeList, parent)
        end
    end
    self:alginCenterNumber(orderLeastNumberNodeList)
end

function LotteryTagUIStatisics:createBallItem(_number, _bRed)
    local view = util_createView("views.lottery.base.LotteryBall", {number = _number, bRed = _bRed})
    return view
end

-- 红球居中 简单写法
function LotteryTagUIStatisics:alginCenterNumber(_list)
    local space = self:findChild("node_most_ball_8"):getPositionX()
    local posXList = {{0}, {-space*0.5, space*0.5}, {-space, 0, space}}
    local orderTypeList = posXList[#_list]
    for i=1, #_list do
        local node = _list[i]
        node:setPositionX(orderTypeList[i] or 0)
    end
end

return LotteryTagUIStatisics