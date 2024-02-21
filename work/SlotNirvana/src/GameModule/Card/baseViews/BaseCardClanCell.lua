--[[
    author:{author}
    time:2019-07-08 14:28:18
]]
local BaseView = util_require("base.BaseView")
local BaseCardClanCell = class(BaseCardClanCell, BaseView)
-- 初始化UI --
function BaseCardClanCell:initUI()
    self:createCsbNode(self:getCsbName())
end

-- 重写
function BaseCardClanCell:getCsbName()
    return ""
end

--是否可以翻页，动画播放过程中不允许翻页（策划需求）
function BaseCardClanCell:getMovePageFlag()
    return true
end

function BaseCardClanCell:getClanData()
    local clansData = CardSysRuntimeMgr:getAlbumTalbeviewData()
    return clansData and clansData[self.m_index]
end

function BaseCardClanCell:updateCell(index)
    self.m_index = index
    self.m_clansData = self:getClanData()
    if not self.m_clansData then
        -- 如果出现这种情况即为不合理情况，查看服务器数据
        return
    end
end

function BaseCardClanCell:showLinkTip(tempNode, linkCount)
    local linkTipView = tempNode:getChildByName("linkTip")
    if linkCount > 0 then
        if not linkTipView then
            linkTipView = util_createView("GameModule.Card.views.BaseCardClanCellLinkTip")
            linkTipView:setName("linkTip")
            tempNode:addChild(linkTipView)
            linkTipView:setPosition(cc.p(110, 0))
        end
        linkTipView:setVisible(true)
    else
        local linkTipView = tempNode:getChildByName("linkTip")
        if linkTipView then
            linkTipView:setVisible(false)
        end
    end
end

function BaseCardClanCell:canClick()
    return true
end

function BaseCardClanCell:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if not self:canClick() then
        return
    end
end

return BaseCardClanCell
