-- 排行榜主界面基类

local BaseRankHelpUI = require("baseRank.BaseRankHelpUI")
local BaseRankTitleUI = require("baseRank.BaseRankTitleUI")
local BaseRankTimer = require("baseRank.BaseRankTimer")
local BaseRankTopThreeCellUI = require("baseRank.BaseRankTopThreeCellUI")
-- local BaseRankUserCell = require("baseRank.BaseRankUserCell")
-- local BaseRankRewardCell = require("baseRank.BaseRankRewardCell")

local BaseRankUI = class("BaseRankUI", BaseLayer)

-- 排行榜显示数据上限
local LOAD_MAX_COUNT = 50

local BTN_TYPE = {
    RANK = 1,
    REWARD = 2
}

function BaseRankUI:ctor()
    BaseRankUI.super.ctor(self)

    self.ActionType = "Common"
    -- 设置横屏csb (如果是竖版不要重写getCsbName，主要兼容旧版)
    local csb_name = self:getCsbName()
    if csb_name then
        self:setLandscapeCsbName(csb_name)
    end
    self:setExtendData("BaseRankUI")

    self.bl_merge = false

    self:addClickSound({"btn_rank", "btn_reward"}, SOUND_ENUM.MUSIC_BTN_CLICK)
end

function BaseRankUI:initCsbNodes()
    self.node_title = self:findChild("node_title") -- title控件挂点
    assert(self.node_title, "node_title 挂点丢失")

    self.node_rankTime = self:findChild("node_rankTime") -- 倒计时控件挂点
    assert(self.node_rankTime, "node_rankTime 挂点丢失")

    self.userNode = self:findChild("userNode") -- 玩家列表容器父节点
    assert(self.userNode, "userNode 挂点丢失")

    self.rewardNode = self:findChild("rewardNode") -- 奖励列表容器父节点
    assert(self.rewardNode, "rewardNode 挂点丢失")

    self.sp_btnRank = self:findChild("sp_btnRank") -- 名次列表按钮
    assert(self.sp_btnRank, "sp_btnRank 挂点丢失")

    self.node_empty = self:findChild("node_empty") -- 空界面显示文字挂点

    self.sp_btnReward = self:findChild("sp_btnReward") -- 奖励列表按钮
    assert(self.sp_btnReward, "sp_btnReward 挂点丢失")

    local userList = self:findChild("userList") -- 玩家列表容器
    assert(userList, "userList 挂点丢失")
    if userList then
        -- self.userList:setBounceEnabled(true)
        -- self.userList:setScrollBarEnabled(false)
        -- self.userList:onScroll(handler(self, self.onListScroll))
        local param = {cellSize = self:getUserCellSize(), tableSize = userList:getContentSize(), parentPanel = userList, directionType = 2}
        self.userList = self:getUserTableView():create(param)
        self.userList:setCellUiInfo(self:getUserCellLua(), self:getUserCellPath())
        userList:addChild(self.userList)
    end

    local rewardList = self:findChild("rewardList") -- 奖励列表容器
    if rewardList then
        -- self.rewardList:setBounceEnabled(true)
        -- self.rewardList:setScrollBarEnabled(false)
        local param = {cellSize = self:getRewardCellSize(), tableSize = rewardList:getContentSize(), parentPanel = rewardList, directionType = 2}
        self.rewardList = self:getRewardTableView():create(param)
        self.rewardList:setCellUiInfo(self:getRewardCellLua(), self:getRewardCellPath(), {maxLen = self:getCoinMaxLen(), scale = self:getRewardScale()})
        rewardList:addChild(self.rewardList)
    end
    -- 记录列表长度 显示自己排行榜信息用
    self.userLst_size = self.userList:getContentSize()

    -- 前三名UI 挂点
    self.m_topThreeNodeList = {}
    self.m_topThreeNodeList[1] = self:findChild("node_1st")
    self.m_topThreeNodeList[2] = self:findChild("node_2nd")
    self.m_topThreeNodeList[3] = self:findChild("node_3rd")
end

function BaseRankUI:getUserTableView()
    -- 返回默认，上层可重写
    return require("baseRank.BaseRankTable")
end

