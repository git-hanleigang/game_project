--[[
    author:JohnnyFred
    time:2019-11-05 10:23:40
]]
local BaseRankUI = class("BaseRankUI", util_require("base.BaseView"))
local LOAD_MAX_COUNT = 50
function BaseRankUI:initView()
    self.rankTitle = self:findChild("rankTitle")
    self.titleReward = self:findChild("QuestLink_rank1_prize_13")
    self.titleSeason = self:findChild("Sprite_17")
    self.firstNode = self:findChild("1st")
    self.secondNode = self:findChild("2nd")
    self.thirdNode = self:findChild("3rd")
    self:startLeftTimer()
    self:clearRankUp()
    self:addClickSound({"btn_x"}, SOUND_ENUM.SOUND_HIDE_VIEW)
end

function BaseRankUI:initTitleUI()
    local nodeTitle = self:findChild("Node_title")
    if not nodeTitle then
        nodeTitle = self:findChild("node_title")
    end
    local titleUI = util_createView(self:getTitleLuaName(), handler(self, self.close))
    self.titleUI = titleUI
    nodeTitle:addChild(titleUI)
end

function BaseRankUI:setInitFlag(flag)
    self.initFlag = flag
end

function BaseRankUI:clearRankUp()
    local gameData = self:getGameData()
    if gameData ~= nil then
        gameData:setRankUp(0)
    end
end

--固定显示的父节点
function BaseRankUI:getFixedParent()
    return self.m_userNode
end

function BaseRankUI:initTableView()
    self.m_allRankCellList = {}
    local selfTopCellOffsetX, selfTopCellOffsetY = self:getSelfTopCellOffset()
    local selfBottomCellOffsetX, selfBottomCellOffsetY = self:getSelfBottomCellOffset()
    local size = self.m_userListView:getContentSize()
    --在tableview最上方，创建一个RankCell
    local topCellLayout = ccui.Layout:create()
    self:getFixedParent():addChild(topCellLayout)
    topCellLayout:setClippingEnabled(true)
    topCellLayout:setContentSize({width = self:getCellWidth(), height = self:getCellHeight()})
    topCellLayout:setPosition(-size.width / 2 + selfTopCellOffsetX, size.height / 2 - self:getCellHeight() + selfTopCellOffsetY)
    local topCell = util_createView(self:getCellLuaName(1), self)
    topCellLayout:addChild(topCell)
    topCell:setVisible(false)
    self.m_tabViewTopCell = topCell
    --在tableview最下方，创建一个RankCell
    local bottomCellLayout = ccui.Layout:create()
    self:getFixedParent():addChild(bottomCellLayout)
    bottomCellLayout:setClippingEnabled(true)
    bottomCellLayout:setContentSize({width = self:getCellWidth(), height = self:getCellHeight()})
    bottomCellLayout:setPosition(-size.width / 2 + selfBottomCellOffsetX, -size.height / 2 + selfBottomCellOffsetY)
    local boomCell = util_createView(self:getCellLuaName(1), self)
    bottomCellLayout:addChild(boomCell)
    boomCell:setVisible(false)
    self.m_tabViewBoomCell = boomCell
end

function BaseRankUI:createUserEmptyBounceItemUI()
    if self.m_userListView ~= nil then
        if not self.emptyCell then
            self.emptyCell = ccui.Layout:create()
            self.emptyCell:setContentSize({width = self:getCellWidth(), height = self:getCellHeight()})
            self.m_userListView:pushBackCustomItem(self.emptyCell)
        end
    end
end

function BaseRankUI:updateRankView(forceRefesh)
    self.m_tabViewTopCell:setVisible(false)
    self.m_tabViewBoomCell:setVisible(false)

    local data = nil
    local rankCfg = self:getRankCfg()
    if rankCfg ~= nil then
        --tab类型1：QuestRankUser  2：QuestReward  3：QuestSeason
        data = rankCfg:getRankConfig(self.m_curIndex)
    end
    self.m_userRankData = data

    if self.m_curIndex == 1 then
        self:createTopThreeUI(data)
        if data ~= nil then
            self:reloadUserListData(data, forceRefesh)
        else
            self:updateTopBottomUI()
        end
    elseif self.m_curIndex == 2 then
        if data ~= nil then
            self:reloadRewardListData(data, forceRefesh)
        end
    end
