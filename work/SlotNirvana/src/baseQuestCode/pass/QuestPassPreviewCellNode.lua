--[[
    tableview右侧固定奖励
    随着tableview滑动，动态改变奖励
]]
local QuestPassTableCell = util_require("baseQuestCode.pass.QuestPassTableCell")
local QuestPassPreviewCellNode = class("QuestPassPreviewCellNode", QuestPassTableCell)

function QuestPassPreviewCellNode:getCsbName()
    return QUEST_RES_PATH.QuestPassPreviewCellNode
end

function QuestPassPreviewCellNode:initUI()
    QuestPassPreviewCellNode.super.initUI(self)
    self.m_isPreview = true
    self.m_nodePro = self:findChild("node_progress")
    self.m_gameData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
end

-- 重写父类方法
function QuestPassPreviewCellNode:loadDataUi(_data, _idx)
    QuestPassPreviewCellNode.super.loadDataUi(self, _data, _idx)
    self:updateProgress()
end

function QuestPassPreviewCellNode:collectUpdate(_params)
    QuestPassPreviewCellNode.super.collectUpdate(self, _params)
end

function QuestPassPreviewCellNode:collectAllUpdate(_params)
    QuestPassPreviewCellNode.super.collectAllUpdate(self, _params)
end

function QuestPassPreviewCellNode:updateProgress()
    if self.m_progress == nil then
        self.m_progress = util_createView(QUEST_CODE_PATH.QuestPassPreviewCellProgressNode)
        self.m_nodePro:addChild(self.m_progress)
    end
    local cur = 0
    local total = 0
    local passData = self.m_gameData:getPassData()
    if passData then
        cur = passData:getCurExp()
        total = passData:getTotalExp()
    end
    local max = self.m_data.free.p_exp 
    if cur >= total then
        max = total
        cur = total
    end
    self.m_progress:updateProgress(cur, max)
end

function QuestPassPreviewCellNode:getCellPos(_boxType)
    if _boxType == "free" then
        local touchNode = self.m_freeView:getTouchNode()
        return touchNode:getParent():convertToWorldSpace(cc.p(touchNode:getPosition()))
    elseif _boxType == "pay" then
        local touchNode = self.m_ticketView:getTouchNode()
        return touchNode:getParent():convertToWorldSpace(cc.p(touchNode:getPosition()))
    end
end

-- function QuestPassPreviewCellNode:clickFunc(sender)
--     local name = sender:getName()
--     if name == "touch_free" then
--         self:onRewardNodeClick(false)
--     elseif name == "touch_pay" then
--         self:onRewardNodeClick(true)
--     end
-- end

function QuestPassPreviewCellNode:onEnter()
    QuestPassPreviewCellNode.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params then
                if params.show == true then
                    self:setVisible(true)
                    local QuestData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
                    if QuestData then
                        local passData = QuestData:getPassData()
                        if passData then
                            local passInfo = passData:getPassInfoByIndex(params.index)
                            self:loadDataUi(passInfo)
                        end
                    else
                        self:setVisible(false)
                    end
                else
                    self:setVisible(false)
                end
            end
        end,
        ViewEventType.NOTIFY_QUEST_PASS_TABLEVIEW_MOVE_ONE
    )
end

return QuestPassPreviewCellNode
