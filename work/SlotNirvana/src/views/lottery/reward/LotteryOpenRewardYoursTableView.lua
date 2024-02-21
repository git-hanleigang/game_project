--[[
Author: your name
Date: 2021-12-07 18:05:40
LastEditTime: 2021-12-07 18:05:42
LastEditors: your name
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/views/lottery/reward/LotteryOpenRewardYoursTableView.lua
--]]
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")
local BaseTable = util_require("base.BaseTable")
local LotteryOpenRewardYoursTableView = class("LotteryOpenRewardYoursTableView", BaseTable)

local PAGE_SHOW_COUNT = 8 -- tableView一页显示多少个

function LotteryOpenRewardYoursTableView:ctor(param)
    LotteryOpenRewardYoursTableView.super.ctor(self, param)
    self.m_showNumberList = {}
end

function LotteryOpenRewardYoursTableView:cellSizeForTable(table, idx)
    return 294, 64
end

function LotteryOpenRewardYoursTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    end
    if cell.view == nil then
        cell.view = util_createView("views.lottery.base.LotteryYoursCell")
        cell:addChild(cell.view)
        cell.view:move(294*0.5, 64*0.5) 
    end

    local data = self._viewData[idx + 1]
    cell.view:updateUI(idx + 1, data)
    cell.view:playNumberSweepAct(self.m_showNumberList)
    if self.m_bShowEf and self.m_fiterWinCoinList then
        -- 服用的cell 是否需要播放特效
        local coins = tonumber(self.m_fiterWinCoinList[idx+1]) or 0
        if coins > 0 then
            cell.view:playWinCoinAct(coins, true)
        end
    end
    
    self._cellList[idx + 1] = cell.view

    return cell
end

function LotteryOpenRewardYoursTableView:reload(_sourceData)
    -- LotteryOpenRewardYoursTableView.super.reload(self, sourceData)

    _sourceData = _sourceData or {}
    -- 加载 tableview
    self._cellList = {}

    self:setViewData(_sourceData)

    self._rowNumber = #self._viewData

    self:_initCellPos()

    self._unitTableView:reloadData()

    self:_setScrollNoticeNode()
end

-- 机器号码摇晃玩 播放中间number动画
function LotteryOpenRewardYoursTableView:showNumberActEvt(params, _fiterWinCoinList)
    self.m_fiterWinCoinList = _fiterWinCoinList

    table.insert(self.m_showNumberList, (params.number or 0))
    self:updateShowContainersUI()
    if params.idx == 5 then
        local maskNode = util_newMaskLayer(false)
        maskNode:setName("touch_mask")
        maskNode:setOpacity(0)
        self:addChild(maskNode, 99)
    elseif params.idx == 6 then
        self:showWinCoinsActEvt()
    end
end

-- 更新号码 动画
function LotteryOpenRewardYoursTableView:updateShowContainersUI()
    local container = self._unitTableView:getContainer()
    
    for k, cell in pairs(container:getChildren()) do
        if not tolua.isnull(cell.view) then
            cell.view:playNumberSweepAct(self.m_showNumberList)
        end
    end

end

-- 机器号码摇晃玩 播放中间number动画
function LotteryOpenRewardYoursTableView:showWinCoinsActEvt()
    self.m_flyEndNode = G_GetMgr(G_REF.Lottery):getBottomCoinsFlyEndNode()

    local containersSize = self._unitTableView:getContentSize()
    local tableViewSize = self._tableSize

    local winCoinListLen = self:getPage()
    local page = math.ceil(winCoinListLen / PAGE_SHOW_COUNT)

    -- local page = math.ceil(containersSize.height/tableViewSize.height)
    local delayTime = 1

    self.aniCoroutine = coroutine.create(function()
        for i=1, page do
            local offsetY = i * tableViewSize.height - containersSize.height
            self._unitTableView:setContentOffsetInDuration(cc.p(0, offsetY), delayTime)
            performWithDelay(self, function()
                self:showPageWinCoinsActEvt(i)
            end, (delayTime+0.1))
            coroutine.yield()
        end

        self.aniCoroutine = nil
        self.m_bShowEf = true
        self:removeChildByName("touch_mask")
        gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.MACHINE_OVER_NPC_AUDIO) -- 机器摇晃结束npc说话 领奖
    end)

    util_resumeCoroutine(self.aniCoroutine)