function BaseRankUI:getRewardTableView()
    -- 返回默认，上层可重写
    return require("baseRank.BaseRankTable")
end

function BaseRankUI:getUserCellLua()
    return "baseRank.BaseRankUserCell"
end

function BaseRankUI:getRewardCellLua()
    return "baseRank.BaseRankRewardCell"
end

function BaseRankUI:initUI()
    release_print("CRASH[MQ], BaseRankUI:initUI 1")
    BaseRankUI.super.initUI(self)
    release_print("CRASH[MQ], BaseRankUI:initUI 2")
    -- 打开界面请求，返回结果后刷新界面
    -- self:sendRankRequestAction()

    self:clearRankUp()

    self:initTitleUI()
    self:initTimer()

    self:showList(BTN_TYPE.RANK)
    util_setCascadeOpacityEnabledRescursion(self, true)
    release_print("CRASH[MQ], BaseRankUI:initUI 3")
end

-- function BaseRankUI:initMyRankCell()
--     if self.myRankCell then
--         return
--     end

--     local myRankCell = BaseRankUserCell_Self:create()
--     if myRankCell then
--         local csb_res = self:getUserCellPath()
--         myRankCell:initUI(csb_res)
--         local rank_data = self:getRankData()
--         local myRank_data = rank_data.p_myRank
--         if self.bl_merge then
--             local reward_data = self:getRewardsData(myRank_data.p_rank)
--             if reward_data then
--                 local item_path = self:getRewardItemPath()
--                 myRankCell:setRewardItemPath(item_path)
--                 myRankCell:showRewards(reward_data)
--             end
--         end
--         myRankCell:updateView(myRank_data)
--         self.userNode:addChild(myRankCell)
--         self.myRankCell = myRankCell
--     end
-- end

-- 创建一个空的条目 给玩家自己排名占位
-- function BaseRankUI:initEmptyRankCell()
--     local rank_data = self:getRankData()
--     local list_data = rank_data:getRankConfig(BTN_TYPE.RANK)
--     if not list_data or table.nums(list_data) <= 0 then
--         return
--     end

--     local data_num = table.nums(list_data)
--     if data_num > LOAD_MAX_COUNT then
--         data_num = LOAD_MAX_COUNT
--     end
--     local last_data = list_data[data_num]

--     local myIdx = rank_data:getSelfRankIndex()
--     local item = self:initRankCell(last_data, data_num + 1, myIdx)
--     if item and item.cell then
--         item.cell:setVisible(false)
--     end
--     return item
-- end

-- 初始化名次条目
-- function BaseRankUI:initRankCell(cell_data, idx, myIdx)
--     local cell = BaseRankUserCell:create()
--     if not cell then
--         printError("BaseRankUI 创建排行榜名次条目失败")
--         return
--     end

--     local csb_res = self:getUserCellPath()
--     if not csb_res then
--         return
--     end
--     local ref_name = self:getRefName()

--     cell:initUI(csb_res, ref_name)
--     if self.bl_merge then
--         local reward_data = self:getRewardsData(cell_data.p_rank)
--         if reward_data then
--             local item_path = self:getRewardItemPath()
--             cell:setRewardItemPath(item_path)
--             cell:showRewards(reward_data)
--         end
--     end
--     cell:updateView(cell_data, idx, myIdx)

--     local item = ccui.Layout:create()
--     if not item then
--         printError("BaseRankUI 创建排行榜名次条目失败2")
--         return
--     end
--     item:addChild(cell)
--     local cell_size = cell:getContentSize()
--     item:setContentSize(cell_size)
--     item:setAnchorPoint(cc.p(0.5, 0.5))
--     cell:setPosition(cc.p(cell_size.width / 2, cell_size.height / 2))
--     item.cell = cell

--     return item
-- end

-- 初始化奖励条目
-- function BaseRankUI:initRewardCell(cell_data, idx)
--     local cell = BaseRankRewardCell:create()
--     if not cell then
--         printError("BaseRankUI 创建排行榜奖励条目失败")
--         return
--     end

