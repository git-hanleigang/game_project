--
--大厅返回最前端按钮节点
--
local BackFrontNode = class("BackFrontNode", util_require("base.BaseView"))

function BackFrontNode:initDatas()
    self.m_isShow = false
    self.m_isCollectLevel = false
end

function BackFrontNode:initUI()
    self:createCsbNode("GameNode/BackButton.csb")
end

function BackFrontNode:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_back" then
        self:playClose()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_CLICK_BACKFRONT)
    end
end

function BackFrontNode:playOpen()
    if self.m_isCollectLevel then
        return
    end
    if self.m_isShow then
        return
    end
    self:setVisible(true)
    self:setIsShow(true)
    self:runCsbAction(
        "open",
        false,
        function()
            if self.m_isShow then
                self:playIdle()
            end
        end,
        60
    )
end

function BackFrontNode:playIdle()
    self:runCsbAction("idle", true)
end

function BackFrontNode:playClose()
    if not self.m_isShow then
        return
    end
    self:setIsShow(false)
    self:setVisible(false)
end

function BackFrontNode:getIsShow()
    return self.m_isShow
end

function BackFrontNode:setIsShow(isShow)
    self.m_isShow = isShow
end

-- 在收藏关卡中不现实按钮
function BackFrontNode:setIsCollectLevel(_isCollectLevel)
    self.m_isCollectLevel = _isCollectLevel
end

return BackFrontNode
