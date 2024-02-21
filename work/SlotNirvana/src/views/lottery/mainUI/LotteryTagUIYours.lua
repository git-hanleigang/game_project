--[[
Author: your name
Date: 2021-11-18 20:23:49
LastEditTime: 2021-11-18 20:23:50
LastEditors: your name
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/views/lottery/mainUI/LotteryTagUIYours.lua
--]]

local LotteryTagUIYours = class("LotteryTagUIYours", BaseView)
local LotteryTagYoursTableView = util_require("views.lottery.mainUI.LotteryTagYoursTableView")

function LotteryTagUIYours:initUI()
    LotteryTagUIYours.super.initUI(self)

    self.m_data = G_GetMgr(G_REF.Lottery):getData()
    local tempList = self.m_data:getYoursList()
    self.m_numberList = {}
    for i=#tempList,1,-1 do
        table.insert(self.m_numberList,tempList[i]) 
    end
   
    self:initView()
    local chooseNumTag = G_GetMgr(G_REF.Lottery):getChooseNumTag()
    if chooseNumTag < #self.m_numberList then
        self:playSweepEffect()
    end
    self:runCsbAction("idle", true)
    -- schedule(self, handler(self, self.playSweepEffect), 3)
end

function LotteryTagUIYours:getCsbName()
    return "Lottery/csd/MainUI/Lottery_MainUI_Yours.csb"
end

-- 初始化节点
function LotteryTagUIYours:initCsbNodes()
    self.m_lbDate = self:findChild("lb_riqi")
    self.m_lbCoin = self:findChild("lb_coin")
    self.m_spEmpty = self:findChild("sp_empty")
end

function LotteryTagUIYours:initView()
    -- 时间
    local data = G_GetMgr(G_REF.Lottery):getData()
    -- 上线版优化成只显示开奖日期
    local endIn = "END ON " .. data:getEndDataStr()
    self.m_lbDate:setString(endIn)

    -- listView个人下注记录
    local listView = self:findChild("ListView_ticket")
    listView:setTouchEnabled(true)
    listView:setScrollBarEnabled(false)
    listView:removeAllItems()
    local size = listView:getContentSize()
    local param = {
        tableSize = size,
        parentPanel = listView,
        directionType = 2
    }
    self.m_tableView = LotteryTagYoursTableView.new(param)
    listView:addChild(self.m_tableView)
    self.m_tableView:reload(self.m_numberList)
    self.m_spEmpty:setVisible(#self.m_numberList == 0)

    -- 滚动金币
    G_GetMgr(G_REF.Lottery):registerCoinAddComponent(self.m_lbCoin, 300)
end

-- 播放特效
function LotteryTagUIYours:playSweepEffect()
    if not tolua.isnull(self.m_tableView) then
        self.m_tableView:playSweepEffect()
    end
end

return LotteryTagUIYours