end

--点击tab按钮切换标题
function BaseRankUI:updateBaseTitle(index)
    if self.rankTitle ~= nil then
        self.rankTitle:setVisible(index ~= 1)
    end
    if self.titleReward ~= nil then
        self.titleReward:setVisible(index == 2)
    end
    if self.titleSeason ~= nil then
        self.titleSeason:setVisible(index == 3)
    end
    self:setTopThreeUIVisible(index == 1)

    -- 切换底图
    for i = 1, #self.m_tabSpList do
        local tab_sp = self.m_tabSpList[i]
        if i == index then
            tab_sp:setVisible(true)
        else
            tab_sp:setVisible(false)
        end
    end
end
--点击tab按钮
function BaseRankUI:onTabClick(index, refreshRankFlag)
    if self.m_curIndex == index then
        return
    end

    self:updateBaseTitle(index)

    if index == 1 then
        self.m_userNode:setVisible(true)
        self.m_rewardNode:setVisible(false)
    elseif index == 2 then
        self.m_userNode:setVisible(false)
        self.m_rewardNode:setVisible(true)
    end

    self.m_curIndex = index
    self:updateView(refreshRankFlag)
end

function BaseRankUI:updateTopBottomUI()
    local userListView = self.m_userListView
    local size = userListView:getSize()
    local height = size.height
    local innerSize = userListView:getInnerContainerSize()
    local innerHeight = innerSize.height
    local pos = userListView:getInnerContainerPosition()
    local posY = pos.y
    local rankConfig = self:getRankCfg()
    if rankConfig ~= nil then
        local myRank = rankConfig:getSelfRankIndex()
        if myRank > 3 then
            local myRankPosY = (myRank - 1 - 3) * self:getCellHeight() - innerHeight
            self.m_tabViewTopCell:setVisible((posY - height) > myRankPosY)
            self.m_tabViewBoomCell:setVisible(posY < (myRankPosY + self:getCellHeight()))
        else
            self.m_tabViewTopCell:setVisible(false)
            self.m_tabViewBoomCell:setVisible(true)
        end
    end

    self:updateCellView()
end

--刷新玩家排行
function BaseRankUI:reloadUserListData(data, forceRefesh)
    if data == nil or #data <= 0 then
        return
    end

    -- test
    -- for i = 1, 40 do
    --     data[i] = clone(data[1])
    --     data[i].p_rank = i
    -- end
    if forceRefesh then
        --清空列表
        self.m_userList = {}
        local userListView = self.m_userListView
        -- userListView:removeAllItems()

        local loadItems = function(data, i)
            if data[i] then
                local cellItem = userListView:getItem(i - 4)
                if not cellItem then
                    cellItem = ccui.Layout:create()
                    cellItem:setContentSize({width = self:getCellWidth(), height = self:getCellHeight()})
                    userListView:pushBackCustomItem(cellItem)
                end

                local userItem = cellItem:getChildByName("userItem")
                if not userItem then
                    userItem = util_createView(self:getCellLuaName(1), self)
                    userItem:setName("userItem")
                    userItem:setPosition(0, 0)
                    cellItem:addChild(userItem)
                    table.insert(self.m_userList, userItem)
                end
                cellItem:setTag(i)
                userItem:updateView(data[i], i)
            end
        end

        local onLoaded = function(dataCount)
            local rankConfig = self:getRankCfg()
            if rankConfig ~= nil then
                local myRank = rankConfig:getSelfRankIndex()
                if myRank and myRank < 4 or myRank > dataCount then
                    self:createUserEmptyBounceItemUI()
                end
            end
            self:updateTopBottomUI()
            self:onListScroll()
        end

        local cur_idx = 4
        local counts = 6
        local dataCount = #data
        if dataCount > LOAD_MAX_COUNT - 3 then
            dataCount = LOAD_MAX_COUNT - 3
        end
        if dataCount >= cur_idx then
            if dataCount >= cur_idx + counts then
                for i = 4, cur_idx + counts do
                    loadItems(data, i)
                    cur_idx = i
                end
                local loadFrames
                loadFrames =
                    util_schedule(
                    userListView,
                    function()
                        local bl_over = false
                        if cur_idx + counts >= dataCount then
                            bl_over = true
                            counts = dataCount - cur_idx
                        end
                        for i = cur_idx, cur_idx + counts do
                            loadItems(data, i)
                            cur_idx = i
                        end
                        if bl_over then
                            userListView:stopAction(loadFrames)
                            onLoaded(dataCount)
                        end
                    end,
                    1 / 60
                )
            else
                for i = 4, dataCount do
                    loadItems(data, i)
                    cur_idx = i
                end
                onLoaded(dataCount)
             end
        end

        --userListView:setEnabled(dataCount >= self:getScrollEnabledCount())
        userListView:setTouchEnabled(dataCount >= self:getScrollEnabledCount())
    end
    self:onListScroll()
