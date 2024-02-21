---
--xcyy
--2018年5月23日
--WarriorAliceBossItem.lua

local WarriorAliceBossItem = class("WarriorAliceBossItem",util_require("Levels.BaseLevelDialog"))

local showName = {
    "Node_mini",
    "Node_minor",
    "Node_major"
}

function WarriorAliceBossItem:initUI(params)

    self:createCsbNode("WarriorAlice_soldierbig.csb")

    self.boss = util_spineCreate("WarriorAlice_shibing",true,true)
    self:findChild("Node_boss"):addChild(self.boss)

    self.saoGuang = util_spineCreate("WarriorAlice_shibing",true,true)
    self:findChild("Node_saoguang"):addChild(self.saoGuang)
    util_spinePlay(self.saoGuang,"idleframe_saoguang")

    local colIndex = params[1]
    local rowIndex = params[2]
    self.saoGuangNode = cc.Node:create()
    self:addChild(self.saoGuangNode)

    self:showResetAllIttem(rowIndex,colIndex)
end

function WarriorAliceBossItem:showResetAllIttem(rowIndex,colIndex)
    self:hideJackpotAct(true)
    self.saoGuangNode:stopAllActions()
    self:showIdleForIndex(colIndex)
    self:showColorForIndex(colIndex)
    self:showSaoGuang(rowIndex,colIndex)
end

function WarriorAliceBossItem:showResetAllIttemByBoss(rowIndex,colIndex)
    self:hideJackpotAct(true)
    self.saoGuangNode:stopAllActions()
    self:showIdleForIndex(colIndex)
    self:showColorForIndexByBoss(colIndex)
    self:showSaoGuang(rowIndex,colIndex)
end

function WarriorAliceBossItem:showIdleForIndex(colIndex)
    if colIndex == 1 or colIndex == 5 then
        util_spinePlay(self.boss,"idleframe_lv_big")
    elseif colIndex == 2 or colIndex == 4 then
        util_spinePlay(self.boss,"idleframe_lan_big")
    else
        util_spinePlay(self.boss,"idleframe_hong_big")
    end
end

function WarriorAliceBossItem:showColorForIndex(colIndex)

    if colIndex == 1 or colIndex == 5 then
        util_spinePlay(self.boss,"idle_3",true)
    elseif colIndex == 2 or colIndex == 4 then
        util_spinePlay(self.boss,"idle_2",true)
    else
        util_spinePlay(self.boss,"idle_1",true)
    end
end

function WarriorAliceBossItem:showColorForIndexByBoss(colIndex)

    if colIndex == 1 or colIndex == 5 then
        util_spinePlay(self.boss,"actionframe5_lv_big",true)
    elseif colIndex == 2 or colIndex == 4 then
        util_spinePlay(self.boss,"actionframe5_lan_big",true)
    else
        util_spinePlay(self.boss,"actionframe5_hong_big",true)
    end
end

function WarriorAliceBossItem:showSaoGuang(rowIndex,colIndex)
    local function saoGuangForcol(colIndex)
        if colIndex == 1 or colIndex == 5 then
            util_spinePlay(self.saoGuang,"idle5_1")
        elseif colIndex == 2 or colIndex == 4 then
            util_spinePlay(self.saoGuang,"idle4_1")
        else
            util_spinePlay(self.saoGuang,"idle3_1")
        end
    end

    if colIndex == 2 or colIndex == 4 then
        saoGuangForcol(colIndex)
    elseif rowIndex == 1 or colIndex == 3 or colIndex == 5 then
        self:delayCallBack(30/30,function ()
            saoGuangForcol(colIndex)
        end)
    end

    performWithDelay(self.saoGuangNode,function ()
        self:showSaoGuang(rowIndex,colIndex)
    end,3.5)
    
end

function WarriorAliceBossItem:addJackpotToNode(colIndex,jackpotNode)
    self:findChild("node_jackpot"):addChild(jackpotNode)
    if colIndex == 3 then
        jackpotNode:setPositionY(10)
    elseif colIndex == 2 or colIndex == 4 then
        jackpotNode:setPositionY(5)
    end
    self.m_jackpotNode = jackpotNode
end

--进入respin界面
function WarriorAliceBossItem:showInRespin(iCol)
    if iCol == 1 or iCol == 5 then
        util_spinePlay(self.boss,"actionframe_lv_big")
    elseif iCol == 2 or iCol == 4 then
        util_spinePlay(self.boss,"actionframe_lan_big")
    else
        util_spinePlay(self.boss,"actionframe_hong_big")
    end
end

function WarriorAliceBossItem:showCheckAct(iCol)
    
    if iCol == 1 or iCol == 5 then
        util_spinePlay(self.boss,"actionframe4_lv_big")
    elseif iCol == 2 or iCol == 4 then
        util_spinePlay(self.boss,"actionframe4_lan_big")
    else
        util_spinePlay(self.boss,"actionframe4_hong_big")
    end
end

--斩击消除动画 0-22帧
function WarriorAliceBossItem:showEliminateAct(iCol)
    if iCol == 1 or iCol == 5 then
        util_spinePlay(self.boss,"actionframe2_lv_big")
    elseif iCol == 2 or iCol == 4 then
        util_spinePlay(self.boss,"actionframe2_lan_big")
    else
        util_spinePlay(self.boss,"actionframe2_hong_big")
    end

end

--将扫光、jackpot隐藏
function WarriorAliceBossItem:hideJackpotAct(isShow)

    self:findChild("node_jackpot"):setVisible(isShow)
    self:findChild("Node_saoguang"):setVisible(isShow)
end

--移动动画
function WarriorAliceBossItem:showSoldierMove(iCol)
    if iCol == 1 or iCol == 5 then
        util_spinePlay(self.boss,"move_lv_big")
    elseif iCol == 2 or iCol == 4 then
        util_spinePlay(self.boss,"move_lan_big")
    else
        util_spinePlay(self.boss,"move_hong_big")
    end
end

--移动动画 每列只剩一个BOSS 移动的时候
function WarriorAliceBossItem:showSoldierMoveByBoss(iCol)
    if iCol == 1 or iCol == 5 then
        util_spinePlay(self.boss,"move_lv_big2")
    elseif iCol == 2 or iCol == 4 then
        util_spinePlay(self.boss,"move_lan_big2")
    else
        util_spinePlay(self.boss,"move_hong_big2")
    end
end

--高举武器，迎击状态 0-60帧
function WarriorAliceBossItem:showToEngageAct(iRow,iCol)
    if iCol == 1 or iCol == 5 then
        util_spinePlay(self.boss,"actionframe3_lv_big",false)
        util_spineEndCallFunc(self.boss, "actionframe3_lv_big", function ()
            self:showColorForIndexByBoss(iCol)
        end)
    elseif iCol == 2 or iCol == 4 then
        util_spinePlay(self.boss,"actionframe3_lan_big",false)
        util_spineEndCallFunc(self.boss, "actionframe3_lan_big", function ()
            self:showColorForIndexByBoss(iCol)
        end)
    else
        util_spinePlay(self.boss,"actionframe3_hong_big",false)
        util_spineEndCallFunc(self.boss, "actionframe3_hong_big", function ()
            self:showColorForIndexByBoss(iCol)
        end)
    end
end

function WarriorAliceBossItem:onEnter()

    WarriorAliceBossItem.super.onEnter(self)

end

function WarriorAliceBossItem:onExit()
    WarriorAliceBossItem.super.onExit(self)
    self.saoGuangNode:stopAllActions()

end

--[[
    延迟回调
]]
function WarriorAliceBossItem:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return WarriorAliceBossItem