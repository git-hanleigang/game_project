--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-08-11 12:07:05
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-08-11 16:33:53
FilePath: /SlotNirvana/src/views/lottery/reward/skipReward/LotteryShowBetListLayer.lua
Description: 乐透 按跳过 本期个人所选号码 弹板
--]]
local LotteryShowBetListTableView = util_require("views.lottery.reward.skipReward.LotteryShowBetListTableView")
local LotteryShowBetListLayer = class("LotteryShowBetListLayer", BaseLayer)

function LotteryShowBetListLayer:ctor()
    LotteryShowBetListLayer.super.ctor(self)

    local data = G_GetMgr(G_REF.Lottery):getData()
    self.m_hitNumber = data:getHitNumberList()
    self.m_numberList = data:getSortYoursList()

    self:setPauseSlotsEnabled(true) 
    self:setExtendData("LotteryShowBetListLayer")
    self:setLandscapeCsbName("Lottery/csd/Choose/Lottery_Reward_tanban.csb")
end

function LotteryShowBetListLayer:initView()
    -- 本期开奖号码
    self:initHitNumberUI()
    -- tableview
    self:initTableView()
end

-- 本期开奖号码
function LotteryShowBetListLayer:initHitNumberUI()
    for i=1, #self.m_hitNumber do
        local node = self:findChild("node_ball_" .. i)
        local view = self:createBallItem(self.m_hitNumber[i], i == 6)
        node:addChild(view)
    end
end
function LotteryShowBetListLayer:createBallItem(_number, _bRed)
    local view = util_createView("views.lottery.base.LotteryBall", {number = _number, bRed = _bRed})
    view:setName("node_show_ball")
    return view
end

-- tableview
function LotteryShowBetListLayer:initTableView()
    local layout = self:findChild("Layout_numbers")
    local size = layout:getContentSize()
    local param = {
        tableSize = size,
        parentPanel = layout,
        directionType = 2
    }
    self.m_tableView = LotteryShowBetListTableView.new(param)
    layout:addChild(self.m_tableView)

    self.m_tableView:reload(self.m_numberList)
end

function LotteryShowBetListLayer:clickFunc(sender)
    local name = sender:getName()
    
    if name == "btn_close" then
       self:closeUI()
    end
end

return LotteryShowBetListLayer