end

-- 更新cell显示
function BaseRankUI:updateCellView()
    local userListView = self.m_userListView
    local size = userListView:getSize()
    local innerSize = userListView:getInnerContainerSize()
    local innerHeight = innerSize.height
    local cellHeight = self:getCellHeight()
    local items = userListView:getItems()
    local _innerPos = userListView:getInnerContainerPosition()
    local _innerPosY = _innerPos.y

    if self.m_innerPos ~= nil then
        local _oldIdx = math.floor(math.abs(self.m_innerPos.y) / cellHeight)
        local _newIdx = math.floor(math.abs(_innerPosY) / cellHeight)
        if _oldIdx == _newIdx then
            return
        end
    end

    self.m_innerPos = _innerPos

    local _topIdx = math.floor((innerHeight - size.height + _innerPosY) / cellHeight)
    local _bottomIdx = math.ceil((innerHeight + _innerPosY) / cellHeight)

    for i = 1, #items do
        local _item = items[i]
        if i < _topIdx or i > _bottomIdx then
            _item:setVisible(false)
        else
            _item:setVisible(true)
        end
    end
end

--刷新奖励排行
function BaseRankUI:reloadRewardListData(data, forceRefesh)
    if data == nil or #data <= 0 then
        return
    end

    if forceRefesh then
        local rewardList = self.m_rewardList
        if rewardList == nil or #rewardList == 0 then
            local rewardListView = self.m_rewardListView
            rewardListView:removeAllItems()
            for k, v in ipairs(data) do
                local cell = util_createView(self:getCellLuaName(2), v, k)
                local layout = ccui.Layout:create()
                layout:setContentSize({width = self:getCellWidth(), height = self:getCellHeight()})
                layout:addChild(cell)
                cell:setPosition(0, 0)
                rewardListView:pushBackCustomItem(layout)
                table.insert(rewardList, cell)
            end
        end
    end
end

--显示规则
function BaseRankUI:showRankHelpUI()
    local uiView = util_createFindView(self:getRankHelpName())
    if uiView ~= nil then
        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_POPUI)
    end
end

function BaseRankUI:createTopThreeUI(dataList)
    local firstNode = self.firstNode
    local secondNode = self.secondNode
    local thirdNode = self.thirdNode
    firstNode:removeAllChildren()
    secondNode:removeAllChildren()
    thirdNode:removeAllChildren()
    for i = 1, 3 do
        local data = nil
        if dataList ~= nil then
            data = dataList[i] or {p_rank = i, p_name = "Pending", p_points = 0}
        else
            data = {p_rank = i, p_name = "Pending", p_points = 0}
        end
        local cellUI = util_createView(self:getTopCellLuaName(), data)
        if i == 1 then
            firstNode:addChild(cellUI)
        elseif i == 2 then
            secondNode:addChild(cellUI)
        elseif i == 3 then
            thirdNode:addChild(cellUI)
        end
    end
