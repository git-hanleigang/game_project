--
-- 梦幻 Quest活动主界面
--

local QuestNewChapterChoseInfoView = class("QuestNewChapterChoseInfoView", BaseLayer)

function QuestNewChapterChoseInfoView:ctor()
    QuestNewChapterChoseInfoView.super.ctor(self)
    self:setLandscapeCsbName(QUESTNEW_RES_PATH.QuestNewChapterChoseInfoView)
    self:setExtendData("QuestNewChapterChoseInfoView")
end

function QuestNewChapterChoseInfoView:initCsbNodes()
    self.btn_close = self:findChild("btn_close")
    self.m_canTouch = false

    self.node_info_1 = self:findChild("node_info_1")
    self.node_info_2 = self:findChild("node_info_2")
    self.node_info_3 = self:findChild("node_info_3")

    self.btn_turn_R = self:findChild("btn_turn_R")
    self.btn_turn_L = self:findChild("btn_turn_L")

    self.node_info_1:setVisible(self.m_viewType == 1)
    self.node_info_2:setVisible(self.m_viewType == 2)
    self.node_info_3:setVisible(self.m_viewType == 3)
    self.btn_turn_R:setVisible(self.m_viewType ~= 3)
    self.btn_turn_L:setVisible(self.m_viewType ~= 1)
end

function QuestNewChapterChoseInfoView:initDatas(viewType)
    self.m_viewType = viewType or 1
end
function QuestNewChapterChoseInfoView:initView()
    self:runCsbAction("idle", true, nil, 60)
end

function QuestNewChapterChoseInfoView:changeViewType(isAdd)
    self.m_canTouch = false
    if isAdd then
        self.m_viewType = self.m_viewType + 1
    else
        self.m_viewType = self.m_viewType - 1
    end
    self.node_info_1:setVisible(self.m_viewType == 1)
    self.node_info_2:setVisible(self.m_viewType == 2)
    self.node_info_3:setVisible(self.m_viewType == 3)
    self.btn_turn_R:setVisible(self.m_viewType ~= 3)
    self.btn_turn_L:setVisible(self.m_viewType ~= 1)

    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("idle", true, nil, 60)
            self.m_canTouch = true
        end,
        60
    )
end

function QuestNewChapterChoseInfoView:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
    self.m_canTouch = true
end

function QuestNewChapterChoseInfoView:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_close" then
        self.m_canTouch = false
        self:closeUI()
    elseif name == "btn_turn_R" then
        if not self.m_canTouch then
            return 
        end
        self:changeViewType(true)
    elseif name == "btn_turn_L" then
        if not self.m_canTouch then
            return 
        end
        self:changeViewType(false)
    end
end

return QuestNewChapterChoseInfoView