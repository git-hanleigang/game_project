---
--xcyy
--2018年5月23日
--MayanMysteryRespinWenAnView.lua
local MayanMysteryRespinWenAnView = class("MayanMysteryRespinWenAnView",util_require("base.BaseView"))

function MayanMysteryRespinWenAnView:initUI()

    self:createCsbNode("MayanMystery_respin_xiao_tb.csb")

    self.m_skipNode = cc.Node:create()
    self:findChild("Node_1"):addChild(self.m_skipNode, 100)

    self:addClick(self:findChild("Panel_click"))
end

function MayanMysteryRespinWenAnView:setCallBack(_func)
    self.m_isCanClick = false
    self.m_callBack = _func
end

function MayanMysteryRespinWenAnView:palyStartAnim()
    self:runCsbAction("start", false, function()
        self.m_isCanClick = true
        self:runCsbAction("idle", false)
        performWithDelay(self.m_skipNode,function()
            self.m_isCanClick = false
            self:runCsbAction("over", false, function()
                if self.m_callBack then
                    self.m_callBack()
                end
            end)
        end, 2.5)
    end)
end

function MayanMysteryRespinWenAnView:clickFunc(sender)
    print("点击文本")
    local name,tag = sender:getName(),sender:getTag()
    if name ~= "Panel_click" or not self.m_isCanClick then
        return
    end
    print("点击文本成功")
    self.m_skipNode:stopAllActions()

    self.m_isCanClick = false
  
    self:runCsbAction("over", false, function()
        if self.m_callBack then
            self.m_callBack()
        end
    end)
end

return MayanMysteryRespinWenAnView