end

function BaseRankUI:setTopThreeUIVisible(flag)
    self.firstNode:setVisible(flag)
    self.secondNode:setVisible(flag)
    self.thirdNode:setVisible(flag)
end

function BaseRankUI:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(target, param)
            if param and param.refName == self:getActivityRefName() then
                if not tolua.isnull(self) and self.updateView then
                    self:updateView(true)
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH
    )
end

function BaseRankUI:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function BaseRankUI:clickFunc(sender)
    if self.isClose then
        return
    end

    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_tab_1" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:onTabClick(1, true)
    elseif name == "btn_tab_2" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:onTabClick(2, true)
    end
end

function BaseRankUI:close()
    if self.isClose then
        return
    end
    self.isClose = true
    self:commonHide(
        self:findChild("root"),
        function()
            if not tolua.isnull(self) then
                self:removeFromParent()
            end
        end
    )
end

------------------------------------------子类重写---------------------------------------
function BaseRankUI:initUI()
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 or globalData.slotRunData.isPortrait == true then
        isAutoScale = false
    end

    self:createCsbNode(self:getCsbName(), isAutoScale)

    -- 打开界面请求，返回结果后刷新界面
    self:sendRankRequestAction()

    self:initTitleUI()

    self:commonShow(
        self:findChild("root"),
        function()
            if not self.isClose then
                self:setInitFlag(true)
                self:runCsbAction("idle", true)
            end
        end,
        60
    )

    --记录滑动后，序号
    self.m_touchEndIndex = 0

    self.m_curIndex = -1
    self.m_selfRankIndex = -1
    self.m_rankData = {}

    self.m_tabList = {}
    self.m_tabSpList = {}
    for i = 1, 2 do
        local tab_btn = self:findChild("btn_tab_" .. i)
        self.m_tabList[#self.m_tabList + 1] = tab_btn

        local sp_qieye = self:findChild("sp_qieye" .. i)
        self.m_tabSpList[#self.m_tabSpList + 1] = sp_qieye
        self:addClick(tab_btn)
    end

    self.m_lb_time = self:findChild("BitmapFontLabel_2")
    if not self.m_lb_time then
        self.m_lb_time = self:findChild("lb_time")
    end

    self:initView()

    self.m_rewardNode = self:findChild("rewardNode")
    self.m_rewardListView = self:findChild("rewardListView")
    self.m_rewardListView:setScrollBarEnabled(false)
    self.m_rewardList = {}

    self.m_userNode = self:findChild("userNode")
    local userListView = self:findChild("userListView")
    self.m_userListView = userListView
    self.m_userListView:setScrollBarEnabled(false)
    self.m_userList = {}
    self.m_innerPos = userListView:getInnerContainerPosition()
    --self.m_userListView:onScroll(handler(self, self.onListScroll))
    local preUserListViewInnerPosY = userListView:getInnerContainerPosition().y
    self:scheduleUpdateWithPriorityLua(
        function(dt)
            local curUserListViewInnerPosY = userListView:getInnerContainerPosition().y
            if preUserListViewInnerPosY ~= curUserListViewInnerPosY then
                preUserListViewInnerPosY = curUserListViewInnerPosY
                self:updateTopBottomUI()
                self:onListScroll()
            end
        end,
        0
    )

    self:initTableView()
    self:onTabClick(1, true)
    self:setExtendData("BaseRankUI")
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function BaseRankUI:onListScroll()

    local offY = self.m_userListView:getInnerContainerPosition().y
    local a = self.m_userListView:getScrolledPercentVertical()
    local flag = false
    if a > 0 then
        if not self.m_offY then
            self.m_offY = math.abs(offY)
        end
        flag = self:isMyRank(math.abs(offY))
    else
        local count = 3 + self:getLayerCount()
        if self.m_userRankData then
            for i=1,count do
                local data = self.m_userRankData[i]
                if data and data.p_udid == globalData.userRunData.userUdid then
                    flag = true
                    break
                end
            end
        end
        
    end
    self.m_tabViewTopCell:setVisible(false)
    if not flag then
        self.m_tabViewBoomCell:setVisible(true)
    else
        self.m_tabViewBoomCell:setVisible(false)
    end
end

function BaseRankUI:getLayerCount()
    local high = self:getCellHeight()
    local ht = self.m_userListView:getContentSize().height
    local p_hig = high + 3
    local count = math.ceil(ht/p_hig)
    return count
end

--增加一个自己是否在页面的判断
function BaseRankUI:isMyRank(_offY)
    local flag = false
    if self.m_userRankData and #self.m_userRankData > 0 then
        for i=1,3 do
             local data = self.m_userRankData[i]
             if data and data.p_udid == globalData.userRunData.userUdid then
                flag = true
                break
             end
         end 
         if not flag then
            local high = self:getCellHeight()
            local a = _offY/high
            local distance = self.m_offY - _offY
            local idx = distance/high
            local idx2 = math.floor(idx)
            local idx1 = idx - idx2
            if idx1 > 0.65 then
                idx2 = idx2 + 1
            end
            local count = self:getLayerCount()
            local index = count + idx2
            for i=1,count do
                local a = self.m_userRankData[index+i]
                if a and a.p_udid == globalData.userRunData.userUdid then
                    flag = true
                    break
                end
            end
         end
    end
    return flag
end

function BaseRankUI:sendRankRequestAction()
end

function BaseRankUI:getActivityRefName()
    assert(false, "------ 子类必须重写 ------")
end

function BaseRankUI:getRankCfg()
    return nil
end

function BaseRankUI:getGameData()
    return nil
end

function BaseRankUI:getCsbName()
    return ""
end

function BaseRankUI:getTitleCsbName()
    return ""
end

function BaseRankUI:getCellLuaName(index)
    return ""
end

function BaseRankUI:getTopCellLuaName()
    return ""
end

function BaseRankUI:getRankHelpName()
    return ""
end

function BaseRankUI:getCellWidth()
    return 0
end

function BaseRankUI:getCellHeight()
    return 0
end

function BaseRankUI:getSelfTopCellOffset()
    return 0, 0
end

function BaseRankUI:getSelfBottomCellOffset()
    return 0, 0
end

function BaseRankUI:getScrollEnabledCount()
    return 8
end

-- 时间字符串可显示长度
function BaseRankUI:getTimeLength()
    return nil
end
function BaseRankUI:getTimeScale()
    return 1, 1
end

function BaseRankUI:startLeftTimer()
    self:stopLeftTimerAction()
    local function update()
        local gameData = self:getGameData()
        if gameData ~= nil and gameData:isRunning() then
            local strLeftTime = util_daysdemaining(gameData:getExpireAt(), true)
            self.m_lb_time:setString(strLeftTime)
            local timeLen = self:getTimeLength()
            if timeLen and timeLen > 0 then
                local scalex, scaley = self:getTimeScale()
                self:updateLabelSize({label = self.m_lb_time, sx = scalex, sy = scaley}, timeLen)
            end
        else
            self:stopLeftTimerAction()
            self:close()
        end
    end
    self.leftTimerAction = schedule(self, update, 1)
    update()
end

function BaseRankUI:stopLeftTimerAction()
    if self.leftTimerAction ~= nil then
        self:stopAction(self.leftTimerAction)
        self.leftTimerAction = nil
    end
end

--返回数据后，刷新界面
function BaseRankUI:updateView(forceRefesh)
    local rankConfig = self:getRankCfg()
    if not rankConfig then
        return
    end
    local myRankData = rankConfig:getMyRankConfig()
    if myRankData then
        self.m_tabViewTopCell:updateView(myRankData)
        self.m_tabViewBoomCell:updateView(myRankData)
    end
    --刷新排行榜
    self:updateRankView(forceRefesh)
end
------------------------------------------子类重写---------------------------------------

return BaseRankUI
