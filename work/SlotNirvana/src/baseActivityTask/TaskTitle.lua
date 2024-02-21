--[[
    任务界面标题
]]
-- ios fix
local TaskTitle = class("TaskTitle", util_require("base.BaseView"))

function TaskTitle:initUI(_csbName,_titleIndex)
    self:createCsbNode(_csbName)

    self:setTitleShow(_titleIndex)

    self:runCsbAction("idle",true)
end

function TaskTitle:setTitleShow(_titleIndex)
    for i=1, 3 do 
        local titleSp = self:findChild("sp_title" .. i)
        local saoguang = self:findChild("ef_saoguang_" .. i)
        if titleSp then 
            titleSp:setVisible(_titleIndex == i)
        end
        if saoguang then 
            saoguang:setVisible(_titleIndex == i)
        end
    end
end

return TaskTitle