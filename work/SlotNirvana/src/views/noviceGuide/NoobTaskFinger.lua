local NoobTaskFinger=class("NoobTaskFinger",util_require("base.BaseView"))
NoobTaskFinger.info = nil
function NoobTaskFinger:initUI()
    self:createCsbNode("NoviceGuide/NoobTask_xiaoshou.csb")
end

function NoobTaskFinger:onEnter()
    self:runCsbAction("show",false,function (  )
        self:runCsbAction("idle",true)
    end,60)
end
return NoobTaskFinger