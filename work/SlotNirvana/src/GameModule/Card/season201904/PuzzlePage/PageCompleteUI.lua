--[[
    集齐界面
]]

local BaseView = util_require("base.BaseView")
local PageCompleteUI = class("PageCompleteUI", BaseView)

function PageCompleteUI:initUI()
    local maskUI = util_newMaskLayer()
    self:addChild(maskUI,-1)
    maskUI:setOpacity(192)

    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self:createCsbNode(CardResConfig.PuzzlePageCompleteRes, isAutoScale)

    self.m_puzzleItemNode = self:findChild("node_puzzleCard")
end

function PageCompleteUI:getPuzzleItemNode()
    return self.m_puzzleItemNode    
end

function PageCompleteUI:playStart(overFunc)
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
        if overFunc then
            overFunc()
        end
    end)
end

function PageCompleteUI:closeUI(closeCall)
    if self.m_closed then
        return
    end
    self.m_closed = true
    self:runCsbAction("over", false, function()
        if closeCall then
            closeCall()
        end
        self:removeFromParent()
    end)
end

return PageCompleteUI