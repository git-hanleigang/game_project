--[[
]]

local BetBubbleRefData = util_require("GameModule.BetBubbles.model.BetBubbleRefData")

local BetBubbleModuleData = class("BetBubbleModuleData")

function BetBubbleModuleData:ctor()
    self.m_isShowing = false
end

function BetBubbleModuleData:parseData(_data)
    self.m_moduleName = _data.moduleName
    self.m_moduleLua = _data.moduleLua
    
    self.m_isLimitMaxH = _data.isLimitMaxH
    
    self.m_refDatas = {}
    if _data.refs and #_data.refs > 0 then
        for i=1,#_data.refs do
            self:addRef(_data.refs[i])
        end
    end

    self.m_zOrder = _data.zOrder
    self.m_zOrderType = _data.zOrderType
end

function BetBubbleModuleData:getModuleName()
    return self.m_moduleName
end
function BetBubbleModuleData:getModuleLua()
    return self.m_moduleLua
end
function BetBubbleModuleData:getRefDatas()
    return self.m_refDatas
end
function BetBubbleModuleData:getZOrder()
    return self.m_zOrder
end
function BetBubbleModuleData:getZOrderType()
    return self.m_zOrderType
end
function BetBubbleModuleData:isLimitMaxH()
    return self.m_isLimitMaxH
end

function BetBubbleModuleData:isTop()
    if self.m_zOrderType == BetBubblesCfg.ZORDER_TYPE.UP then
        return true
    end
    return false
end

function BetBubbleModuleData:isBottom()
    if self.m_zOrderType == BetBubblesCfg.ZORDER_TYPE.DOWN then
        return true
    end
    return false
end

function BetBubbleModuleData:getRefDataByRef(_ref)
    if self.m_refDatas and #self.m_refDatas > 0 then
        for i=1,#self.m_refDatas do
            local refData = self.m_refDatas[i]
            if refData:getRefName() == _ref then
                return refData 
            end
        end
    end
    return
end

function BetBubbleModuleData:getSwitchOnRefDatas()
    local temps = {}
    if self.m_refDatas and #self.m_refDatas > 0 then
        for i=1,#self.m_refDatas do
            local refData = self.m_refDatas[i]
            if refData:isSwitchOn() then
                table.insert(temps, refData)
            end
        end
    end
    return temps
end

function BetBubbleModuleData:hasSwitchOnRef()
    local refs = self:getSwitchOnRefDatas()
    if refs and #refs > 0 then
        return true
    end
    return false
end

function BetBubbleModuleData:addRef(_ref)
    if not self.m_refDatas then
        self.m_refDatas = {}
    end
    local refData = BetBubbleRefData:create()
    refData:parseData(_ref)
    table.insert(self.m_refDatas, refData)
end

function BetBubbleModuleData:delRef(_ref)
    if self.m_refDatas and #self.m_refDatas > 0 then
        for i = #self.m_refDatas, 1, -1 do
            local refData = self.m_refDatas[i]
            if refData:getRefName() == _ref then
                table.remove(self.m_refDatas, i)
                break
            end
        end
    end
end

-- function BetBubbleModuleData:getModuleHeight()
--     local height = 0
--     if self.m_moduleLua and self.m_moduleLua ~= "" then
--         height = self:getViewHeight(self.m_moduleLua)
--     else
--         height = self:getRefsHeight()
--     end
--     return height
-- end

-- function BetBubbleModuleData:getRefsHeight()
--     local height = 0
--     if self.m_refDatas and #self.m_refDatas > 0 then
--         for i=1,#self.m_refDatas do
--             local refData = self.m_refDatas[i]
--             if refData:isSwitchOn() then
--                 height = height + (refData:getHeight() or 0)
--             end
--         end
--     end
--     return height
-- end

-- function BetBubbleModuleData:getViewHeight(_filePath)
--     local height = 0
--     if _filePath and _filePath ~= "" then
--         if util_IsFileExist(_filePath .. ".lua") or util_IsFileExist(_filePath .. ".luac") then
--             _filePath = string.gsub(_filePath, "/", ".")
--             local view = util_createView(_filePath, self.m_refDatas)
--             if view and view.getLabelSize then
--                 local size = view:getLabelSize()
--                 height = size.height or 0
--             end
--         end        
--     end
--     return height
-- end


function BetBubbleModuleData:setShowing(_isShowing)
    self.m_isShowing = _isShowing
end

function BetBubbleModuleData:isShowing()
    return self.m_isShowing
end

return BetBubbleModuleData