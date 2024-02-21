--[[
Author: your name
Date: 2021-11-19 16:36:10
LastEditTime: 2021-11-19 16:38:14
LastEditors: your name
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/views/lottery/reward/LotteryOpenRewardYours.lua
--]]
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")
local LotteryOpenRewardYours = class("LotteryOpenRewardYours", BaseView)
local LotteryOpenRewardYoursTableView = util_require("views.lottery.reward.LotteryOpenRewardYoursTableView")

function LotteryOpenRewardYours:initDatas()
    LotteryOpenRewardYours.super.initDatas(self)

    self.m_cellList = {}

    local data = G_GetMgr(G_REF.Lottery):getData()
    
    local winNumberList = data:getYoursList()
    local winCoinList = data:getYouWinCoinList()
    
    local noWinNumberList = {}
    local noWinCoinList = {}

    local numList = {}
    local coinList = {}

    self.m_numberList = {}
    self.m_winCoinList = {}

    for i,v in ipairs(winCoinList) do
        if v ~= 0 then
            table.insert( coinList, v )
            table.insert( numList, winNumberList[i] )
        else
            table.insert(noWinCoinList,v)
            table.insert(noWinNumberList,winNumberList[i])
        end
    end
    
    for i,v in ipairs(numList) do
        table.insert( self.m_numberList, v )
    end
    for i, v in ipairs(noWinNumberList) do
        table.insert(self.m_numberList, v)
    end

    for i, v in ipairs(coinList) do
        table.insert( self.m_winCoinList, v ) 
    end
    for i, v in ipairs(noWinCoinList) do
        table.insert(self.m_winCoinList, v)
    end

end

function LotteryOpenRewardYours:initUI()
    LotteryOpenRewardYours.super.initUI(self)
    
    self:initView()

    gLobalNoticManager:addObserver(self, "showWinCoinsActEvt", LotteryConfig.EVENT_NAME.PLAY_REWARD_NUMBER_ACT)
    gLobalNoticManager:addObserver(self, "stopWinCoinsActEvt", LotteryConfig.EVENT_NAME.STOP_PLAYER_REWARD_NUMBER_ACT)
end

function LotteryOpenRewardYours:getCsbName()
    return "Lottery/csd/Drawlottery/Lottery_Drawlottery_Yours.csb"
end

function LotteryOpenRewardYours:initView()
    
    -- listView个人下注记录
    local listView = self:findChild("ListView_1")
    listView:setTouchEnabled(true)
    listView:setScrollBarEnabled(false)
    listView:removeAllItems()
    local size = listView:getContentSize()
    local param = {
        tableSize = size,
        parentPanel = listView,
        directionType = 2
    }
    self.m_tableView = LotteryOpenRewardYoursTableView.new(param)
    listView:addChild(self.m_tableView)
    self.m_tableView:reload(self.m_numberList)
end

function LotteryOpenRewardYours:playShowAct(_cb)
    if self.m_bShow then
        return
    end
    self.m_bShow = true
    
    self:runCsbAction("start", false, _cb, 60)
end

-- 显示每一组号中奖动画
function LotteryOpenRewardYours:showWinCoinsActEvt(_params)
    if not tolua.isnull(self.m_tableView) then
        self.m_tableView:showNumberActEvt(_params, self.m_winCoinList)
    end
end
function LotteryOpenRewardYours:stopWinCoinsActEvt(_params)
    if not tolua.isnull(self.m_tableView) then
        self.m_tableView:stopNumberActEvt()
    end
end

return LotteryOpenRewardYours