--[[
    合成pass
]]

local MergePassLayerMgr = class("MergePassLayerMgr", BaseActivityControl)

function MergePassLayerMgr:ctor()
    MergePassLayerMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.MergePassLayer)
end

function MergePassLayerMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function MergePassLayerMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function MergePassLayerMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

return MergePassLayerMgr