--     local csb_res = self:getRewardCellPath()
--     if not csb_res then
--         return
--     end
--     cell:initUI(csb_res)
--     local coin_len = self:getCoinMaxLen()
--     local rewardScale = self:getRewardScale()
--     if rewardScale ~= nil then
--         cell:setRewardScale(rewardScale)
--     end
--     cell:setCoinMaxLen(coin_len)
--     cell:updateView(cell_data, idx)

--     local item = ccui.Layout:create()
--     if not item then
--         printError("BaseRankUI 创建排行榜奖励条目失败2")
--         return
--     end
--     item:addChild(cell)
--     local cell_size = cell:getContentSize()
--     item:setContentSize(cell_size)
--     cell:setPosition(cc.p(cell_size.width / 2, cell_size.height / 2))
--     item.cell = cell

--     return item
-- end

--显示规则
function BaseRankUI:showRankHelpUI()
    local csb_res = self:getRankHelpPath()
    if not csb_res then
        return
    end
    local rankHelpUI = BaseRankHelpUI:create(csb_res)
    if rankHelpUI then
        rankHelpUI:initUI()
        self:addChild(rankHelpUI)
        gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    end
end

function BaseRankUI:initTitleUI()
    local title = BaseRankTitleUI:create()
    if not title then
        return
    end
    local csb_res = self:getRankTitlePath()
    if not csb_res then
        return
    end
    local act_ref = self:getRefName()
    title:initUI(act_ref, csb_res)
    self.node_title:addChild(title)
end

function BaseRankUI:initTimer()
    local csb_res = self:getRankTimerPath()
    if not csb_res then
        return
    end
    local timerUI = BaseRankTimer:create()
    if timerUI then
        timerUI:initUI(csb_res, self:getActData())
        self.node_rankTime:addChild(timerUI)
    end
end

function BaseRankUI:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function BaseRankUI:clearRankUp()
    local act_data = self:getActData()
    if act_data then
        act_data:setRankUp(0)
    end
end

-- 显示列表
function BaseRankUI:showList(_type)
    if self.m_curType == _type then
        return
    end
    self.m_curType = _type
    self.userNode:setVisible(_type == BTN_TYPE.RANK)
    self.rewardNode:setVisible(_type == BTN_TYPE.REWARD)
    self.sp_btnRank:setVisible(_type == BTN_TYPE.RANK)
    self.sp_btnReward:setVisible(_type == BTN_TYPE.REWARD)

    if self.m_topThreeNodeList and #self.m_topThreeNodeList > 0 then
        for idx, TopCellNode in ipairs(self.m_topThreeNodeList) do
            if TopCellNode then
                TopCellNode:setVisible(_type == BTN_TYPE.RANK)
            end
        end
    end
    self:updateView()
end

--刷新界面
function BaseRankUI:updateView(isRefresh)
    if self.m_curType == BTN_TYPE.RANK then
        self:refreshRankList(isRefresh)
    end

    if self.m_curType == BTN_TYPE.REWARD then
        self:refreshRewardList(isRefresh)
    end
end

-- 刷新玩家信息
--

-- function BaseRankUI:onListScroll()
--     self:updateMyRankOnScroll()
-- end

-- function BaseRankUI:updateMyRankOnScroll()
--     local rank_data = self:getRankData()
--     if not rank_data then
--         return
--     end

--     if not self.myRankCell then
--         return
--     end
--     local topCell = self.userList:getTopmostItemInCurrentView()
--     local bottomCell = self.userList:getBottommostItemInCurrentView()

--     local myIdx = rank_data:getSelfRankIndex()
--     if myIdx <= 0 then
--         myIdx = 999
--     end

--     local curY
--     local cur_item = self.userList:getItem(myIdx - 1)
--     if cur_item then
--         if cur_item.cell then
--             cur_item.cell:setOpacity(0)
--         end

--         local item_world = cur_item:getWorldPosition()
--         local curPos = self.userNode:convertToNodeSpace(item_world)
--         -- 显示在榜单中时 跟随排行榜一起滑动
--         -- 经过两次修正 限定边界值
--         local topY, bottomY = self:getRankEdge()
--         curY = math.max(math.min(curPos.y, topY), bottomY)
--     else
--         -- 没上榜 默认放在最下面
--         local topY, bottomY = self:getRankEdge()
--         curY = bottomY
--     end
--     if curY then
--         self.myRankCell:setPositionY(curY)
--     end
-- end

