--[[
    DailyMissionPassTableView
]]
local BaseTable = require("base.BaseTable")
local DailyMissionPassTableView = class("DailyMissionPassTableView", BaseTable)

DailyMissionPassTableView.CONFIG = {
    normal = {
        SAFEBOX_SIZE = {w = 320, h = 335},
        TAG_SIZE = {w = 200, h = 335},
        CELL_SIZE = {w = 140, h = 335}
    }
    ,
    threeLine = {
        SAFEBOX_SIZE = {w = 510, h = 380,w_p = 768 ,h_p = 510},
        TAG_SIZE = {w = 250, h = 380,w_p = 768,h_p = 160},
        CELL_SIZE = {w = 180, h = 380,w_p = 768,h_p = 180}
    }
}

function DailyMissionPassTableView:getConfig()
    if G_GetMgr(ACTIVITY_REF.NewPass):isThreeLinePass() then
        return  self.CONFIG.threeLine
    else
        return  self.CONFIG.normal
    end
end
-- overwrite --
function DailyMissionPassTableView:reload(passData)
    self.m_curProgressLen = 0
    -- 是否可以涨进度
    self.m_isCanInc = true
    -- 进度条增长基础时间
    self.m_perSpeedTime = 1

    -- 增长动画标识
    self.m_isIncrease = false
    self.m_startLevel = 1

    -- 积分文本list
    self.m_pointLabelList = nil
    self.m_pointArriveBgList = nil

    self._cellList = {}

    DailyMissionPassTableView.super.reload(self)
    
    self:initPreviewIndex()
end


