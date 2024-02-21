--[[--
    家具配置表数据
]]
local RedecorSimpleTreasureData = import(".RedecorSimpleTreasureData")
local RedecorNodeConfig = class("RedecorNodeConfig")

--     "id"
--     optional int32 nodeId = 1;    //节点id
--     optional string name = 2; //名称
--     repeated string spine = 4;    //资源
--     optional string thumbnail = 5;    //缩略图
--     optional int32 quadrant = 6;    //象限
--     optional int32 style = 7;    //风格数量
--     repeated int32 prevNode = 8;    //父节点
--     optional int32 videoType = 9;    //动效类型
--     optional int32 videoInterval = 10;    //动效间隔
--     repeated int32 layer = 11;    //层级
--     optional string effects = 17;    //粒子特效
--     optional string refName = 18;    //引用名
--     optional int32 longPress = 19;    //长按
--     optional int32 shortPress = 20;    //短按

function RedecorNodeConfig:parseData(_cfgData)
    self.p_id = _cfgData[1]
    self.p_nodeId = _cfgData[2]
    self.p_name = _cfgData[3]

    self.p_spines = {}
    if _cfgData[4] and _cfgData[4] ~= "" then
        local spines = string.split(_cfgData[4], ";")
        for i = 1, #spines do
            table.insert(self.p_spines, spines[i])
        end
    end

    self.p_thumbnail = _cfgData[5]
    self.p_quadrant = _cfgData[6]
    self.p_style = _cfgData[7]

    self.p_prevNode = {}
    if _cfgData[8] and _cfgData[8] ~= "" then
        local prevNodes = string.split(_cfgData[8], ";")
        for i = 1, #prevNodes do
            table.insert(self.p_prevNode, prevNodes[i])
        end
    end

    self.p_videoType = _cfgData[9]
    self.p_videoInterval = _cfgData[10]

    self.p_layer = {}
    if _cfgData[11] and _cfgData[11] ~= "" then
        local layers = string.split(_cfgData[11], ";")
        for i = 1, #layers do
            table.insert(self.p_layer, layers[i])
        end
    end
    self.p_effectStr = _cfgData[12]
    self:splitEffectStr()
    self.p_refName = _cfgData[13]
    self.p_longPress = _cfgData[14]
    self.p_shortPress = _cfgData[15]
end

-- 节点id
function RedecorNodeConfig:getNodeId()
    return self.p_nodeId
end
-- 名称
function RedecorNodeConfig:getName()
    return self.p_name
end
-- 资源
function RedecorNodeConfig:getSpines()
    return self.p_spines
end
-- 缩略图
function RedecorNodeConfig:getThumbnail()
    return self.p_thumbnail
end
-- 象限
function RedecorNodeConfig:getQuadrant()
    return self.p_quadrant
end
-- 风格数量
function RedecorNodeConfig:getStyleNum()
    return self.p_style
end
-- 父节点
function RedecorNodeConfig:getPrevNode()
    return self.p_prevNode
end
-- 动效类型
function RedecorNodeConfig:getVideoType()
    return self.p_videoType
end
-- 动效间隔
function RedecorNodeConfig:getVideoInterval()
    return self.p_videoInterval
end
-- 层级
function RedecorNodeConfig:getLayer()
    return self.p_layer
end
-- 粒子特效
function RedecorNodeConfig:getEffectStr()
    return self.p_effectStr
end
function RedecorNodeConfig:getEffects()
    return self.p_effects
end
function RedecorNodeConfig:splitEffectStr()
    self.p_effects = {}
    self:getEffectStr()
    local effects = string.split(self.p_effectStr, ";")
    for i = 1, #effects do
        local effs = string.split(effects[i], "|")
        local delays = string.split(effs[2], "-")
        self.p_effects[effs[1]] = delays
    end
end
-- 引用名
function RedecorNodeConfig:getRefName()
    return self.p_refName
end
function RedecorNodeConfig:getLongPress()
    return self.p_longPress
end
function RedecorNodeConfig:getShortPress()
    return self.p_shortPress
end

return RedecorNodeConfig