-- function BaseRankUI:updateMyRankInfo()
--     local rank_data = self:getRankData()
--     if not rank_data then
--         return
--     end

--     if self.node_empty then
--         self.node_empty:setVisible(false)
--     end

--     local myIdx = rank_data:getSelfRankIndex()
--     local bl_inList = false
--     if #self.m_topThreeNodeList >= 3 and myIdx > 3 then
--         bl_inList = true
--     end
--     local bl_notInRank = false
--     if myIdx < 0 then
--         bl_notInRank = true
--     end

--     if bl_notInRank or bl_inList then
--         -- 没上榜或没在前三名 创建个人信息条并显示在榜单里
--     else
--         return
--     end

--     if not self.myRankCell then
--         self:initMyRankCell()
--     end
--     self.myRankCell:setVisible(true)
--     local curX = self.userList:getPositionX()
--     if curX then
--         self.myRankCell:setPositionX(curX)
--     end

--     self:updateMyRankOnScroll()
-- end

-- function BaseRankUI:getRankEdge()
--     if not self.rankListTopY or not self.rankListBottomY then
--         local size = self.userList:getSize()
--         local posY = self.userList:getPositionY()
--         local cell_size = self.myRankCell:getContentSize()
--         self.rankListTopY = posY + size.height / 2 - cell_size.height / 2
--         self.rankListBottomY = posY - size.height / 2 + cell_size.height / 2
--     end
--     return self.rankListTopY, self.rankListBottomY
-- end

--刷新名次排行榜
function BaseRankUI:refreshRankList(isRefresh)
    if not isRefresh and self.userList:isLoaded() then
        return
    end

    local rank_data = self:getRankData()
    if not rank_data then
        return
    end

    local rank_list = rank_data:getRankConfig(BTN_TYPE.RANK) or {}
    local list_data = clone(rank_list)
    if not list_data or #list_data <= 0 then
        -- 这里只是名次排行榜为空 玩家信息还是要显示的
        -- self:updateMyRankInfo()
        self.userList:initMyRankCellUI(self:getUserCellPath())
        self.userList:updateMyRankCell(self:getRankData())
        return
    end

    self:refreshTopRankUI(list_data)

    -- 前三名单独显示 筛除前三名
    if #self.m_topThreeNodeList >= 3 then
        table.remove(list_data, 1)
        table.remove(list_data, 1)
        table.remove(list_data, 1)
    end

    if self.node_empty then
        self.node_empty:setVisible(false)
    end

    self.userList:reload(list_data)

    -- local items = self.userList:getItems()
    -- local cell_num = table.nums(items)
    -- local data_num = table.nums(list_data)
    -- if data_num > LOAD_MAX_COUNT then
    --     data_num = LOAD_MAX_COUNT
    -- end

    local myIdx = rank_data:getSelfRankIndex()
    -- -- 刷新数据
    -- for idx = 1, data_num do
    --     local cell_data = list_data[idx]
    --     if cell_data then
    --         local rank_idx = rank_data:getRankIndex(cell_data.p_udid)
    --         local item = self.userList:getItem(idx - 1)
    --         if not item then
    --             item = self:initRankCell(cell_data, rank_idx, myIdx)
    --             if item then
    --                 self.userList:insertCustomItem(item, rank_idx - 1)
    --             end
    --         else
    --             if item.cell then
    --                 if rank_idx ~= myIdx and item.cell:getOpacity() == 0 then
    --                     item.cell:setOpacity(255)
    --                 end
    --                 item.cell:updateView(cell_data, rank_idx, myIdx)
    --             end
    --         end
    --     end
    -- end

    -- 去除多余条目
    -- if cell_num > data_num then
    --     for idx = data_num, cell_num do
    --         self.userList:removeItem(idx)
    --     end
    -- end

    local bl_inList = false
    if #self.m_topThreeNodeList >= 3 and myIdx > 3 then
        bl_inList = true
    end
    local bl_notInRank = false
    if myIdx < 0 then
        bl_notInRank = true
    end
    -- 没上榜或没在前三名
    if bl_notInRank or bl_inList then
        self.userList:initMyRankCellUI(self:getUserCellPath())
        self.userList:updateMyRankCell(rank_data.p_myRank, (myIdx - 3))
        -- if not self.cell_empty or tolua.isnull(self.cell_empty) then
        --     local item = self:initEmptyRankCell()
        --     if item then
        --         self.userList:pushBackCustomItem(item)
        --         self.cell_empty = item
        --     end
        -- end
    end

    -- if self.myRankCell then
    --     self.myRankCell:updateView(rank_data.p_myRank)
    -- end

    -- util_performWithDelay(self, handler(self, self.updateMyRankInfo), 1 / 60)
