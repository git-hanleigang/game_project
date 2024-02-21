-- quest 排行榜推送面板 基类

local QuestShowTop = class("QuestShowTop", BaseLayer)

function QuestShowTop:initDatas(csbName)
    self:setLandscapeCsbName(csbName)
    self:setPauseSlotsEnabled(true)
end

function QuestShowTop:initCsbNodes()
    self.m_btnClose = self:findChild("btn_close")
    -- assert(self.m_btnClose, "QuestShowTop 缺少必要的资源节点1")

    self.m_btnLetsgo = self:findChild("btn_letsgo")
    -- assert(self.m_btnLetsgo, "QuestShowTop 缺少必要的资源节点2")

    self:setButtonLabelContent("btn_rank", "SEE MY RANK")
    self:startButtonAnimation("btn_rank", "breathe", true)
end

function QuestShowTop:onKeyBack()
    self:closeUI(
        function()
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end
    )
end

function QuestShowTop:onEnter()
    QuestShowTop.super.onEnter(self)
    self:runCsbAction("idle", true)
end

function QuestShowTop:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    -- 尝试重新连接 network
    if name == "btn_close" then
        self:closeUI(
            function()
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
            end
        )
    elseif name == "btn_letsgo" or name == "btn_rank" then
        local questConfig = self:getData()
        if questConfig ~= nil then
            questConfig.m_isAutoShowTop = true
        end
        gLobalSendDataManager:getLogQuestActivity():sendQuestEntrySite("topActToQuestMain")
        self:closeUI(
            function()
                G_GetMgr(ACTIVITY_REF.Quest):showMainLayer()
            end
        )
    end
end

-- 获取数据
function QuestShowTop:getData()
    return G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
end

return QuestShowTop
