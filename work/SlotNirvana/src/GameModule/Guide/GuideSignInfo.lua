--[[
    引导标记信号（高亮）节点信息
    time:2022-09-02 10:38:50
]]
GD.GuideSignType = {
    Up = "up",
    Clip = "clip"
}

local GuideSignInfo = class("GuideSignInfo")

function GuideSignInfo:ctor()
    -- 当前信号id
    self.m_signId = nil
    -- lua名称
    self.m_luaName = ""
    -- 节点名称
    self.m_nodeName = ""
    -- 标记信号类型(默认抬起)
    self.m_type = GuideSignType.Up
    -- 资源路径
    self.m_resPath = ""
    -- 标记信号大小
    self.m_nodeSize = cc.size(0, 0)
    -- 标记信号缩放
    self.m_scale = 1
    -- 信号偏移位置
    self.m_offsetPos = cc.p(0, 0)
    -- 信号锚点位置
    self.m_anchorPos = cc.p(0, 0)
    -- 层级
    self.m_zOrder = 0
    -- 是否阻断响应
    self.m_isBlock = false
end

function GuideSignInfo:parseData(info)
    self.m_signId = info.signId
    -- lua名称
    self.m_luaName = info.luaName
    self.m_zOrder = tonumber(info.zOrder or 0)
    -- self.m_isBlock = info.isBlock or false
    self:setBlock(info.isBlock)
    -- 标记信号类型
    self:setShowType(info.type or GuideSignType.Up)
    -- 节点名称
    self:setNodeName(info.nodeName or "")
    -- 标记信号大小
    self:setSize(info.size or "")
    self:setOffsetPos(info.offset or "")
    -- 节点锚点
    self:setAnchorPos(info.anchor or "")
end

function GuideSignInfo:getSignId()
    return self.m_signId
end

function GuideSignInfo:setBlock(isBlock)
    if type(isBlock) == "string" then
        self.m_isBlock = (isBlock == "true")
    else
        self.m_isBlock = isBlock
    end
end

function GuideSignInfo:getLuaName()
    return self.m_luaName or ""
end

function GuideSignInfo:setNodeName(nodeName)
    nodeName = nodeName or ""
    -- if nodeName ~= "" then
    --     local strs = string.split(nodeName, "|")
    --     self.m_nodeName = strs
    -- end
    self.m_nodeName = nodeName
end

function GuideSignInfo:getNodeName()
    return self.m_nodeName or {}
end

function GuideSignInfo:setShowType(showType)
    local strs = string.split(showType, "|")
    self.m_type = strs[1] or GuideSignType.Up
    self.m_resPath = strs[2] or ""
end

function GuideSignInfo:isType(sType)
    return self.m_type == (sType or "")
end

function GuideSignInfo:getResPath()
    return self.m_resPath or ""
end

function GuideSignInfo:getZOrder()
    return self.m_zOrder or 0
end

function GuideSignInfo:getSize()
    return self.m_nodeSize or cc.size(0, 0)
end

function GuideSignInfo:getScale()
    return self.m_scale or 1
end

function GuideSignInfo:setSize(size)
    size = size or ""
    local strs = string.split(size, "|")
    if #strs >= 2 then
        self.m_nodeSize = cc.size(tonumber(strs[1]), tonumber(strs[2]))
    end
end

function GuideSignInfo:getOffsetPos()
    return self.m_offsetPos or cc.p(0, 0)
end

function GuideSignInfo:setOffsetPos(pos)
    pos = pos or ""
    local strs = string.split(pos, "|")
    if #strs == 2 then
        self.m_offsetPos = cc.p(tonumber(strs[1]), tonumber(strs[2]))
    end
end

function GuideSignInfo:getAnchorPos()
    return self.m_anchorPos or cc.p(0, 0)
end

function GuideSignInfo:setAnchorPos(anchorPos)
    anchorPos = anchorPos or ""
    local strs = string.split(anchorPos, "|")
    if #strs >= 2 then
        self.m_anchorPos = cc.p(tonumber(strs[1]), tonumber(strs[2]))
        self.m_scale = tonumber(strs[3] or 1)
    end
end

function GuideSignInfo:isBlock()
    return self.m_isBlock
end

return GuideSignInfo
