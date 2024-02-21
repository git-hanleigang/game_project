---
--xcyy
--2018年5月23日
--RollingJackpotFreeJackpotItemShell.lua

local RollingJackpotFreeJackpotItemShell = class("RollingJackpotFreeJackpotItemShell",util_require("Levels.BaseLevelDialog"))
local ConfigInstance  = require("RollingJackpotPublicConfig"):getInstance()
-- local SoundConfig = ConfigInstance.SoundConfig
local ITMETYPE = {
    NORMAL = 1,  --普通的
    NEXT = 2,    --下次的
    CURRENT = 3 --当前的
}

function RollingJackpotFreeJackpotItemShell:initUI(index)

    self:createCsbNode("RollingJackpot_free_dan_item_shell.csb")
    self.m_type = ITMETYPE.NEXT
    self.m_index = index
    self.m_curRow = 3
    self.m_item = util_createView("RollingJackpotSrc.RollingJackpotFreeJackpotItem", self.m_index)
    self:findChild("item"):addChild(self.m_item)
    self:createTargetObj()
    self:createFreeSpin()
end

function RollingJackpotFreeJackpotItemShell:initInfo(data)
    self.m_gameData = data
    self.m_index = data.index
    self.m_multiple = data.multiple
    self.m_item:initData(data)
end

function RollingJackpotFreeJackpotItemShell:onEnter()

end

function RollingJackpotFreeJackpotItemShell:showAdd()
    
end
function RollingJackpotFreeJackpotItemShell:onExit()
    --gLobalNoticManager:removeAllObservers(self)
end

--默认按钮监听回调
function RollingJackpotFreeJackpotItemShell:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end

function RollingJackpotFreeJackpotItemShell:setItemType(typeIndex)
    self.m_type = typeIndex
end

function RollingJackpotFreeJackpotItemShell:initItemType(typeIndex)
    self:setItemType(typeIndex)
    self.m_item:setItemType(typeIndex)
    self.m_item:playIdle()
    self:playTargetObjIdle()
    if self.m_type == ITMETYPE.CURRENT then
        self.m_freeBarObj:hide(false)
    end
    self:playIdle()
end

function RollingJackpotFreeJackpotItemShell:createTargetObj()
    self.m_targetObj = util_createAnimation("RollingJackpot_Free_mubiaoshu.csb")
    self:findChild("targetNum"):addChild(self.m_targetObj)
end

function RollingJackpotFreeJackpotItemShell:createFreeSpin()
    self.m_freeBarObj = util_createAnimation("RollingJackpot_FreeSpinBar.csb")
    self:findChild("freebar"):addChild(self.m_freeBarObj)
end

function RollingJackpotFreeJackpotItemShell:playTargetObjAni(aniStr, isLoop, callBack)
    if self.m_targetObj and aniStr and aniStr ~= "" then
        self.m_targetObj:playAction(aniStr, isLoop, callBack)
    end
end

function RollingJackpotFreeJackpotItemShell:playTargetObjIdle()
    local idleStr = ""
    if ITMETYPE.CURRENT == self.m_type then
        idleStr = "idle4"
    elseif ITMETYPE.NEXT == self.m_type then
        idleStr = "idle"
    end
    self:playTargetObjAni(idleStr, false)
end

function RollingJackpotFreeJackpotItemShell:playIdle()
    local idleStr = ""
    if ITMETYPE.CURRENT == self.m_type then
        idleStr = "idle4"
    elseif ITMETYPE.NEXT == self.m_type then
        if self.m_curRow < 5 then
            idleStr = "idle1"
        else
            idleStr = "idle2"
        -- else
        --     idleStr = "idle3"
        end
    end
    self:runCsbAction(idleStr)
    if ITMETYPE.CURRENT == self.m_type then
        -- local targetPos = cc.p(self:findChild("targetNum"):getPosition()) 
        -- local movePos = cc.p(-200, targetPos.y)
        -- self:findChild("targetNum"):setPosition(movePos)
        self:findChild("targetNum"):setScale(1)
    end
end

function RollingJackpotFreeJackpotItemShell:upReelAni(row)
    self.m_curRow = row
    local posY = 0
    local actionStr = nil
    if self.m_curRow == 5 then
        actionStr = "animation1"
        posY = -5
    -- elseif self.m_curRow == 9 then
    --     actionStr = "animation2"
    --     posY = -7
    end
    if actionStr then
        self:setPositionY(posY)
        self:runCsbAction(actionStr, false, function()
            self:playIdle()
        end)
    end
end

function RollingJackpotFreeJackpotItemShell:showCollectFullEffect()
    self.m_freeBarObj:hide()
    self.m_item:showCollectFullEffect()
end

function RollingJackpotFreeJackpotItemShell:setFullEffect()
    self.m_item:runCsbAction("idle4")
    self:playTargetObjAni("idle2", true)
    self.m_freeBarObj:hide()
    self:playIdle()
end

--转换成当前的action
function RollingJackpotFreeJackpotItemShell:changeCurTypeAction()
    self.m_item:runCsbAction("actionframe2")
    self:playTargetObjAni("switch2", false, function()
        self:playTargetObjAni("idle3", true)
        -- self:waitWithDelay(7/6, function()
        --     self:findChild("item"):runAction(cc.ScaleTo:create(time,1))
        --     self:findChild("targetNum"):runAction(cc.ScaleTo:create(time,1))
        -- end)
    end)
    local time = 1/3
    self:waitWithDelay(7/6, function()
        self:findChild("item"):runAction(cc.ScaleTo:create(time,1))
        self:findChild("targetNum"):runAction(cc.ScaleTo:create(time,1))
    end)
end