end

function LotteryOpenRewardYoursTableView:getPage()
    local lotteryData = G_GetMgr(G_REF.Lottery):getData()
    local winCoinList = lotteryData:getYouWinCoinList()

    local tempTableList = {}

    for i,v in ipairs(winCoinList) do
        if v ~= 0 then
            table.insert(tempTableList,v)
        end
    end
    local len = #tempTableList or 0
    return len
end

-- 机器号码摇晃玩 播放中间number动画 播放每一页的动画
function LotteryOpenRewardYoursTableView:showPageWinCoinsActEvt(_page)
    local showItemList = {}
    -- local container = self._unitTableView:getContainer()
    -- for k, cell in pairs(container:getChildren()) do
    --     table.insert(showItemList, cell.view)
    -- end
    for idx = 1, PAGE_SHOW_COUNT do
        local cellIdx = idx + (_page - 1) * PAGE_SHOW_COUNT
        local cellNode = self:getCellByIndex(cellIdx) 
        if tolua.isnull(cellNode) then
            break
        end

        table.insert(showItemList, cellNode.view)
    end

    if #showItemList == 0 then
        util_resumeCoroutine(self.aniCoroutine)
        return
    end

    self.flyCoroutine = coroutine.create(function()
        
        for i=1, #showItemList do
            local itemNode = showItemList[i]
            if not tolua.isnull(itemNode) then
                local order = itemNode:getCurOrder() or 0
                local coins = self.m_fiterWinCoinList[order] or 0
                if tonumber(coins) > 0 and order ~= self.m_preOrder  then
                    gLobalSoundManager:playSound("Lottery/sounds/Lottery_machine_over_yourscell_ef.mp3")
                    itemNode:playWinCoinAct(tonumber(coins))
                    self:playFlyCoinsAni(itemNode, coins)
                    self.m_preOrder = order
                    coroutine.yield()
                end
            end
        end

        self.flyCoroutine = nil
        util_resumeCoroutine(self.aniCoroutine)

    end)

    util_resumeCoroutine(self.flyCoroutine)
end

-- 中间号码飞金币粒子
function LotteryOpenRewardYoursTableView:playFlyCoinsAni(_itemNode, _coins)
    local _refNode = _itemNode
    local parent = gLobalViewManager:getViewLayer() or display.getRunningScene()
    local particle = util_createView("views.lottery.reward.LotteryOpenRewardFlyParticle")
    parent:addChild(particle, 99999)
    local startPosW = _refNode:convertToWorldSpace(cc.p(0,0))
    local startPosL = parent:convertToNodeSpace(startPosW)
    particle:move(startPosL)

    local endNode = self._unitTableView
    if not tolua.isnull(self.m_flyEndNode) then
        endNode = self.m_flyEndNode
    end
    local endPosW = endNode:convertToWorldSpace(cc.p(0,0))
    local endPosL = parent:convertToNodeSpace(endPosW)
    local moveTo = cc.MoveTo:create(1, endPosL)
    local endCallFunc = cc.CallFunc:create(function()
                            gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.OPEN_ADD_COINS_UI, _coins) --开奖中奖cell金币粒子飞完增加底部栏金币数
                            util_resumeCoroutine(self.flyCoroutine)
                        end)
    local remove = cc.RemoveSelf:create()
    local seq = cc.Sequence:create(moveTo, endCallFunc, remove)
    particle:runAction(seq)
end

-- 停止动画
function LotteryOpenRewardYoursTableView:stopNumberActEvt()
    self.m_bStop = true
    if (self.flyCoroutine and coroutine.status(self.flyCoroutine) == "running") or 
        self.aniCoroutine and coroutine.status(self.aniCoroutine) == "running" then
        coroutine.yield()
    end
end

return LotteryOpenRewardYoursTableView 
