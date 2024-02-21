---
--xcyy
--2018年5月23日
--HogHustlerMapRole.lua

local HogHustlerMapRole = class("HogHustlerMapRole",util_require("Levels.BaseLevelDialog"))
local HogHustlerMusic = util_require("CodeHogHustlerSrc.HogHustlerMusic")

local map_type = {

    -- {1,1,1,1,1,1,1, 1,3,3,3,3,2, 2,2,2,2,2,2,2,2,2,2,  2}, --第一张地图

    -- {1,1,1,1,1,1,1,1,1,1,  1,3,3,3,3,3,3,  2,2,2,2,2,2,2,2,2,2,2,2,2,2, 2}, --第二张地图

    -- {1,1,1,1,1,1,1,1,1,1,1,1, 1,3,3,3,3,3,3,3,3,  2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, 2,1,1}  --第三张地图

    {1,1,1,1,1,1,1, 1,3,3,3,3,2, 2,2,2,2,2,2,2,2,2,2,  2}, --第一张地图

    {1,1,1,1,1,1,1,1,1,1,  1,3,3,3,3,3,2,  2,2,2,2,2,2,2,2,2,2,2,2,2,2, 2}, --第二张地图

    {1,1,1,1,1,1,1,1,1,1,1,1, 1,3,3,2,3,3,3,3,3,  2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, 2,1,1}  --第三张地图

}


function HogHustlerMapRole:initUI(data)
    self.m_mapIndex = data.mapIndex
    self.m_posIndex = data.posIndex
    self:createCsbNode("HogHustler_map_zhu.csb")
    self.m_roleNode = util_spineCreate("Socre_HogHustler_juese", true, true)
    -- self.m_roleNode = util_spineCreate("Socre_SmellyRich_juese", true, true)
    self:findChild("role"):addChild(self.m_roleNode)
    self:findChild("role"):setPosition(cc.p(0,60))
    -- self.m_roleAni_node = cc.Node:create()  --角色动作的节点
    -- self:addChild(self.m_roleAni_node)
    self:initRoleType()
    self:showStartIdle()
end

function HogHustlerMapRole:onEnter()
    HogHustlerMapRole.super.onEnter(self)
    self:setLocalZOrder(200)
end

function HogHustlerMapRole:onExit()
    HogHustlerMapRole.super.onExit(self)
end

function HogHustlerMapRole:initRoleType()
    local roleType = map_type[self.m_mapIndex]
    local curType = roleType[self.m_posIndex]
    if curType == 3 then
        curType = 1
    end
    self.m_curType = curType
    if curType == 2 then
        self:setScaleX(-1)
    else
        self:setScaleX(1)
    end
end

function HogHustlerMapRole:showStartIdle()
    --self.m_roleAni_node:removeAllChildren()


    util_spinePlay(self.m_roleNode, "D_huishou")
    util_spineEndCallFunc(self.m_roleNode, "D_huishou", function()
        util_spinePlay(self.m_roleNode, "D_startidle", true)
    end)
end

function HogHustlerMapRole:playRoleIdle()
    util_spinePlay(self.m_roleNode, "D_idle", true)
end

function HogHustlerMapRole:playRun()
    util_spinePlay(self.m_roleNode, "D_paostart")
    util_spineEndCallFunc(self.m_roleNode, "D_paostart", function()
        util_spinePlay(self.m_roleNode, "D_paoidle", true)
    end)
end

function HogHustlerMapRole:playRunOver()
    util_spinePlay(self.m_roleNode, "D_paoOver")
    util_spineEndCallFunc(self.m_roleNode, "D_paoOver", function()
        self:playRoleIdle()
    end)
end

--设置
function HogHustlerMapRole:setRoleType(mapIndex, posIndex)
    local roleType = map_type[mapIndex]
    local curType = roleType[posIndex]
    if curType == self.m_curType then
        return
    end
    if curType == 3 then
    end
    if curType == 2 then
        self:setScaleX(-1)
    else
        self:setScaleX(1)
    end
    self.m_curType = curType
end

function HogHustlerMapRole:roelGreed()
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_role_celebratejump)

    util_spinePlay(self.m_roleNode, "D_tanqian")
    util_spineEndCallFunc(self.m_roleNode, "D_tanqian", function()
        util_spinePlay(self.m_roleNode, "D_tanqian")
        util_spineEndCallFunc(self.m_roleNode, "D_tanqian", function()
            self:playRoleIdle()
        end)
    end)
end

--延时
function HogHustlerMapRole:waitWithDelay(time, endFunc, parent)
    time = time or 0
    if time == 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    if parent then
        parent:addChild(waitNode)
    else
        self:addChild(waitNode)
    end
    performWithDelay(waitNode, function(  )
        if endFunc then
            endFunc()
        end
        waitNode:removeFromParent()
    end, time)
end

return HogHustlerMapRole