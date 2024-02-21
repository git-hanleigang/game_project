--[[
Author: ZKK
Description: 比赛聚合 宣传活动 数据
--]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local BattleMatchRuleData = class("BattleMatchRuleData", BaseActivityData)

function BattleMatchRuleData:ctor()
    BattleMatchRuleData.super.ctor(self)
    self.p_open = true
end

-- 是否可显示弹板
function BattleMatchRuleData:isCanShowPopView()
    if not BattleMatchRuleData.super.isCanShowPopView(self) then
        return false
    end

    local mrg = G_GetMgr(ACTIVITY_REF.BattleMatch_Rule)
    if mrg then
        return mrg:isRunning() 
    end

    return true
end

return BattleMatchRuleData