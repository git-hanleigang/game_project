--[[

--]]
local SpinGetItem = class("SpinGetItem", BaseActivityControl)

function SpinGetItem:ctor()
    SpinGetItem.super.ctor(self)
    self:setRefName(G_REF.SpinGetItem)
end

-- icon个数，道具个数
function SpinGetItem:getSlotData()
    if G_GetMgr(ACTIVITY_REF.SpinItem):getRunningData() then 
        return G_GetMgr(ACTIVITY_REF.SpinItem):getSlotData()
    end

    if G_GetMgr(ACTIVITY_REF.Coloring):getRunningData() then 
        return G_GetMgr(ACTIVITY_REF.Coloring):getSlotPaintData()
    end
end

function SpinGetItem:clearSlotData()
    if G_GetMgr(ACTIVITY_REF.SpinItem):getRunningData() then 
        return G_GetMgr(ACTIVITY_REF.SpinItem):clearSlotData()
    end

    if G_GetMgr(ACTIVITY_REF.Coloring):getRunningData() then 
        return G_GetMgr(ACTIVITY_REF.Coloring):clearSlotPaintData()
    end
end

-- 角标资源
function SpinGetItem:getLevelLogoRes()
    if G_GetMgr(ACTIVITY_REF.SpinItem):getRunningData() then 
        return G_GetMgr(ACTIVITY_REF.SpinItem):getLevelLogoRes()
    end

    if G_GetMgr(ACTIVITY_REF.Coloring):getRunningData() then 
        return G_GetMgr(ACTIVITY_REF.Coloring):getLevelLogoRes()
    end
end

-- 角标动作节点
function SpinGetItem:getLevelLogoNode()
    if G_GetMgr(ACTIVITY_REF.SpinItem):getRunningData() then 
        return G_GetMgr(ACTIVITY_REF.SpinItem):getLevelLogoNode()
    end

    if G_GetMgr(ACTIVITY_REF.Coloring):getRunningData() then 
        return G_GetMgr(ACTIVITY_REF.Coloring):getLevelLogoNode()
    end
end


function SpinGetItem:getLevelHeipingNode()
    if G_GetMgr(ACTIVITY_REF.SpinItem):getRunningData() then 
        return G_GetMgr(ACTIVITY_REF.SpinItem):getLevelHeipingNode()
    end

    if G_GetMgr(ACTIVITY_REF.Coloring):getRunningData() then 
        return G_GetMgr(ACTIVITY_REF.Coloring):getLevelHeipingNode()
    end
end

function SpinGetItem:getActivityData()
    if G_GetMgr(ACTIVITY_REF.SpinItem):getRunningData() then 
        return G_GetMgr(ACTIVITY_REF.SpinItem):getRunningData()
    end

    if G_GetMgr(ACTIVITY_REF.Coloring):getRunningData() then 
        return G_GetMgr(ACTIVITY_REF.Coloring):getRunningData()
    end
end

return SpinGetItem
