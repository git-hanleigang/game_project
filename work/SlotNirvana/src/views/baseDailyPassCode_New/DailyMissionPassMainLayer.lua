--[[
    -- pass 主界面
]]
local DailyMissionPassMainLayer = class("DailyMissionPassMainLayer", BaseLayer)

local PAGE_TYPE = {
    MISSION_PAGE = 1,
    REWARD_PAGE = 2,
    FLOWER_PAGE = 3
}

function DailyMissionPassMainLayer:initDatas(isPortrait)
    self.m_isPortrait = isPortrait
    if not isPortrait then
        self:setResolutionPolicy(self.ResolutionPolicy.FIXED_HEIGHT)
    else
        self:setResolutionPolicy(self.ResolutionPolicy.FIXED_WIDTH)
    end
end

function DailyMissionPassMainLayer:ctor()
    DailyMissionPassMainLayer.super.ctor(self)
    
    self:setLandscapeCsbName(DAILYPASS_RES_PATH.DailyMissionPass_MainLayer)
    self:setPortraitCsbName(DAILYPASS_RES_PATH.DailyMissionPass_MainLayer_Vertical)

    self.m_inAction = false
    self.m_completeCreatePassTableView = true
    self:setMaskEnabled(false)
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    self:setShowBgOpacity(0)
end

function DailyMissionPassMainLayer:initCsbNodes()
    self.m_nodeRewardPage = self:findChild("node_rewardPage") -- reward 界面总节点
    self.m_nodePassReward = self:findChild("passPanelLayout") -- table View 节点

    self.m_nodePass = self:findChild("node_pass") -- 固定奖励
    self.m_nodePreview = self:findChild("node_fixedReward") -- 固定奖励
end

function DailyMissionPassMainLayer:initView()
    -- 检测当前是否有season 活动
    -- self:initRewardPageUI()
end

---------------------------------- Reward Page 相关 ----------------------------------
-- 创建rewardPage 页相关ui
function DailyMissionPassMainLayer:initRewardPageUI()
    self:createPassTableView()
    self:initPreviewCell()
end

function DailyMissionPassMainLayer:createPassTableView()
    -- 创建table view
    self.m_completeCreatePassTableView = false
    local tmpSize = self.m_nodePassReward:getContentSize()
    --
    local passViewInfo = {
        tableSize = tmpSize,
        parentPanel = self.m_nodePassReward,
        directionType =  self.m_isPortrait and 2 or 1 --1 水平方向 ; 2 垂直方向
    }
    local PassTableView = util_require(DAILYPASS_CODE_PATH.DailyMissionPass_PassTableView)
    self.m_passView = PassTableView:create(passViewInfo)
    local passData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    self.m_passView:reload()
    self.m_nodePass:addChild(self.m_passView)
    performWithDelay(
        self,
        function()
            self:updateTableViewToIndex(
                0.5,
                nil,
                function()
                    if not tolua.isnull(self) then
                        self.m_completeCreatePassTableView = true
                        if self.m_tableViewEnterScrollOverCallFun then
                            self.m_tableViewEnterScrollOverCallFun()
                        end
                    end
                end
            )
            self.m_bOpenRewardPage = true
        end,
        0.5
    )
end

function DailyMissionPassMainLayer:setTableViewEnterScrollOverCallFun(callFun)
    self.m_tableViewEnterScrollOverCallFun = callFun
end

-- 下一个有色奖励预览
function DailyMissionPassMainLayer:initPreviewCell()
    if not self.m_nodePreview then
        return
    end
    self.m_previewCell = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_PreviewCellNode_ThreeLine,self.m_isPortrait)
    self.m_nodePreview:addChild(self.m_previewCell)
    local previewIndex = 6 -- 默认
    if self.m_passView then
        previewIndex = self.m_passView:getPreviewIndex() or previewIndex
    end
    local passData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if passData then
        local passInfo = passData:getPassInfoByIndex(previewIndex)
        self.m_previewCell:loadDataUi(passInfo)
    end
end

function DailyMissionPassMainLayer:updatePreviewCellProgress()
    self.m_previewCell:updateProgress()
end

function DailyMissionPassMainLayer:updateRewardPage(_moveTableView)
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if not actData then
        return
    end
    -- 通知滑动界面到哪一个index
    if _moveTableView then
        if self.m_passView then
            self.m_passView:increaseProgressAction()
        end
    end
end

-- pass跳转
function DailyMissionPassMainLayer:updateTableViewToIndex(_nTime, _level, overCallBack)
    local passActData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if passActData then
        local currLevel = _level and _level or passActData:getLevel()
        if G_GetMgr(ACTIVITY_REF.NewPass):getIsMaxPoints() then
            currLevel = passActData:getLevel() + 1
        end
        -- 默认居中
        self.m_passView:scrollTableViewByRowIndex(currLevel + 1, _nTime, 1)
        if overCallBack then
            performWithDelay(
                self,
                function()
                    overCallBack()
                end,
                _nTime
            )
        end
    else
        if overCallBack then
            overCallBack()
        end
    end
end

-- 保险箱独立出来
function DailyMissionPassMainLayer:updateSafeBox(_max)
    if G_GetMgr(ACTIVITY_REF.NewPass):getInSafeBoxStatus() then
        self.m_passView:updateSafeBox(_max)
    end
end

function DailyMissionPassMainLayer:doAfterBuyPassUpdate(isSafeBox)
    if isSafeBox then
        self.m_passView:buyPassUpdate("safeBox")
        return
    end
    self.m_passView:buyPassUpdate("pay")
    self.m_previewCell:buyPassUpdate("pay")
end

function DailyMissionPassMainLayer:getCellPos(_boxType, _level, _offset)
    -- 从tableView 中获取
    local node = nil
    node = self.m_passView:getCellPos(_boxType, _level, _offset)
    return node
end

function DailyMissionPassMainLayer:getPreviewCellCellPos(_boxType)
    return self.m_previewCell:getCellPos(_boxType)
end

---------------------------------- 引导 相关 ----------------------------------
function DailyMissionPassMainLayer:onEnter()
    DailyMissionPassMainLayer.super.onEnter(self)

    self:initRewardPageUI()
end

function DailyMissionPassMainLayer:onExit()
    DailyMissionPassMainLayer.super.onExit(self)
end

function DailyMissionPassMainLayer:setMoveSpeedTime(value)
    self.m_passView:setMoveSpeedTime(value)
end

function DailyMissionPassMainLayer:scrollTableViewByRowIndex(_rowIndex, _scrollTime, _direction, _bAction)
    self.m_passView:scrollTableViewByRowIndex(_rowIndex, _scrollTime, _direction, _bAction)
end

function DailyMissionPassMainLayer:scrollToBottom()
    self.m_passView:scrollToBottom(0.4)
end

function DailyMissionPassMainLayer:beforeClose()
    self.m_passView:beforeClose()
    self.m_nodeRewardPage:setVisible(false)
end

function DailyMissionPassMainLayer:getPreviewNodePos()
    local previewPos = cc.p(self.m_nodePreview:getPosition())
    local pos = self.m_nodePreview:getParent():convertToWorldSpace(cc.p(previewPos.x, previewPos.y))
    return pos
end

function DailyMissionPassMainLayer:collectAllUpdate()
    self.m_passView:collectAllUpdate()
    self.m_previewCell:collectAllUpdate()
end

function DailyMissionPassMainLayer:collectUpdate(rewardInfo)
    self.m_passView:collectUpdate(rewardInfo)
    self.m_previewCell:collectUpdate(rewardInfo)
end


return DailyMissionPassMainLayer
