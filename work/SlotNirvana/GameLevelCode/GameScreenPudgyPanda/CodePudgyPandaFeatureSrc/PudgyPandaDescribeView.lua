---
--xcyy
--2018年5月23日
--PudgyPandaDescribeView.lua
local PublicConfig = require "PudgyPandaPublicConfig"
local PudgyPandaDescribeView = class("PudgyPandaDescribeView",util_require("Levels.BaseLevelDialog"))
PudgyPandaDescribeView.m_totalNum = 3

function PudgyPandaDescribeView:initUI()

    self:createCsbNode("PudgyPanda_FGshuoming.csb")

    self:runCsbAction("idle", true) -- 播放时间线

    self.m_kuangNodeAniTbl = {}
    for i=1, self.m_totalNum do
        local kuangNode = self:findChild("Node_kuang"..i)
        self.m_kuangNodeAniTbl[i] = util_createAnimation("PudgyPanda_FGshuoming_kuang.csb")
        kuangNode:addChild(self.m_kuangNodeAniTbl[i])
    end
end

-- 设置显示的类型
function PudgyPandaDescribeView:setCurFreeType(_curType)
    for i=1, self.m_totalNum do
        if i == _curType then
            self.m_kuangNodeAniTbl[i]:setVisible(true)
        else
            self.m_kuangNodeAniTbl[i]:setVisible(false)
        end
    end
end

return PudgyPandaDescribeView