-- overwrite --
function DailyMissionPassTableView:setViewData()
    self.m_passPoints = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData():getPassPointsInfo()

    self.m_cellCenterPos = {}
    local _viewData = {}
    -- 创建多少个数据节点
    for i = 1, #self.m_passPoints do
        _viewData[#_viewData + 1] = self.m_passPoints[i]
    end
    self._maxIndex = table.nums(_viewData)
    DailyMissionPassTableView.super.setViewData(self, _viewData)
end

-- overwrite --
function DailyMissionPassTableView:cellSizeForTable(table, idx)
    -- 有些特殊情况 不需要传入idx 直接获取通用Cell大小 暂时先这样 --
    idx = idx or 0

    if self._tableDirection == 1 then -- 横版
        -- 如果是最有一个大宝箱 --
        if idx + 1 == self._maxIndex then
            return self:getConfig().SAFEBOX_SIZE.w, self:getConfig().SAFEBOX_SIZE.h
        elseif idx + 1 == 1 then -- 如果第一格是标签页的话
            return self:getConfig().TAG_SIZE.w, self:getConfig().TAG_SIZE.h
        end
        -- 根据idx 来处理CellSize -- 普通的节点按照付费点大小来设置
        return self:getConfig().CELL_SIZE.w, self:getConfig().CELL_SIZE.h
    else    -- 竖版
        -- 如果是最有一个大宝箱 --
        if idx + 1 == self._maxIndex then
            return self:getConfig().SAFEBOX_SIZE.w_p, self:getConfig().SAFEBOX_SIZE.h_p
        elseif idx + 1 == 1 then -- 如果第一格是标签页的话
            return self:getConfig().TAG_SIZE.w_p, self:getConfig().TAG_SIZE.h_p
        end
        -- 根据idx 来处理CellSize -- 普通的节点按照付费点大小来设置
        return self:getConfig().CELL_SIZE.w_p, self:getConfig().CELL_SIZE.h_p
    end
end

-- overwrite --
function DailyMissionPassTableView:tableCellAtIndex(tableView, idx)
    local cell = tableView:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    end
    if cell.view == nil then
        cell.view = util_createView(self:getCellLua(),self._tableDirection == 2)
        cell:addChild(cell.view)
        table.insert(self._cellList, cell.view)
    end

    -- Manager get data --
    local data = self._viewData[idx + 1]
    data.increase = (idx + 1 > self.m_startLevel) and self.m_isIncrease or false
    cell.view:loadDataUi(data, idx + 1, self._maxIndex)
    return cell
end

function DailyMissionPassTableView:getCellLua()
    return DAILYPASS_CODE_PATH.DailyMissionPass_PassCell_ThreeLine 
end
--购买后刷新
function DailyMissionPassTableView:buyPassUpdate(params)
    self:setViewData()
    for k, v in pairs(self._cellList) do
        v:buyPassUpdate(params)
    end
end
--收集更新
function DailyMissionPassTableView:collectUpdate(params)
    self:setViewData()
    for k, v in pairs(self._cellList) do
        v:collectUpdate(params)
    end
end

--关闭界面时 先停止动画
function DailyMissionPassTableView:beforeClose()
    for k, v in pairs(self._cellList) do
        v:beforeClose()
    end
end

-- 一键领取
function DailyMissionPassTableView:collectAllUpdate()
    self:setViewData()
    -- 只是当前屏幕更新
    for k, v in pairs(self._cellList) do
        v:collectAllUpdate()
    end
end

function DailyMissionPassTableView:updateSafeBox(_max)
    self:setViewData()
    -- 只是当前屏幕更新
    for k, v in pairs(self._cellList) do
        v:updateSafeBoxStatus(_max)
    end
end

function DailyMissionPassTableView:getCellByLevel(_boxType, _level)
    local node = nil
    for k, v in pairs(self._cellList) do
        node = v:getCellByLevel(_boxType, _level)
        if node then
            break
        end
    end
    return node
end

function DailyMissionPassTableView:getCellPos(_boxType, _level, _offset)
    if _offset == nil then
        _offset = cc.p(0, 0)
    end
    if self._tableDirection == 2 then
        _offset = cc.p(384, 152)
    end
    local pos = nil
    local cellNode = self:getCellByLevel(_boxType, _level)
    if cellNode then
        local cellNodePos = cc.p(cellNode:getParent():getPosition())
        local tableCell = self:cellAtIndex(_level)
        if tableCell then
            local tableCellPos = cc.p(tableCell:getPosition())
            local finalPos = cc.p(tableCellPos.x + cellNodePos.x + _offset.x, tableCellPos.y + cellNodePos.y + _offset.y)
            pos = tableCell:getParent():convertToWorldSpace(finalPos)
        end
    end
    return pos
end

-- 触摸的处理
function DailyMissionPassTableView:_onTouchBegan(event)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_REMOVE_REWARD_INFO, true)
    local touchPoint = cc.p(event.x, event.y)
    self._pointTouchBegin = touchPoint
    return DailyMissionPassTableView.super._onTouchBegan(self, event)
end

function DailyMissionPassTableView:_onTouchEnded(event)
    local touchPoint = cc.p(event.x, event.y)
    local distance = cc.pGetDistance(self._pointTouchBegin, touchPoint)
    if distance <= 10 then
        -- print --
        local cellView = nil
        local panelIndex = nil

        local tablecellNum = self._unitTableView:getChildrenCount()

        for i, v in pairs(self._cellList) do
            self:checkTouchCell_ThreeLine(v,touchPoint)
        end
    end
end

function DailyMissionPassTableView:checkTouchCell_ThreeLine(cellNode,touchPoint)
    -- 检测上节点 --
    local hitNode = cellNode:getRewardNode(2)
    if hitNode then
        local isTouchPosPanel = self:onTouchCellChildNode(hitNode, touchPoint)
        if isTouchPosPanel then
            cellNode:onRewardNodeClick(2)
            return
        end
    end
    -- 检测中节点 --
    hitNode = cellNode:getRewardNode(1)
    if hitNode then
        local isTouchPosPanel = self:onTouchCellChildNode(hitNode, touchPoint)
        if isTouchPosPanel then
            cellNode:onRewardNodeClick(1)
            return
        end
    end
    -- 检测下节点 --
    hitNode = cellNode:getRewardNode(0)
    if hitNode then
        local isTouchPosPanel = self:onTouchCellChildNode(hitNode, touchPoint)
        if isTouchPosPanel then
            cellNode:onRewardNodeClick(0)
            return
        end
    end
    -- 检测大宝箱 -- qipao
    hitNode = cellNode:getBoxNode("qipao")
    if hitNode then
        local isTouchPosPanel = self:onTouchCellChildNode(hitNode, touchPoint)
        if isTouchPosPanel then
            cellNode:onBoxNodeClick("qipao")
            return
        end
    end
    -- 检测大宝箱 -- 购买
    hitNode = cellNode:getBoxNode("buy")
    if hitNode then
        local isTouchPosPanel = self:onTouchCellChildNode(hitNode, touchPoint)
        if isTouchPosPanel then
            cellNode:onBoxNodeClick("buy")
            return
        end
    end
