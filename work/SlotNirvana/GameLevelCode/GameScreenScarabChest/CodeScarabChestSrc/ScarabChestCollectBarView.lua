---
--xcyy
--2018年5月23日
--ScarabChestCollectBarView.lua
local PublicConfig = require "ScarabChestPublicConfig"
local ScarabChestCollectBarView = class("ScarabChestCollectBarView",util_require("Levels.BaseLevelDialog"))
ScarabChestCollectBarView.m_totalCount = 3
ScarabChestCollectBarView.m_curCollectCount = 0
ScarabChestCollectBarView.m_isTrigger = false

function ScarabChestCollectBarView:initUI(_machine)

    self:createCsbNode("ScarabChest_baoxiang_shoujilan.csb")

    self.m_machine = _machine

    self:runCsbAction("idleframe", true)

    self.m_collectNodeCellTbl = {}
    for i=1, self.m_totalCount do
        local nodeCell = util_createAnimation("ScarabChest_baoxiang_zhu.csb")
        nodeCell:runCsbAction("idleframe", true)
        self:findChild("Node_shouji_"..i):addChild(nodeCell)
        self.m_collectNodeCellTbl[i] = nodeCell
    end
end

-- 落地收集wild
function ScarabChestCollectBarView:collectWildNode(_curCol)
    local curCol = _curCol
    self.m_curCollectCount = self.m_curCollectCount + 1
    if self.m_curCollectCount > self.m_totalCount then
        self.m_curCollectCount = self.m_totalCount
    end
    local curCollectCount = self.m_curCollectCount
    if not self.m_isTrigger then
        util_resetCsbAction(self.m_collectNodeCellTbl[curCollectCount].m_csbAct)
        self.m_collectNodeCellTbl[curCollectCount]:runCsbAction("idleframe1", false, function()
            self.m_collectNodeCellTbl[curCollectCount]:runCsbAction("idleframe2", true)
        end)
        -- 触发
        if self.m_curCollectCount == self.m_totalCount and self.m_machine:isTriggerBonus() then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Base_Add_EndCollectCount)
            self:playTrigger()
        end
    end
end

-- 开始spin重置
function ScarabChestCollectBarView:resetCollectWild()
    self.m_isTrigger = false
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("idleframe", true)
    for i=1, self.m_curCollectCount do
        util_resetCsbAction(self.m_collectNodeCellTbl[i].m_csbAct)
        self.m_collectNodeCellTbl[i]:runCsbAction("idleframe3", false, function()
            self.m_collectNodeCellTbl[i]:runCsbAction("idleframe", true)
        end)
    end
    self.m_curCollectCount = 0
end

-- 触发
function ScarabChestCollectBarView:playTrigger()
    self.m_isTrigger = true
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("actionframe", true)
    for i=1, #self.m_collectNodeCellTbl do
        if i <= self.m_curCollectCount then
            util_resetCsbAction(self.m_collectNodeCellTbl[i].m_csbAct)
            self.m_collectNodeCellTbl[i]:runCsbAction("idleframe4", false, function()
                self.m_collectNodeCellTbl[i]:runCsbAction("idleframe6", true)
            end)
        end
    end
end

-- 没有连线，取消触发
function ScarabChestCollectBarView:isNotBonusCancelCollectAct()
    if self.m_isTrigger then
        util_resetCsbAction(self.m_csbAct)
        self:runCsbAction("actionframe2", false, function()
            self:runCsbAction("idleframe", true)
        end)

        for i=1, self.m_curCollectCount do
            util_resetCsbAction(self.m_collectNodeCellTbl[i].m_csbAct)
            self.m_collectNodeCellTbl[i]:runCsbAction("idleframe2", true)
        end
    end
end

-- spin关闭收集的点
function ScarabChestCollectBarView:closeCollectCell()
    for i=1, self.m_curCollectCount do
        util_resetCsbAction(self.m_collectNodeCellTbl[i].m_csbAct)
        self.m_collectNodeCellTbl[i]:runCsbAction("idleframe7", false, function()
            self.m_collectNodeCellTbl[i]:runCsbAction("idleframe", true)
        end)
    end
end

return ScarabChestCollectBarView