end

function BaseRankUI:refreshTopRankUI(list_data)
    if #self.m_topThreeNodeList ~= 3 then
        return
    end

    -- local rank_data = self:getRankData()
    -- if not rank_data then
    --     return
    -- end

    -- local list_data = rank_data:getRankConfig(BTN_TYPE.RANK)
    if not list_data or #list_data <= 0 then
        return
    end

    for i = 1, 3 do
        local topCell = self:createTopCell(i, list_data[i])
        if topCell then
            self.m_topThreeNodeList[i]:removeAllChildren()
            self.m_topThreeNodeList[i]:addChild(topCell)
        end
    end
end

function BaseRankUI:createTopCell(idx, data)
    if not data then
        data = {p_rank = idx, p_name = "Pending", p_points = 0}
    end
    local top_res = self:getTop3CellPath()
    if top_res and #top_res > 0 then
        local TopCell = class("TopCell", BaseRankTopThreeCellUI)
        function TopCell:getCsbName()
            return top_res[idx]
        end
        local topCell = TopCell:create()
        if topCell then
            topCell:initUI(data)
            return topCell
        end
    else
        local luaPath = self:getTopThreeCellLuaPath()
        if not luaPath or luaPath == "" then
            return
        end
        local topCell = util_createView(luaPath, data)
        return topCell
    end
end

--刷新奖励排行榜
function BaseRankUI:refreshRewardList(isRefresh)
    if not isRefresh and self.rewardList:isLoaded() then
        return
    end

    local data = self:getRankData()
    if not data then
        return
    end

    local reward_data = data:getRankConfig(BTN_TYPE.REWARD)
    if not reward_data or table.nums(reward_data) <= 0 then
        return
    end
    self.rewardList:setRewardItemScale(self:getRewardScale())

    -- local data_num = table.nums(reward_data)
    -- -- 刷新数据
    -- for idx = 1, data_num do
    --     local cell_data = reward_data[idx]
    --     local item = self.rewardList:getItem(idx - 1)
    --     if not item then
    --         item = self:initRewardCell(cell_data, idx)
    --         if item then
    --             self.rewardList:insertCustomItem(item, idx - 1)
    --         end
    --     else
    --         --if item.cell then
    --         --    item.cell:updateView(cell_data, idx)
    --         --end
    --     end
    -- end
    self.rewardList:reload(reward_data)
end

function BaseRankUI:onEnter()
    BaseRankUI.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, param)
            if param and param.refName == self:getRefName() then
                if not tolua.isnull(self) and self.updateView then
                    self:updateView(true)
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, param)
            if param and param.name == self:getRefName() then
                self:closeUI(
                    function()
                        -- 打开查看了 玩家信息板子关闭
                        local userMatonLayer = gLobalViewManager:getViewByExtendData("UserInfoMation")
                        if not tolua.isnull(userMatonLayer) then
                            userMatonLayer:closeUI()
                        end
                    end
                )
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function BaseRankUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_rank" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        release_print("CRASH[MQ], BaseRankUI:clickFunc btn_rank 1")
        self:showList(BTN_TYPE.RANK)
        -- self:updateView()
        release_print("CRASH[MQ], BaseRankUI:clickFunc btn_rank 2")
    elseif name == "btn_reward" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        release_print("CRASH[MQ], BaseRankUI:clickFunc btn_reward 1")
        self:showList(BTN_TYPE.REWARD)
        -- self:updateView()
        release_print("CRASH[MQ], BaseRankUI:clickFunc btn_reward 2")
    elseif name == "btn_rule" then
        release_print("CRASH[MQ], BaseRankUI:clickFunc btn_rule 1")
        self:showRankHelpUI()
        release_print("CRASH[MQ], BaseRankUI:clickFunc btn_rule 2")
    elseif name == "btn_close" then
        release_print("CRASH[MQ], BaseRankUI:clickFunc btn_close 1")
        self:closeUI()
        release_print("CRASH[MQ], BaseRankUI:clickFunc btn_close 2")
    end