function RollingJackpotFreeJackpotItemShell:waitWithDelay(time, endFunc)
    if time <= 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode, function(  )
        if endFunc then
            endFunc()
        end
        waitNode:removeFromParent()
    end, time)
end

function RollingJackpotFreeJackpotItemShell:hideTarget()
    self.m_targetObj:hide()
end

function RollingJackpotFreeJackpotItemShell:resetCurLevelInfo()
    if self.m_type == ITMETYPE.CURRENT then
        local info = ConfigInstance:getCurLevelInfo()
        self:initInfo(info)
        self:initItemType(self.m_type)
        self.m_targetObj:setOpacity(255)
        self.m_targetObj:show()
    end
end

function RollingJackpotFreeJackpotItemShell:resetNextLevelInfo()
    if self.m_type == ITMETYPE.NEXT then
        local info = ConfigInstance:getnextLevelInfo()
        self:initInfo(info)
        self:initItemType(self.m_type)
        local num = ConfigInstance:getCurResidueCollectNum()
        local freeNum = ConfigInstance:getCurResidueFreeNum()
        self:setTargetNum(num)
        self:setFreeNum(freeNum)
        self.m_targetObj:setOpacity(255)
        self.m_freeBarObj:setOpacity(255)
        self.m_targetObj:show()
        self.m_freeBarObj:show()
        self.m_residueNum = num
    end
end

function RollingJackpotFreeJackpotItemShell:hideFreeBarAndTarget(bfade)
    util_setCascadeOpacityEnabledRescursion(self.m_targetObj,true)
    util_setCascadeOpacityEnabledRescursion(self.m_freeBarObj,true)
    if bfade then
        local tiem = 0.25
        self.m_targetObj:runAction(cc.Sequence:create(cc.FadeTo:create(tiem,0),cc.CallFunc:create(function(p)
            p:hide()
        end)))
        self.m_freeBarObj:runAction(cc.Sequence:create(cc.FadeTo:create(tiem,0),cc.CallFunc:create(function(p)
            p:hide()
        end)))
    else
        self.m_targetObj:setOpacity(0)
        self.m_freeBarObj:setOpacity(0)
        self.m_targetObj:hide()
        self.m_freeBarObj:hide()
    end
end

function RollingJackpotFreeJackpotItemShell:showFreeBarAndTarget(bfade)
    util_setCascadeOpacityEnabledRescursion(self.m_targetObj,true)
    util_setCascadeOpacityEnabledRescursion(self.m_freeBarObj,true)

    local opacity = bfade and 0 or 255
    self.m_targetObj:setOpacity(opacity)
    self.m_freeBarObj:setOpacity(opacity)
    self.m_targetObj:show()
    self.m_freeBarObj:show()
    if bfade then
        local tiem = 0.25
        self.m_targetObj:runAction(cc.FadeTo:create(tiem, 255))
        self.m_freeBarObj:runAction(cc.FadeTo:create(tiem, 255))
    end
end

function RollingJackpotFreeJackpotItemShell:setItemScale(scale)
    self:findChild("item"):setScale(scale)
end

function RollingJackpotFreeJackpotItemShell:setItemScaleTo(scale)
    self:findChild("item"):runAction(cc.ScaleTo:create(1/4, scale))
end

function RollingJackpotFreeJackpotItemShell:setTargetNum(num)
    self.m_targetObj:findChild("m_lb_num"):setString(num)
end

function RollingJackpotFreeJackpotItemShell:setFreeNum(num)
    self.m_freeBarObj:findChild("m_lb_num"):setString(num)
    self.m_freeBarObj:findChild("spin"):setVisible(num > 0)
    self.m_freeBarObj:findChild("last_spin"):setVisible(num <= 0)
end

function RollingJackpotFreeJackpotItemShell:showCollectAni(callBack)
    if ITMETYPE.NEXT == self.m_type then
        self.m_residueNum = self.m_residueNum - 1
        self.m_residueNum = math.max(self.m_residueNum, 0)
        if self.m_residueNum == 0 then
            self.m_item:runCsbAction("over2")
            self:playTargetObjAni("switch", false, function()
                self:playTargetObjAni("idle2", true)
                if callBack then
                    callBack()
                end
            end)
        else
            if callBack then
                self:playTargetObjAni("shouji", false, function()
                    callBack()
                end)
            else
                self:playTargetObjAni("shouji")
            end
            self:waitWithDelay(1/6, function()
                self:setTargetNum(self.m_residueNum)
            end)
        end
    end
end

function RollingJackpotFreeJackpotItemShell:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    self:setFreeNum(leftFsCount)
end
function RollingJackpotFreeJackpotItemShell:setCurFreeRow(rowNum)
    self.m_curRow = rowNum
end

--
function RollingJackpotFreeJackpotItemShell:showWinJackpot(callBack)
    self:playTargetObjAni("switch3")
    self.m_item:showTotalWin()
    self.m_item:runCsbAction("actionframe4", false, function()
        callBack()
    end)
end

--显示左右信息
function RollingJackpotFreeJackpotItemShell:showNextEffect()
    self:show()
    self.m_item:runCsbAction("actionframe5", false, function()
        self:showFreeBarAndTarget(true)
        self.m_item:runCsbAction("start")
    end)
end

function RollingJackpotFreeJackpotItemShell:hideSelf()
    self.m_item:runCsbAction("over")
    util_setCascadeOpacityEnabledRescursion(self.m_targetObj,true)
    local tiem = 1
    self.m_targetObj:runAction(cc.Sequence:create(cc.FadeTo:create(tiem,0),cc.CallFunc:create(function(p)
        p:hide()
    end)))
end

return RollingJackpotFreeJackpotItemShell