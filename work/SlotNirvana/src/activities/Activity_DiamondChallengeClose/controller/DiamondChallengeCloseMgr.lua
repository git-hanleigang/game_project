
local DiamondChallengeCloseMgr = class("DiamondChallengeCloseMgr", BaseActivityControl)

-- 需要随机的 主题后缀 index 对应工程里面
local randomIndexCommunityVec = {
    1,
    2
}

function DiamondChallengeCloseMgr:ctor()
    DiamondChallengeCloseMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DiamondChallengeClose)
   
end

function DiamondChallengeCloseMgr:showMainLayer(data)
    if not self:isCanShowLayer() then
        return nil
    end
    
    local uiView = util_createFindView("Activity/Activity_FBGroup", data)
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_POPUI)
    return uiView
end

return DiamondChallengeCloseMgr
