--
--大厅关卡下载中
--
local LevelDownloadNode = class("LevelDownloadNode", util_require("base.BaseView"))
LevelDownloadNode.m_contentLenX = nil
LevelDownloadNode.m_contentLenY = nil

function LevelDownloadNode:initUI(path)
    self.m_content = util_createSprite(path)
    self:addChild(self.m_content)
    local size = self.m_content:getContentSize()
    self.m_contentLenX = size.width * 0.5
    self.m_contentLenY = size.height * 0.5
end

function LevelDownloadNode:getContentLen()
    return self.m_contentLenX, self.m_contentLenY
end

function LevelDownloadNode:getOffsetPosX()
    return self.m_contentLenX
end

function LevelDownloadNode:updateUI()
end

return LevelDownloadNode
