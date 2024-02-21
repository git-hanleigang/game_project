---
--island
--2017年8月28日
--JungleJauntSlotsNode.lua
--

local JungleJauntSlotsNode = class("JungleJauntSlotsNode",util_require("Levels.SlotsNode"))

---
-- 运行节点动画
-- @param animName string 节点里面动画名字

function JungleJauntSlotsNode:runAnim(animName,loop,func)
    if not self.p_symbolType then
        if type(func) == "function" then
            func()
        end
        return
    end
  
    local ccbNode = self:checkLoadCCbNode()
    if not tolua.isnull(ccbNode.m_spineNode) then
        ccbNode:resetTimeLine()
    end

    JungleJauntSlotsNode.super.runAnim(self,animName,loop,func)
end


return JungleJauntSlotsNode