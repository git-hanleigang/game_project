--
--大厅关卡滑动配置
--
local BaseScroll = util_require "base.BaseScroll"
local LevelScrollControl = class("LevelScrollControl", BaseScroll)
function LevelScrollControl:move(x, secs)
    --新手引导相关
    -- if globalNoviceGuideManager.current_info then
    --     local info = globalNoviceGuideManager.current_info
    --     if info.id == NOVICEGUIDE_ORDER.comeCust.id then
    --         return
    --     end
    -- end
    BaseScroll.move(self, x, secs)
end

return LevelScrollControl
-- endregion