end

function BaseRankUI:getActData()
    local act_ref = self:getRefName()
    if act_ref and G_GetMgr(act_ref) then
        assert(G_GetMgr(act_ref).getRunningData, "manager需要提供 getRunningData 接口，来获取活动数据")
        local data = G_GetMgr(act_ref):getRunningData()
        return data
    end
end

function BaseRankUI:getRankData()
    local act_data = self:getActData()
    if act_data then
        if not act_data.getRankCfg then
            printError("排行榜数据需要活动数据类实现方法 getRankCfg 来获取排行榜数据")
            return
        end
        return act_data:getRankCfg()
    end
end

function BaseRankUI:getRewardsData(rand_idx)
    local rank_data = self:getRankData()
    if rank_data then
        local rewards = rank_data:getRankConfig(BTN_TYPE.REWARD)
        if rewards and table.nums(rewards) > 0 then
            for i, reward_data in ipairs(rewards) do
                if reward_data.p_minRank == reward_data.p_maxRank then
                    if reward_data.p_minRank == rand_idx then
                        return reward_data
                    end
                elseif rand_idx >= reward_data.p_minRank and rand_idx <= reward_data.p_maxRank then
                    return reward_data
                end
            end
        end
    end
end

function BaseRankUI:getActKey()
    local data = self:getActData()
    if data then
        local theme_name = data:getThemeName()
        local ending = data:getExpireAt()
        return theme_name .. ending
    end
    assert(false, "getActKey 数据异常")
end

------------------------------------------子类重写---------------------------------------

-- 发送请求拉取排行榜最新数据
function BaseRankUI:sendRankRequestAction()
    assert(false, "子类重写方法，主动请求最新排行榜数据")
end

-- 活动引用名
function BaseRankUI:getRefName()
    assert(false, "子类重写方法，获取活动引用名")
end

-- 排行榜主界面资源
-- function BaseRankUI:getCsbName()
--     assert(false, "子类重写方法，指定主界面资源")
-- end

-- 排行榜玩法介绍界面资源
function BaseRankUI:getRankHelpPath()
    assert(false, "子类重写方法，指定排行榜玩法信息控件")
end

-- 排行榜标题栏资源
function BaseRankUI:getRankTitlePath()
    assert(false, "子类重写方法，指定排行榜金币条控件")
end

-- 排行榜倒计时资源
function BaseRankUI:getRankTimerPath()
    assert(false, "子类重写方法，获取排行榜倒计时控件")
end

-- 排行榜名次条目资源
function BaseRankUI:getUserCellPath()
    assert(false, "子类必须实现的方法，获取玩家控件")
end

-- 排行榜奖励条目资源
function BaseRankUI:getRewardCellPath()
    assert(false, "子类必须实现的方法，获取奖励控件")
end

function BaseRankUI:getCoinMaxLen()
    assert(false, "子类必须实现的方法，获取奖励控件金币最大显示长度")
end

-- 玩家排名中需要添加奖励显示
function BaseRankUI:getRewardItemPath()
    printInfo("子类西药重写这个方法")
end

-- 玩家前三名UI对应lua文件路径
function BaseRankUI:getTopThreeCellLuaPath()
    return ""
end

-- 玩家前三名ui
function BaseRankUI:getTop3CellPath()
    return {}
end

function BaseRankUI:mergeRankAndRewards(bl_merge)
    self.bl_merge = bl_merge
end

function BaseRankUI:getRewardScale()
    return 1
end

-- 排行榜名次列表中，单个cell的size
function BaseRankUI:getUserCellSize()
    return cc.size(813, 90)
end

-- 排行榜奖励列表中，单个cell的size
function BaseRankUI:getRewardCellSize()
    return cc.size(813, 90)
end

------------------------------------------子类重写---------------------------------------

return BaseRankUI
