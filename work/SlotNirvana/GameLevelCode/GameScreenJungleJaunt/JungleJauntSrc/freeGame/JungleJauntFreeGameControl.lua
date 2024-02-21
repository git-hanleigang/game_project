---
--xcyy
--2018年5月23日
--JungleJauntFreeGameControl.lua
local PBC = require "JungleJauntPublicConfig"
local JungleJauntFreeGameControl = class("JungleJauntFreeGameControl")

function JungleJauntFreeGameControl:initData_(_machine)
    self.m_machine = _machine
end

function JungleJauntFreeGameControl:playFreeBonusMove(_func)

    if self.m_machine:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if _func then
            _func()
        end
        return
    end

    

    -- 根据free回传固定bonus位置创建
    local fsExtraData = self.m_machine.m_runSpinResultData.p_fsExtraData or {}
    local storedIcons = fsExtraData.storedIcons or {}
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local newstordIcons = selfData.newstordIcons or {}
    if table_length(storedIcons) > 0  then

        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_45)
        
        -- 把棋盘上已经固定的刷新一下信息
        local childs = self.m_machine.m_effectNode:getChildren()
        for i=1,#childs do
            local node = childs[i]
            node.iRow = node.iRow - 1
            node:setName("lockBonus"..self.m_machine:getNodeTag(node.iCol, node.iRow,SYMBOL_NODE_TAG))
        end

        -- -- 新增本次新的
        -- if table_length(newstordIcons) > 0  then
        --     for i=1,#newstordIcons do
        --         local info = newstordIcons[i]
        --         local node = self:createFsLockBonus(info)
        --         node.iRow = node.iRow - 1
        --         node:setName("lockBonus"..self.m_machine:getNodeTag(node.iCol, node.iRow,SYMBOL_NODE_TAG))
        --     end
        -- end

        -- 看本次是否是需要添加
        for i=1,#storedIcons do
            local info = storedIcons[i]
            local posIndex = info[1]
            local fixPos = self.m_machine:getRowAndColByPos(posIndex)
            local iCol = fixPos.iY
            local iRow = fixPos.iX
            local node = self:getFsLockBonus(iCol,iRow - 1)
            if not node then
                node = self:createFsLockBonus(info)
                node.iRow = node.iRow - 1
                node:setName("lockBonus"..self.m_machine:getNodeTag(node.iCol, node.iRow,SYMBOL_NODE_TAG))
            end
        end

        -- 一起向下移动
        local childs = self.m_machine.m_effectNode:getChildren()
        local moveTime = 0.5

        for i=1,#childs do
            local node = childs[i]
            local endPos = util_getOneGameReelsTarSpPos(self.m_machine, self.m_machine:getPosReelIdx(node.iRow, node.iCol))
            local actionList = {}
            if node.iRow <= 0 then
                actionList[#actionList + 1] =
                    cc.CallFunc:create(
                    function()
                        util_playFadeOutAction(node,moveTime/2,function()
                            node:removeFromParent()
                        end)
                    end
                )
            end
            actionList[#actionList + 1] = cc.EaseInOut:create(cc.MoveTo:create(moveTime,endPos), 1)
            local seq = cc.Sequence:create(actionList)
            node:runAction(seq)

            local showOrder = self.m_machine:getBounsScatterDataZorder(node.symbolType)
            node:setLocalZOrder(showOrder - node.iRow + node.iCol * self.m_machine.m_iReelRowNum)  
        end
        -- 做下数据校验
        local lockNum = 0
        for i=1,#childs do
            local node = childs[i]
            lockNum = lockNum + 1
        end

        if lockNum ~=  table_length(storedIcons) then
            util_logDevAssert("本地固定和服务器固定不一致;storedIcons: "..cjson.encode(storedIcons))
        end

        performWithDelay(self.m_machine,function()
            if _func then
                _func()
            end
        end,moveTime)
    else
        if _func then
            _func()
        end
    end
end

-- freeLockBonus玩法

function JungleJauntFreeGameControl:getFsLockBonus(_iCol,_iRow)
    return self.m_machine.m_effectNode:getChildByName("lockBonus"..self.m_machine:getNodeTag(_iCol, _iRow,SYMBOL_NODE_TAG))
end

function JungleJauntFreeGameControl:createFsLockBonus(_infos)
    local score = _infos[3]
    local symbolType = _infos[2]
    local posIndex = _infos[1]
    local fixPos = self.m_machine:getRowAndColByPos(posIndex)
    local iCol = fixPos.iY
    local iRow = fixPos.iX
    local lockBonus = util_spineCreate(self.m_machine:MachineRule_GetSelfCCBName(symbolType),true,true)
    lockBonus.m_coinsLab = self.m_machine:createBonusLab(symbolType,lockBonus)
    self.m_machine.m_effectNode:addChild(lockBonus)
    lockBonus:setName("lockBonus"..self.m_machine:getNodeTag(iCol, iRow,SYMBOL_NODE_TAG))
    lockBonus.iCol = iCol
    lockBonus.iRow = iRow
    lockBonus:setPosition(util_getOneGameReelsTarSpPos(self.m_machine, posIndex))
    local totalBet = globalData.slotRunData:getCurTotalBet()
    score = util_formatCoinsLN(score * totalBet, 3)
    lockBonus.m_coinsLab:findChild("m_lb_coins"):setString(score)
    lockBonus.m_coinsLab:updateLabelSize({label = lockBonus.m_coinsLab:findChild("m_lb_coins"), sx = 1, sy = 1}, 134)
    util_spinePlay(lockBonus,"idleframe2",true)
    local showOrder = self.m_machine:getBounsScatterDataZorder(symbolType)
    lockBonus:setLocalZOrder(showOrder - iRow + iCol * self.m_machine.m_iReelRowNum)  
    lockBonus.symbolType = symbolType
    util_setCascadeOpacityEnabledRescursion(lockBonus,true)
    return lockBonus
end

return JungleJauntFreeGameControl