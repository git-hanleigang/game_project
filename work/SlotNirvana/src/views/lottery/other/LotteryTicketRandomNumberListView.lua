--[[
Author: dinghansheng dinghansheng@luckxcyy.com
Date: 2022-06-10 15:24:17
LastEditors: dinghansheng dinghansheng@luckxcyy.com
LastEditTime: 2022-06-10 15:24:21
FilePath: /SlotNirvana/src/views/lottery/other/LotteryTicketRandomNumberListView.lua
Description: 乐透券 一键选号展示界面
--]]
local LotteryTicketRandomNumberListView = class("LotteryTicketRandomNumberListView", BaseView)
local LotteryTicketRandomNumberTableView = util_require("views.lottery.other.LotteryTicketRandomNumberTableView")
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")

function LotteryTicketRandomNumberListView:initUI()
    LotteryTicketRandomNumberListView.super.initUI(self)
    self.m_posYCfg = {
        55,
        -60
    }
    self:initView()
end

function LotteryTicketRandomNumberListView:getCsbName()
    return "Lottery/csd/Lottery_Ticket_list.csb"
end

function LotteryTicketRandomNumberListView:initCsbNodes()
    self.m_nodeList = self:findChild("node_list")
    self.m_spListBg1 = self:findChild("sp_list_di_1")
    self.m_nodeCell1 = self:findChild("node_cell_1")
    self.m_spListBg1:setVisible(false)

    self.m_spListBg2 = self:findChild("sp_list_di_2")
    self.m_nodeCell2 = self:findChild("node_cell_2")
    self.m_spListBg2:setVisible(false)

    self.m_spListBg3 = self:findChild("sp_list_di_3")
    self.m_tableViewList = self:findChild("ListView_ticket")
    self.m_spListBg3:setVisible(false)
end

function LotteryTicketRandomNumberListView:initView()
    -- 一键选号记录
    local listView = self:findChild("ListView_ticket")
    listView:setTouchEnabled(true)
    listView:setScrollBarEnabled(false)
    if self.m_tableView == nil then
        local size = listView:getContentSize()
        local param = {
            tableSize = size,
            parentPanel = listView,
            directionType = 2
        }
        self.m_tableView = LotteryTicketRandomNumberTableView.new(param)
        listView:addChild(self.m_tableView)
    end
end

-- 根据获得的选号数据个数用来显示当前背景
function LotteryTicketRandomNumberListView:updateListBg(_randomNumber, _randomList)
    if not _randomNumber then
        -- 全部隐藏
        self.m_nodeList:setVisible(false)
        return
    end
    self:runCsbAction("act", false)
    self.m_nodeList:setVisible(true)
    if _randomNumber == 1 then
        self.m_spListBg1:setVisible(true)
        self:initRandomNumberCell(self.m_nodeCell1, _randomList)
    elseif _randomNumber == 2 then
        self.m_spListBg2:setVisible(true)
        self:initRandomNumberCell(self.m_nodeCell2, _randomList)
    elseif _randomNumber >= 3 then
        self.m_spListBg3:setVisible(true)
        self:updateRandomList(_randomList)
    end
end

-- 更新个人选号记录
function LotteryTicketRandomNumberListView:updateRandomList(_data)
    if self.m_tableView and table.nums(_data) > 0 then
        self.m_tableView:setTouchEnabled(false)
        self.m_tableView:reload(_data)
        local listLength = table.nums(_data)
        local actionList = {}

        actionList[#actionList + 1] = cc.DelayTime:create(0.5)

        actionList[#actionList + 1] =
            cc.CallFunc:create(
            function()
                self.m_tableView:scrollTableViewByRowIndex(listLength, 1.5, 3)
            end
        )

        actionList[#actionList + 1] = cc.DelayTime:create(2.5)

        actionList[#actionList + 1] =
            cc.CallFunc:create(
            function()
                gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.CLOSE_LOTTERY_TICKET_PANEL)
            end
        )

        self.m_tableViewList:runAction(cc.Sequence:create(actionList))
    end
end

function LotteryTicketRandomNumberListView:initRandomNumberCell(_node, _randomList)
    if _node and table.nums(_randomList) > 0 then
        -- 获取当前list长度
        local listLength = table.nums(_randomList)

        for k, v in pairs(_randomList) do
            local view = util_createView("views.lottery.other.LotteryTicketRandomNumberCell")
            if view and _node then
                local posY = 0
                if listLength == 2 then
                    posY = self.m_posYCfg[k]
                end
                view:setPosition(cc.p(0, posY))
                _node:addChild(view)
                view:updateUI(v)
            end
        end
        util_performWithDelay(
            self,
            function()
                gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.CLOSE_LOTTERY_TICKET_PANEL)
            end,
            1.5
        )
    else
        gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.CLOSE_LOTTERY_TICKET_PANEL)
    end
end

return LotteryTicketRandomNumberListView