end

-- 创建进度条
function DailyMissionPassTableView:initProgress()
    -- 添加进度条 --
    local tmpSize = self._unitTableView:getContentSize()
    local levelProgressPath = DAILYPASS_RES_PATH.DailyMissionPass_LevelProgress_ThreeLine 
    if self._tableDirection == 2 then
        levelProgressPath = DAILYPASS_RES_PATH.DailyMissionPass_LevelProgress_ThreeLine_Vertical 
    end
    self.m_progressNode = util_csbCreate(levelProgressPath)
    self._unitTableView:addChild(self.m_progressNode, -1)

     -- 进度条imageview
     self.m_progress = self.m_progressNode:getChildByName("progress")

     self.m_pointLabelList = {}
     self.m_pointArriveBgList = {}

    if self._tableDirection == 1 then
        local pos_pro_y = tmpSize.height / 2 - 115
        -- 进度条起始坐标 = tag页的中心
        self.m_progressStartX = self:getConfig().TAG_SIZE.w / 2
        self.m_progressNode:setPosition(cc.p(self.m_progressStartX, pos_pro_y))

        if self.m_progressNode then
            local oriSize = self.m_progressNode:getChildByName("progressBg"):getContentSize()
    
            -- 设置进度条最大长度 = 总个数 - 3（去掉保险箱 和 tag 页 和 第一奖励） * 每个道具框的大小 + 补足量（为了展示效果）
            local disBuff = 0
            local cellWidht = self:getConfig().CELL_SIZE.w
            local progressBg = self.m_progressNode:getChildByName("progressBg")
            progressBg:setContentSize(self.m_progressStartX + cellWidht / 2 + cellWidht * (#self.m_passPoints - 3) + disBuff, oriSize.height)
            local rightFrame = self.m_progressNode:getChildByName("progressBg_right")
            rightFrame:setPosition(cc.p(progressBg:getContentSize().width, rightFrame:getPositionY()))
    
            local pass_progress_jiao = self.m_progressNode:getChildByName("pass_progress_jiao")
            pass_progress_jiao:setVisible(false)
            
            local pass_progress_jiao = self.m_progressNode:getChildByName("pass_progress_kuang")
            pass_progress_jiao:setVisible(false)
    
            -- 计算每个付费奖励的坐标
            for i = 1, #self.m_passPoints do
                if i > 1 and i < #self.m_passPoints then
                    local img_path = DAILYPASS_RES_PATH.DailyMissionPass_LevelProgress_Frame
                    if i == #self.m_passPoints - 1 then
                        img_path = DAILYPASS_RES_PATH.DailyMissionPass_LevelProgress_Frame_Last
                    end
                    local spCorner = cc.Sprite:create(img_path)
                    local posX = cellWidht * (i - 1) + (self.m_progressStartX - cellWidht / 2)
                    spCorner:setPosition(cc.p(posX, 0))
                    self.m_progressNode:addChild(spCorner)
            

                    local spCorner_Arrived = cc.Sprite:create(DAILYPASS_RES_PATH.DailyMissionPass_LevelProgress_Frame_Arrived)
                    spCorner_Arrived:setPosition(cc.p(posX, -1.5))
                    spCorner_Arrived:setVisible(false)
                    self.m_progressNode:addChild(spCorner_Arrived)

                    table.insert(self.m_pointArriveBgList,{spCorner,spCorner_Arrived})
    
                    local fnt = ccui.TextBMFont:create()
                    fnt:setFntFile(DAILYPASS_RES_PATH.DailyMissionPass_LevelProgress_Font)
                    fnt:setString(self.m_passPoints[i].payInfo:getExp())
                    fnt:setPosition(cc.p(posX, 1.5))
                    fnt:setScale(0.8)
                    self.m_progressNode:addChild(fnt,10)

                    local fnt_Arrived = ccui.TextBMFont:create()
                    fnt_Arrived:setFntFile(DAILYPASS_RES_PATH.DailyMissionPass_LevelProgress_Font_Arrived)
                    fnt_Arrived:setString(self.m_passPoints[i].payInfo:getExp())
                    fnt_Arrived:setPosition(cc.p(posX, 0))
                    fnt_Arrived:setScale(0.8)
                    fnt_Arrived:setVisible(false)
                    self.m_progressNode:addChild(fnt_Arrived,10)

                    table.insert(self.m_pointLabelList,{fnt,fnt_Arrived})
                end
            end
            -- 更新进度条长度
            self.m_curProgressLen = self:caculateProgressLen()
            self.m_startLevel = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData():getLevel()
            self:updateProgress()
            self:updatePonitLabelStatus()
        end

    else
        local pos_pro_x = tmpSize.width / 2 - 140
        -- 进度条起始坐标 = tag页的中心
        local disBuff = 0
        local cellHeight = self:getConfig().CELL_SIZE.h_p
        self.m_progressStartY = self:getConfig().TAG_SIZE.h_p / 2  + cellHeight * (#self.m_passPoints - 2) + self:getConfig().SAFEBOX_SIZE.h_p
        self.m_progressNode:setPosition(cc.p(pos_pro_x , self.m_progressStartY))

        if self.m_progressNode then
            local oriSize = self.m_progressNode:getChildByName("progressBg"):getContentSize()
    
            local progressBg = self.m_progressNode:getChildByName("progressBg") 
            progressBg:setContentSize(self:getConfig().TAG_SIZE.h_p / 2 + cellHeight / 2 + cellHeight * (#self.m_passPoints - 3) + disBuff  ,oriSize.height )
            local rightFrame = self.m_progressNode:getChildByName("progressBg_right")
            rightFrame:setPosition(cc.p( 0 , - progressBg:getContentSize().width))
    
            local pass_progress_jiao = self.m_progressNode:getChildByName("pass_progress_jiao")
            pass_progress_jiao:setVisible(false)

            local pass_progress_jiao = self.m_progressNode:getChildByName("pass_progress_kuang")
            pass_progress_jiao:setVisible(false)
    
            -- 计算每个付费奖励的坐标
            for i = 1, #self.m_passPoints do
                if i > 1 and i < #self.m_passPoints then
                    local img_path = DAILYPASS_RES_PATH.DailyMissionPass_LevelProgress_Frame
                    if i == #self.m_passPoints - 1 then
                        img_path = DAILYPASS_RES_PATH.DailyMissionPass_LevelProgress_Frame_Last
                    end
                    local spCorner = cc.Sprite:create(img_path)
                    local posY = - cellHeight * (i - 1)
                    spCorner:setPosition(cc.p(1.5, posY))
                    spCorner:setRotation(90)
                    self.m_progressNode:addChild(spCorner)

                    local spCorner_Arrived = cc.Sprite:create(DAILYPASS_RES_PATH.DailyMissionPass_LevelProgress_Frame_Arrived)
                    spCorner_Arrived:setPosition(cc.p(-1.5, posY))
                    spCorner_Arrived:setRotation(90)
                    spCorner_Arrived:setVisible(false)
                    self.m_progressNode:addChild(spCorner_Arrived)

                    table.insert(self.m_pointArriveBgList,{spCorner,spCorner_Arrived})
    
                    local fnt = ccui.TextBMFont:create()
                    fnt:setFntFile(DAILYPASS_RES_PATH.DailyMissionPass_LevelProgress_Font)
                    fnt:setString(self.m_passPoints[i].payInfo:getExp())
                    fnt:setPosition(cc.p(0, posY))
                    fnt:setScale(0.8)
                    self.m_progressNode:addChild(fnt,10)

                    local fnt_Arrived = ccui.TextBMFont:create()
                    fnt_Arrived:setFntFile(DAILYPASS_RES_PATH.DailyMissionPass_LevelProgress_Font_Arrived)
                    fnt_Arrived:setString(self.m_passPoints[i].payInfo:getExp())
                    fnt_Arrived:setPosition(cc.p(0, posY))
                    fnt_Arrived:setScale(0.8)
                    fnt_Arrived:setVisible(false)
                    self.m_progressNode:addChild(fnt_Arrived,10)

                    table.insert(self.m_pointLabelList,{fnt,fnt_Arrived})
                end
            end
            -- 更新进度条长度
            self.m_curProgressLen = self:caculateProgressLen()
            self.m_startLevel = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData():getLevel()
            self:updateProgress()
            self:updatePonitLabelStatus()
        end
    end
end

-- 更新中间的进度条显示 --
function DailyMissionPassTableView:updateProgress()
    if not self.m_progressNode then
        return
    end
    local curWidth = self.m_curProgressLen or 0

    local _size = self.m_progress:getContentSize()
    _size.width = curWidth
    self.m_progress:setContentSize(_size)
end

-- 计算出总长度
function DailyMissionPassTableView:caculateProgressLen()
    local progressLen = 0
    if self._tableDirection == 1 then
        local cellWidht = self:getConfig().CELL_SIZE.w
        local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
        local curLevel = actData:getLevel()
        local progress = self.m_progressNode:getChildByName("progress")
        local oriSize = progress:getContentSize()
        local firstWidht = self.m_progressStartX + cellWidht / 2 -- 进度条起始坐标 + 到第一个奖励中心的距离
        local startDis = firstWidht + (cellWidht * (curLevel - 1)) -- +当前有几个等级奖励间距  -- 12 csb 制作问题需要补的进度条大小

        local levelExpList = actData:getLevelExpList()
        local curExp = actData:getCurExp()
        if curExp >= levelExpList[#levelExpList] then -- 如果当前经验已经满了,直接设置为最长
            local progressBg = self.m_progressNode:getChildByName("progressBg")
            local rightFrame = self.m_progressNode:getChildByName("progressBg_right")
            local dis = progressBg:getContentSize().width + rightFrame:getContentSize().width / 2 - 3 -- 作图误差值
            progressLen = dis
        else
            -- 需要计算 0级时候的情况
            local overflowExp = curExp - levelExpList[curLevel] -- 溢出的经验
            local nextNeedLevelExp = levelExpList[curLevel + 1] - levelExpList[curLevel] -- 下一级需要的经验
            local increase = overflowExp / nextNeedLevelExp * self:getConfig().CELL_SIZE.w -- 占比 * 道具间距
            increase = curExp > 0 and increase or 0
            progressLen = startDis + increase
        end
    else
        local cellHeight = self:getConfig().CELL_SIZE.h_p
        local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
        local curLevel = actData:getLevel()
        local progress = self.m_progressNode:getChildByName("progress")
        local oriSize = progress:getContentSize()
        local firstWidht = self:getConfig().TAG_SIZE.h_p / 2 + cellHeight / 2 -- 进度条起始坐标 + 到第一个奖励中心的距离
        local startDis = firstWidht + (cellHeight * (curLevel - 1)) -- +当前有几个等级奖励间距  -- 12 csb 制作问题需要补的进度条大小

        local levelExpList = actData:getLevelExpList()
        local curExp = actData:getCurExp()
        if curExp >= levelExpList[#levelExpList] then -- 如果当前经验已经满了,直接设置为最长
            local progressBg = self.m_progressNode:getChildByName("progressBg")
            local rightFrame = self.m_progressNode:getChildByName("progressBg_right")
            local dis = progressBg:getContentSize().width + rightFrame:getContentSize().width/2 - 3  -- 作图误差值
            progressLen = dis
        else
            -- 需要计算 0级时候的情况
            local overflowExp = curExp - levelExpList[curLevel] -- 溢出的经验
            local nextNeedLevelExp = levelExpList[curLevel + 1] - levelExpList[curLevel] -- 下一级需要的经验
            local increase = overflowExp / nextNeedLevelExp * self:getConfig().CELL_SIZE.h_p -- 占比 * 道具间距
            increase = curExp > 0 and increase or 0
            progressLen = startDis + increase
        end
    end
    
    return progressLen
end

-- 进度增长动画
function DailyMissionPassTableView:increaseProgressAction()
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if not actData then
        return
    end

    if self.m_curProgressLen == self:caculateProgressLen() then
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_INC_EXP_OVER)
        return
    end

    self.m_isIncrease = true
    -- 添加遮罩
    gLobalViewManager:addLoadingAnima(true)
    local intervalTime = 1 / 60
    -- 最新的当前长度
    local curProgressLen = self:caculateProgressLen()
    -- 根据不同情况可以设置不同的速度
    local sppeedTiem = self.m_moveSpeedTime and self.m_moveSpeedTime or self.m_perSpeedTime
    self.m_moveSpeedTime = nil

    local speedVal = curProgressLen - self.m_curProgressLen
    speedVal = speedVal * intervalTime / sppeedTiem

    if self.m_sheduleHandle then
        scheduler.unscheduleGlobal(self.m_sheduleHandle)
    end
    local sumDis = 0
    self.cellIndex = (self.m_startLevel + 1) + 1
    self.m_sheduleHandle =
        scheduler.scheduleGlobal(
        function()
            if self.m_curProgressLen < curProgressLen then
                if not self.m_isCanInc then
                    return
                end

                local newProgressLen = math.min(self.m_curProgressLen + speedVal, curProgressLen)
                self.m_curProgressLen = newProgressLen
                self:updateProgress()
                sumDis = sumDis + speedVal
                self:scrollTableViewByDis(self.m_startLevel + 1, sumDis, 0, 1)
                self:updateCellStatus()
            else
                self:updateCellStatus()
                if self.m_sheduleHandle then
                    self.m_isCanInc = true
                    scheduler.unscheduleGlobal(self.m_sheduleHandle)
                    self.m_sheduleHandle = nil
                    self.m_startLevel = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData():getLevel()
                    self.m_isIncrease = false
                    -- 稍微做个延迟
                    performWithDelay(
                        self,
                        function()
                            gLobalViewManager:removeLoadingAnima()
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_INC_EXP_OVER)
                        end,
                        0.3
                    )
                end
            end
        end,
        intervalTime
    )
end

function DailyMissionPassTableView:updateCellStatus()
    local cellPos = self:getPosAtIndex(self.cellIndex)
    if self._tableDirection == 1 then
        local len = self.m_curProgressLen + self.m_progressStartX - self:getConfig().CELL_SIZE.w / 2
        if len >= cellPos.x then
            --调用刷新
            local freenode = self:getCellByLevel("free", self.cellIndex - 1)
            if freenode then
                freenode:updateClaimStatus()
            end
            
            if G_GetMgr(ACTIVITY_REF.NewPass):isThreeLinePass() then
                --顶部
                local paynode = self:getCellByLevel("premium", self.cellIndex - 1)
                if paynode then
                    paynode:updateClaimStatus()
                end
                -- 中部
                paynode = self:getCellByLevel("season", self.cellIndex - 1)
                if paynode then
                    paynode:updateClaimStatus()
                end
            else
                local paynode = self:getCellByLevel("pay", self.cellIndex - 1)
                if paynode then
                    paynode:updateClaimStatus()
                end
            end

            self:updatePonitLabelStatus(self.cellIndex - 1)
            self.cellIndex = self.cellIndex + 1
        end
    else
        local len = self.m_progressStartY - self.m_curProgressLen  - self:getConfig().CELL_SIZE.h_p / 2
        if len <= cellPos.y then
            --调用刷新
            local freenode = self:getCellByLevel("free", self.cellIndex - 1)
            if freenode then
                freenode:updateClaimStatus()
            end
            
            if G_GetMgr(ACTIVITY_REF.NewPass):isThreeLinePass() then
                --顶部
                local paynode = self:getCellByLevel("premium", self.cellIndex - 1)
                if paynode then
                    paynode:updateClaimStatus()
                end
                -- 中部
                paynode = self:getCellByLevel("season", self.cellIndex - 1)
                if paynode then
                    paynode:updateClaimStatus()
                end
            else
                local paynode = self:getCellByLevel("pay", self.cellIndex - 1)
                if paynode then
                    paynode:updateClaimStatus()
                end
            end

            self:updatePonitLabelStatus(self.cellIndex - 1)
            self.cellIndex = self.cellIndex + 1
        end
    end
    -- 当前长度需要 + 进度条node 的起始距离 - 后面每个奖励块的大小 /2
    
end

--[[
    @desc: 隐藏积分节点
    --@_level: 指定等级隐藏
]]
function DailyMissionPassTableView:updatePonitLabelStatus(_level)
    -- 需要判断当前积分节点是否允许展示
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if not actData then
        return
    end
    local curLevel = actData:getLevel()
    if self.m_pointLabelList ~= nil and #self.m_pointLabelList > 0 then
        local lbNodeMap = nil
        if _level then
            lbNodeMap = self.m_pointLabelList[_level]
            if lbNodeMap[1] then
                lbNodeMap[1]:setVisible(false)
            end
            if lbNodeMap[2] then
                lbNodeMap[2]:setVisible(true)
            end
        else
            for i = 1, #self.m_pointLabelList do
                if curLevel >= i then
                    lbNodeMap = self.m_pointLabelList[i]
                    if lbNodeMap[1] then
                        lbNodeMap[1]:setVisible(false)
                    end
                    if lbNodeMap[2] then
                        lbNodeMap[2]:setVisible(true)
                    end
                end
            end
        end
    end
    if self.m_pointArriveBgList ~= nil and #self.m_pointArriveBgList > 0 then
        local spNodeMap = nil
        if _level then
            spNodeMap = self.m_pointArriveBgList[_level]
            if spNodeMap[1] then
                spNodeMap[1]:setVisible(false)
            end
            if spNodeMap[2] then
                spNodeMap[2]:setVisible(true)
            end
        else
            for i = 1, #self.m_pointArriveBgList do
                if curLevel >= i then
                    spNodeMap = self.m_pointArriveBgList[i]
                    if spNodeMap[1] then
                        spNodeMap[1]:setVisible(false)
                    end
                    if spNodeMap[2] then
                        spNodeMap[2]:setVisible(true)
                    end
                end
            end
        end
    end
    
end

function DailyMissionPassTableView:setMoveSpeedTime(_time)
    self.m_moveSpeedTime = _time
end

-- 重写父类
-- _bAction 是否为主动调用
function DailyMissionPassTableView:scrollTableViewByRowIndex(_rowIndex, _scrollTime, _direction, _bAction)
    if _bAction then
        self.m_bAction = _bAction --
    end
    DailyMissionPassTableView.super.scrollTableViewByRowIndex(self, _rowIndex, _scrollTime, _direction)
end

-- 重写父类
function DailyMissionPassTableView:scrollViewDidScroll(view)
    local pos = self:getTable():getContentOffset()
    if self.m_bAction then
        if self.m_offsetX then
            if math.abs(math.abs(pos.x) - math.abs(self.m_offsetX)) < 0.999 then
                print("----csc 当前滑动层坐标 self.m_offsetX == " .. self.m_offsetX)
                self.m_bAction = nil
                self.m_offsetX = nil
                util_nextFrameFunc(
                    function()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_TABLEVIEW_MOVEOVER)
                    end
                )
            end
        elseif self.m_offsetY then
            if math.abs(math.abs(pos.y) - math.abs(self.m_offsetY)) < 0.999 then
                print("----csc 当前滑动层坐标 self.m_offsetY == " .. self.m_offsetY)
                self.m_bAction = nil
                self.m_offsetY = nil
                util_nextFrameFunc(
                    function()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_TABLEVIEW_MOVEOVER)
                    end
                )
            end
        end

    end
    DailyMissionPassTableView.super.scrollViewDidScroll(self, view)
    -- 滚动的时候同时刷新固定奖励
    local maxIndex = self:getMaxShowIndex()
    if maxIndex ~= nil then
        local previewIndex = self:getPreviewIndexFromIndex(maxIndex)
        if previewIndex and previewIndex ~= self.m_previewIndex then
            self.m_previewIndex = previewIndex
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_TABLEVIEW_MOVE_ONE, {show = true, index = previewIndex})
        end
    else
        self.m_previewIndex = nil
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_TABLEVIEW_MOVE_ONE, {show = false})
    end
end

function DailyMissionPassTableView:initPreviewIndex()
    local maxIndex = self:getMaxShowIndex()
    if maxIndex ~= nil then
        self.m_previewIndex = self:getPreviewIndexFromIndex(maxIndex)
    end
end

function DailyMissionPassTableView:getPreviewIndex()
    return self.m_previewIndex
end

function DailyMissionPassTableView:getMaxShowIndex()
    local pos = self:getTable():getContentOffset()
    if self._tableDirection == 1 then
        local offsetX = pos.x -- 默认是0，往左滑动时，是负数
        local fixedCellWidth = 200
        if G_GetMgr(ACTIVITY_REF.NewPass):isThreeLinePass() then
            fixedCellWidth = 140
        end
        local cellWidht = self:getConfig().CELL_SIZE.w
        local hidePosX = self._posList[self._maxIndex-1].x
        local maxShowPosX = self._tableSize.width - fixedCellWidth - cellWidht - offsetX -- offsetX 是负数，要用减
        maxShowPosX = math.max(maxShowPosX, 0)
        if maxShowPosX < hidePosX then
            local maxIndex = self:getIndexAtPos_X(maxShowPosX)
            return maxIndex
        end
    else
        local offsetY = pos.y -- 默认是0，往左滑动时，是负数
        local fixedCellHeight = 160

        local cellHeight = self:getConfig().CELL_SIZE.h_p
        local hidePosY = self._posList[self._maxIndex-1].y
        local maxShowPosY = self._tableSize.height - fixedCellHeight - cellHeight - offsetY - self:getConfig().SAFEBOX_SIZE.h_p -- offsetX 是负数，要用减
        maxShowPosY = math.max(maxShowPosY, 0)
        -- print("!!! scrollViewDidScroll offsetX, maxShowPosX, hidePosX=", pos.x, maxShowPosX, hidePosX)
        if maxShowPosY > hidePosY then
            local maxIndex = self:getIndexAtPos_Y(maxShowPosY)
            return maxIndex
        end
    end
    
    return nil
end

function DailyMissionPassTableView:getPreviewIndexFromIndex(_maxIndex)
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if actData then
        local index = actData:getPreviewIndex(_maxIndex)
        if index and index ~= self.m_showMaxIndex then
            return index
        end
    end
    return nil
end

-- OnEnter --
function DailyMissionPassTableView:onEnter()
    self:initProgress()
end

--
function DailyMissionPassTableView:onExit()
    if self.m_sheduleHandle then
        scheduler.unscheduleGlobal(self.m_sheduleHandle)
        self.m_sheduleHandle = nil
    end
end

function DailyMissionPassTableView:getIndexAtPos_X(_offsetX)
    for i=1,#self._posList do
        if i > 1 then
            local prePos = self._posList[i-1]
            local curPos = self._posList[i]
            if _offsetX >= prePos.x  and _offsetX < curPos.x then
                return i-1
            end
        end
    end
end

function DailyMissionPassTableView:getIndexAtPos_Y(_offseY)
    for i=1,#self._posList do
        if i > 1 then
            local prePos = self._posList[i-1]
            local curPos = self._posList[i]
            if _offseY < prePos.y  and _offseY >= curPos.y then
                return i-1
            end
        end
    end
end

return DailyMissionPassTableView
