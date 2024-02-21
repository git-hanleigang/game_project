local BaseView = util_require("base.BaseView")
local CardLinkProgressMark = class("CardLinkProgressMark", BaseView)

function CardLinkProgressMark:getCsbName()
    return string.format(CardResConfig.commonRes.linkProgressMark201903, "common" .. CardSysRuntimeMgr:getCurAlbumID())
end

function CardLinkProgressMark:getPreStr()
    return "*"
end

function CardLinkProgressMark:initUI(showIndex, markIndex, num)
    self.m_showIndex = showIndex
    self.m_markIndex = markIndex
    self.m_num = num

    self:createCsbNode(self:getCsbName())

    self.m_markNodeList = {}
    for i = 1, 5 do
        self.m_markNodeList[i] = self:findChild("Node_" .. i)
    end

    local preStr = self:getPreStr()
    for i = 1, #self.m_markNodeList do
        local markNode = self.m_markNodeList[i]
        if i == self.m_showIndex then
            markNode:setVisible(true)
            local indexLb = markNode:getChildByName("Node_shuzi1"):getChildByName("BitmapFontLabel_1")
            local numLb = markNode:getChildByName("shuzi_1")
            indexLb:setString(self.m_markIndex)
            numLb:setString(preStr .. self.m_num)
        else
            markNode:setVisible(false)
        end
    end

    self:runCsbAction("idle")
end

function CardLinkProgressMark:showMark(current, isPlay)
    if self.m_markIndex < current then
        self:runCsbAction("idle2")
    elseif self.m_markIndex == current then
        if isPlay then
            self:runCsbAction(
                "change",
                false,
                function()
                    self:runCsbAction("idle2")
                end
            )
        else
            self:runCsbAction("idle2")
        end
    end
end

return CardLinkProgressMark
