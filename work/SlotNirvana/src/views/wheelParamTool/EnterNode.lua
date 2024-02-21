local EnterNode = class("EnterNode", util_require("base.BaseView"))

function EnterNode:initUI()
    self:createCsbNode("wheelParamTool/EnterNode.csb")
end

function EnterNode:clickFunc(sender)

    local name = sender:getName()
    local tag = sender:getTag()
    if name=="Button_1" then
        local view = util_createView("views.wheelParamTool.WheelParamTool")
        gLobalViewManager:showUI(view,ViewZorder.ZORDER_UI)
    end
end

return EnterNode