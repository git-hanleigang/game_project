--[[
    
    author:{author}
    time:2021-09-28 17:58:50
]]
local RichManShowTopMgr = class("RichManShowTopMgr", BaseActivityControl)

function RichManShowTopMgr:ctor()
    RichManShowTopMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.RichManRank)
    self:addPreRef(ACTIVITY_REF.RichMan)
end

function RichManShowTopMgr:showMainLayer(_bClick)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = G_GetMgr(ACTIVITY_REF.RichMan):showMainLayer({openRankFlag = true})
    if not view and not _bClick then
        self:showPopLayer({})
    end
end

return RichManShowTopMgr
