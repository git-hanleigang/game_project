--[[
    Echo Win
]]

local SaleGroupControl = class("SaleGroupControl", BaseActivityControl)

function SaleGroupControl:ctor()
    SaleGroupControl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.SaleGroup)
end 

-- 休闲干杯主题 新加
function SaleGroupControl:getPopPath(popName)
    if popName == "Activity_SaleGroup_UnDrinking" then
        return popName .. "/" .. popName
    end
    return "Activity/" .. popName  --万圣节2022目录 不改工程逻辑了直接改 路径
end
-- 休闲干杯主题 新加 end

return SaleGroupControl
