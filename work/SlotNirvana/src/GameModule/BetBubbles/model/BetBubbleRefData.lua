--[[
]]
local BetBubbleRefData = class("BetBubbleRefData")

function BetBubbleRefData:ctor()
end

function BetBubbleRefData:parseData(_ref)
    self.m_refName = _ref

    -- 开关 数据解析时默认是开的
    self.m_status = BetBubblesCfg.REF_SWITCH.ON    

    -- local h = self:getLabelHeightByRef(self.m_refName)
    -- self:setHeight(h)
end

function BetBubbleRefData:getRefName()
    return self.m_refName
end

-- function BetBubbleRefData:getHeight()
--     return self.m_height
-- end

-- function BetBubbleRefData:setHeight(_height)
--     self.m_height = _height
-- end

-- function BetBubbleRefData:getLabelHeightByRef(_refName)
--     local height = 0
--     local mgr = G_GetMgr(_refName)
--     if mgr and mgr.getBetBubbleLuaPath then
--         local luaPath = mgr:getBetBubbleLuaPath()
--         if luaPath and luaPath ~= "" then
--             -- if util_IsFileExist(luaPath .. ".lua") or util_IsFileExist(luaPath .. ".luac") then
--             --     luaPath = string.gsub(luaPath, "/", ".")
--             -- end
--             local view = util_createView(luaPath)
--             if view and view.getLabelSize then
--                 local size = view:getLabelSize()
--                 height = size.height or 0
--             end            
--         end
--     end
--     return height
-- end

function BetBubbleRefData:setSwitchStatus(_status)
    self.m_status = _status
end

function BetBubbleRefData:getSwitchStatus()
    return self.m_status
end

function BetBubbleRefData:isSwitchOn()
    return self.m_status == BetBubblesCfg.REF_SWITCH.ON
end

return BetBubbleRefData