--[[--
    行尸走肉预热活动
]]

-- 加载配置
util_require("activities.Activity_Zombie_WarmUp.config.ZombieWarmUpCfg")
-- 
local ZombieWarmUpMgr = class("ZombieWarmUpMgr", BaseActivityControl)

function ZombieWarmUpMgr:ctor()
    ZombieWarmUpMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ZombieWarmUp)
end

-- function ZombieWarmUpMgr:showMainLayer()
--     if gLobalViewManager:getViewByExtendData("Activity_Zombie_WarmUp") ~= nil then
--         return
--     end

--     if not self:isCanShowLayer() then
--         return
--     end

--     G_GetNetModel(NetType.ZombieWarmUp):requestZombie("Config", 
--         function()
--             local view = util_createView("Activity.Activity_Zombie_WarmUp")
--             if view then
--                 self:showLayer(view)
--             end
--         end
--     )
-- end

-- 显示大厅弹板
function ZombieWarmUpMgr:showPopLayer(popInfo, callback)
    if popInfo.clickFlag == true then
        G_GetNetModel(NetType.ZombieWarmUp):requestZombie(
            "Config", 
            function()
                ZombieWarmUpMgr.super.showPopLayer(self, popInfo, callback)
            end
        )
    else
        return ZombieWarmUpMgr.super.showPopLayer(self, popInfo, callback)
    end
end

return ZombieWarmUpMgr
