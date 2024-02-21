--[[
    tableview右侧固定奖励
    随着tableview滑动，动态改变奖励
]]
local DailyMissionPassCellNode = util_require(DAILYPASS_CODE_PATH.DailyMissionPass_PassCell_ThreeLine)
local DailyMissionThreeLinePassPreviewCellNode = class("DailyMissionThreeLinePassPreviewCellNode", DailyMissionPassCellNode)

function DailyMissionThreeLinePassPreviewCellNode:initDatas(isPortrait)
    self.m_isPortrait = isPortrait
end

function DailyMissionThreeLinePassPreviewCellNode:getCsbName()
    if self.m_isPortrait then
        return DAILYPASS_RES_PATH.DailyMissionPass_PreviewCellNode_Vertical
    else
        return DAILYPASS_RES_PATH.DailyMissionPass_PreviewCellNode
    end
end

function DailyMissionThreeLinePassPreviewCellNode:initUI()
    DailyMissionThreeLinePassPreviewCellNode.super.initUI(self)

    self.m_isPreview = true

    self.m_nodePro = self:findChild("node_progress")
    self.m_touchPay = self:findChild("touch_pay")
    self:addClick(self.m_touchPay)
    self.m_touchFree = self:findChild("touch_free")
    self:addClick(self.m_touchFree)
    self:addClick(self:findChild("touch_season"))
    self:addClick(self:findChild("touch_premium"))
end

-- 重写父类方法
function DailyMissionThreeLinePassPreviewCellNode:loadDataUi(_passInfo)
    self.m_passInfo = _passInfo
    self:updateReward()
    self:updateProgress()
end

function DailyMissionThreeLinePassPreviewCellNode:collectUpdate(_params)
    DailyMissionThreeLinePassPreviewCellNode.super.collectUpdate(self, _params)
end

function DailyMissionThreeLinePassPreviewCellNode:collectAllUpdate(_params)
    DailyMissionThreeLinePassPreviewCellNode.super.collectAllUpdate(self, _params)
end

function DailyMissionThreeLinePassPreviewCellNode:updateProgress()
    if not self.m_nodePro then
        return
    end
    if self.m_progress == nil then
        self.m_progress = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_PreviewCellProgressNode)
        self.m_nodePro:addChild(self.m_progress)
    end
    local cur = 0
    local passData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if passData then
        cur = passData:getCurExp()
    end
    local max = 999
    if self.m_passInfo.freeInfo then
        max = self.m_passInfo.freeInfo:getExp()
    end
    self.m_progress:updateProgress(cur, max)
end

function DailyMissionThreeLinePassPreviewCellNode:getCellPos(_boxType)
    if _boxType == "free" then
        local touchNode = self.m_freeView:getTouchNode()
        return touchNode:getParent():convertToWorldSpace(cc.p(touchNode:getPosition()))
    elseif _boxType == "season" then
        local touchNode = self.m_seasonView:getTouchNode()
        return touchNode:getParent():convertToWorldSpace(cc.p(touchNode:getPosition()))
    elseif _boxType == "premium" then
        local touchNode = self.m_premiumView:getTouchNode()
        return touchNode:getParent():convertToWorldSpace(cc.p(touchNode:getPosition()))
    end
end

function DailyMissionThreeLinePassPreviewCellNode:clickFunc(sender)
    local name = sender:getName()
    if name == "touch_free" then
        self:onRewardNodeClick(0)
    elseif name == "touch_season" then
        self:onRewardNodeClick(1)
    elseif name == "touch_premium" then
        self:onRewardNodeClick(2)
    end
end

function DailyMissionThreeLinePassPreviewCellNode:onEnter()
    DailyMissionThreeLinePassPreviewCellNode.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params then
                if params.show == true then
                    self:setVisible(true)
                    local passData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
                    if passData then
                        local passInfo = passData:getPassInfoByIndex(params.index)
                        self:loadDataUi(passInfo)
                    end
                else
                    self:setVisible(false)
                end
            end
        end,
        ViewEventType.NOTIFY_DAILYPASS_TABLEVIEW_MOVE_ONE
    )
end

return DailyMissionThreeLinePassPreviewCellNode
