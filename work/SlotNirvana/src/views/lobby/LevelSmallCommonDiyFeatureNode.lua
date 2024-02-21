--[[--
    公共Jackopt在小关卡的标题
]]
local LevelSmallCommonDiyFeatureNode = class("LevelSmallCommonDiyFeatureNode", BaseView)

function LevelSmallCommonDiyFeatureNode:initUI()
    LevelSmallCommonDiyFeatureNode.super.initUI(self)
    self:initView()
end

function LevelSmallCommonDiyFeatureNode:getCsbName()
    return "newIcons/LevelRecmd2023/DiyFeature/DiyFeature_Short.csb"
end

function LevelSmallCommonDiyFeatureNode:initView()
    self:runCsbAction("idle",true)
end

return LevelSmallCommonDiyFeatureNode
