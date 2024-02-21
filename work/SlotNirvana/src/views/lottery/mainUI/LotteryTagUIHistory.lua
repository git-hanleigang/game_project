--[[
Author: your name
Date: 2021-11-18 20:51:28
LastEditTime: 2021-11-18 20:52:06
LastEditors: your name
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/views/lottery/mainUI/LotteryTagUIHistory.lua
--]]
local LotteryTagUIHistory = class("LotteryTagUIHistory", BaseView)
local LotteryTagUIHistoryTableView = util_require("views.lottery.mainUI.LotteryTagUIHistoryTableView")
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")

function LotteryTagUIHistory:initUI()
    LotteryTagUIHistory.super.initUI(self)
    
    self:registerListener()
    self:initView()

    G_GetMgr(G_REF.Lottery):sendHistoryListReq()
end

function LotteryTagUIHistory:getCsbName()
    return "Lottery/csd/MainUI/Lottery_MainUI_History.csb"
end

function LotteryTagUIHistory:initView()
    
    -- 个人选号记录
    local listView = self:findChild("ListView_results")
    listView:setTouchEnabled(true)
    listView:setScrollBarEnabled(false)
    if self.m_tableView == nil then
        local size = listView:getContentSize()
        local param = {
            tableSize = size,
            parentPanel = listView,
            directionType = 2
        }
        self.m_tableView = LotteryTagUIHistoryTableView.new(param)
        listView:addChild(self.m_tableView)
    end
    
end

function LotteryTagUIHistory:onRecieveHistoryEvt()
    local list = G_GetMgr(G_REF.Lottery):getOpenNumberHistoryList()

    self.m_tableView:reload(list)
    
    self.m_spEmpty = self:findChild("sp_empty")
    self.m_spEmpty:setVisible(#list == 0)
end

function LotteryTagUIHistory:registerListener()
    gLobalNoticManager:addObserver(self, "onRecieveHistoryEvt", LotteryConfig.EVENT_NAME.RECIEVE_HISTORY_LIST)

end

return LotteryTagUIHistory