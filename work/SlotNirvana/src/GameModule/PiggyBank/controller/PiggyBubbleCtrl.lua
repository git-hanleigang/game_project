--[[--
    右上角小猪气泡
]]
local CFG_BUBBLES = {
    ["LevelUp"] = {
        luaName = "PiggyBubble_LevelUp",
        luaPath = "views.piggy.top.PiggyBubble_LevelUp",
        refName = G_REF.PiggyBank
    },
    ["Max"] = {
        luaName = "PiggyBubble_Max",
        luaPath = "views.piggy.top.PiggyBubble_Max",
        refName = G_REF.PiggyBank
    },
    ["Unlock"] = {
        luaName = "PiggyBubble_Unlock",
        luaPath = "views.piggy.top.PiggyBubble_Unlock",
        refName = G_REF.PiggyBank
    },
    ["ChipMax"] = {
        luaName = "PiggyBubble_ChipMax",
        luaPath = "Activity_ChipPiggy.PiggyBubble_ChipMax",
        refName = ACTIVITY_REF.ChipPiggy
    },
    ["GemMax"] = {
        luaName = "PiggyBubble_GemMax",
        luaPath = "Activity_GemPiggy.PiggyBubble_GemMax",
        refName = ACTIVITY_REF.GemPiggy
    }
}

local PiggyBubbleCtrl = class("PiggyBubbleCtrl", BaseSingleton)

function PiggyBubbleCtrl:ctor()
    self:clearData()
end

function PiggyBubbleCtrl:clearData()
    self.m_position = nil
    self.m_popList = {}
    self.m_isShowing = false
    self.m_curKey = ""
end

function PiggyBubbleCtrl:pushTipList(_info)
    table.insert(self.m_popList, _info)
end

function PiggyBubbleCtrl:popTipList()
    local info = table.remove(self.m_popList, 1)
    return info
end

function PiggyBubbleCtrl:setBubblePosition(_worldPos)
    self.m_position = _worldPos
end

-- 检测是否可以弹出
function PiggyBubbleCtrl:checkCanPop(_key)
    if self.m_curKey == _key then
        return false
    end

    for _, _v in ipairs(self.m_popList) do
        if _v == _key then
            return false
        end
    end

    return true
end

function PiggyBubbleCtrl:showTip(_key)
    if not self:checkCanPop(_key) then
        return
    end

    if self.m_isShowing == true then
        self:pushTipList(_key)
        return
    end
    return self:popTip(_key)
end

function PiggyBubbleCtrl:popTip(_key)
    if not gLobalViewManager:isLevelView() then
        return false
    end
    if not self.m_position then
        return false
    end
    -- -- 隐藏其他
    -- for k, v in pairs(CFG_BUBBLES) do
    --     if k ~= _key then
    --         self:hideTip(k)
    --     end
    -- end
    -- 显示
    local bubbleCfg = CFG_BUBBLES[_key]
    if not bubbleCfg then
        return false
    end
    local mgr = G_GetMgr(bubbleCfg.refName)
    if not (mgr and mgr.createPiggyTip) then
        return false
    end
    
    local tip = mgr:createPiggyTip(bubbleCfg.luaName, bubbleCfg.luaPath, ViewZorder.ZORDER_UI_LOWER, self.m_position)
    -- local tip = gLobalViewManager:getViewByName(bubbleCfg.luaName)
    -- if tip == nil then
    --     tip = util_createView(bubbleCfg.luaPath)
    --     gLobalViewManager:getViewLayer():addChild(tip, ViewZorder.ZORDER_UI_LOWER)
    --     tip:setPosition(cc.p(self.m_position.x, self.m_position.y))
    -- end
    if tip then
        self.m_isShowing = true
        self.m_curKey = _key
        tip:playStart()
    end
    return true
end

function PiggyBubbleCtrl:showNextTip()
    self.m_curKey = ""
    if table.nums(self.m_popList) == 0 then
        self.m_isShowing = false
        return
    end
    local key = self:popTipList()
    self:popTip(key)
end


-- function PiggyBubbleCtrl:hideTip(_key)
--     local bubbleCfg = CFG_BUBBLES[_key]
--     local tip = gLobalViewManager:getViewByName(bubbleCfg.luaName)
--     if tip ~= nil then
--         if tip:isShowing() then
--             tip:closeUI()
--         end
--     end
-- end

return PiggyBubbleCtrl
