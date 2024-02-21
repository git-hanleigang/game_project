---
--xcyy
--2018年5月23日
--WarriorAliceSoldierSItem.lua

local WarriorAliceSoldierSItem = class("WarriorAliceSoldierSItem",util_require("Levels.BaseLevelDialog"))

local showName = {
    "Node_mini",
    "Node_minor",
    "Node_major"
}

function WarriorAliceSoldierSItem:initUI(params)

    self:createCsbNode("WarriorAlice_soldiersmall.csb")

    
    self.soldier = util_spineCreate("WarriorAlice_shibing",true,true)
    self:findChild("Node_soldier"):addChild(self.soldier)
    
    self.saoGuang = util_spineCreate("WarriorAlice_shibing",true,true)
    self:findChild("Node_saoguang"):addChild(self.saoGuang)
    util_spinePlay(self.saoGuang,"idleframe_saoguang")

    local colIndex = params[1]
    local rowIndex = params[2]

    self.saoGuangNode = cc.Node:create()
    self:addChild(self.saoGuangNode)

    self.idleNode = cc.Node:create()
    self:addChild(self.idleNode)

    self:showResetAllIttem(rowIndex,colIndex)
end

function WarriorAliceSoldierSItem:showResetAllIttem(rowIndex,colIndex)
    self:hideJackpotAct(true)
    self.saoGuangNode:stopAllActions()
    self:showIdleForIndex(colIndex)
    self:showColorForIndex(colIndex)
    self:showSaoGuang(rowIndex,colIndex)
end

function WarriorAliceSoldierSItem:showIdleForIndex(colIndex)
    if colIndex == 1 or colIndex == 5 then
        util_spinePlay(self.soldier,"idleframe_lv")
    elseif colIndex == 2 or colIndex == 4 then
        util_spinePlay(self.soldier,"idleframe_lan")
    else
        util_spinePlay(self.soldier,"idleframe_hong")
    end
end

function WarriorAliceSoldierSItem:showColorForIndex(colIndex)
    if colIndex == 1 or colIndex == 5 then
        performWithDelay(self.idleNode,function ()
            util_spinePlay(self.soldier,"idle2_3",true)
        end,20/30)
    elseif colIndex == 2 or colIndex == 4 then
        performWithDelay(self.idleNode,function ()
            util_spinePlay(self.soldier,"idle2_2",true)
        end,10/30)
    else
        util_spinePlay(self.soldier,"idle2_1",true)
    end
end

function WarriorAliceSoldierSItem:showSaoGuang(rowIndex,colIndex)
    local function saoGuangForcol(colIndex)
        if colIndex == 1 or colIndex == 5 then
            util_spinePlay(self.saoGuang,"idle5_2")
        elseif colIndex == 2 or colIndex == 4 then
            util_spinePlay(self.saoGuang,"idle4_2")
        else
            util_spinePlay(self.saoGuang,"idle3_2")
        end
    end

    local function saoGuangForRow( )
        if rowIndex == 1 then
            saoGuangForcol(colIndex)
        elseif rowIndex == 2 then
            self:delayCallBack(8/30,function ()
                saoGuangForcol(colIndex)
            end)
        elseif rowIndex == 3 then
            self:delayCallBack(16/30,function ()
                saoGuangForcol(colIndex)
            end)
        elseif rowIndex == 4 then
            self:delayCallBack(30/30,function ()
                saoGuangForcol(colIndex)
            end)
        end
    end
    if colIndex == 2 or colIndex == 4 then
        saoGuangForRow(colIndex)
    elseif colIndex == 1 or colIndex == 3 or colIndex == 5 then
        self:delayCallBack(60/30,function ()
            saoGuangForRow(colIndex)
        end)
    end

    performWithDelay(self.saoGuangNode,function ()
        self:showSaoGuang(rowIndex,colIndex)
    end,5.5)
end

--进入respin界面 0-42帧
function WarriorAliceSoldierSItem:showInRespin(iCol)
    self.saoGuangNode:stopAllActions()
    if iCol == 1 or iCol == 5 then
        util_spinePlay(self.soldier,"actionframe_lv")
    elseif iCol == 2 or iCol == 4 then
        util_spinePlay(self.soldier,"actionframe_lan")
    else
        util_spinePlay(self.soldier,"actionframe_hong")
    end
end

--选中动画 0-60帧
function WarriorAliceSoldierSItem:showCheckAct(iCol)
    self.saoGuangNode:stopAllActions()
    self.idleNode:stopAllActions()
    if iCol == 1 or iCol == 5 then
        util_spinePlay(self.soldier,"actionframe4_lv")
    elseif iCol == 2 or iCol == 4 then
        util_spinePlay(self.soldier,"actionframe4_lan")
    else
        util_spinePlay(self.soldier,"actionframe4_hong")
    end
end

--斩击消除动画 0-22帧
function WarriorAliceSoldierSItem:showEliminateAct(iCol)
    self.saoGuangNode:stopAllActions()
    if iCol == 1 or iCol == 5 then
        util_spinePlay(self.soldier,"actionframe2_lv")
    elseif iCol == 2 or iCol == 4 then
        util_spinePlay(self.soldier,"actionframe2_lan")
    else
        util_spinePlay(self.soldier,"actionframe2_hong")
    end
end

--移动动画 0- 40帧
function WarriorAliceSoldierSItem:showSoldierMove(iCol)
    self.saoGuangNode:stopAllActions()
    if iCol == 1 or iCol == 5 then
        util_spinePlay(self.soldier,"move_lv")
    elseif iCol == 2 or iCol == 4 then
        util_spinePlay(self.soldier,"move_lan")
    else
        util_spinePlay(self.soldier,"move_hong")
    end
end

--将扫光、jackpot隐藏
function WarriorAliceSoldierSItem:hideJackpotAct(isShow)

    self:findChild("Node_saoguang"):setVisible(isShow)
end

function WarriorAliceSoldierSItem:onEnter()

    WarriorAliceSoldierSItem.super.onEnter(self)

end

function WarriorAliceSoldierSItem:onExit()
    WarriorAliceSoldierSItem.super.onExit(self)
    self.saoGuangNode:stopAllActions()
    self.idleNode:stopAllActions()
end

--[[
    延迟回调
]]
function WarriorAliceSoldierSItem:delayCallBack(time, func)
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


return WarriorAliceSoldierSItem