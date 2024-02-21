-- quest 排行榜推送面板 基类

local QuestNewShowTop = class("QuestNewShowTop", BaseLayer)

function QuestNewShowTop:initDatas(csbName)
    self:setLandscapeCsbName(csbName)
    self:setPauseSlotsEnabled(true)
end

function QuestNewShowTop:initCsbNodes()
    self.m_btnClose = self:findChild("btn_close")
    -- assert(self.m_btnClose, "QuestNewShowTop 缺少必要的资源节点1")

    self.m_btnLetsgo = self:findChild("btn_letsgo")
    -- assert(self.m_btnLetsgo, "QuestNewShowTop 缺少必要的资源节点2")

    self:setButtonLabelContent("btn_rank", "SEE MY RANK")
    self:startButtonAnimation("btn_rank", "breathe", true)
end

function QuestNewShowTop:onKeyBack()
    self:closeUI(
        function()
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end
    )
end

function QuestNewShowTop:onEnter()
    QuestNewShowTop.super.onEnter(self)
    self:runCsbAction("idle", true)
end

function QuestNewShowTop:clickFunc(sender)
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
        G_GetMgr(ACTIVITY_REF.QuestNew):setWillAutoShowRankLayer(true)
        gLobalSendDataManager:getLogQuestNewActivity():sendQuestEntrySite("topActToQuestMain")
        self:closeUI(
            function()
                G_GetMgr(ACTIVITY_REF.QuestNew):showMainLayer()
            end
        )
    end
end

-- 获取数据
function QuestNewShowTop:getData()
    return G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
end

return QuestNewShowTop
