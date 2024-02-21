---
--xcyy
--2018年5月23日
--JungleJauntMonkeyGameControl.lua
local PBC = require "JungleJauntPublicConfig"
local JungleJauntMonkeyGameControl = class("JungleJauntMonkeyGameControl")

function JungleJauntMonkeyGameControl:initData_(_machine)
    self.m_machine = _machine
end

function JungleJauntMonkeyGameControl:initSpineUI()
   self.m_monkey1 = util_spineCreate("JungleJaunt_base_buff4",true,true)
   self.m_machine:findChild("base_buff4"):addChild(self.m_monkey1)

   self.m_monkey2 = util_spineCreate("JungleJaunt_base_buff4",true,true)
   self.m_machine:findChild("base_buff4"):addChild(self.m_monkey2)

   self.m_machine:findChild("Panel_StopBuff3"):setVisible(false)
   self.m_monkey1:setVisible(false)
   self.m_monkey2:setVisible(false)
end

function JungleJauntMonkeyGameControl:playMonkeyGameStart(_func)

    self.m_endCallFunc = _func

    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local game3_wild_pos = clone(selfData.game3_wild_pos) -- 变化的列

    
    --先把变化的列分成两份
    local playL1 = {}
    local playL2 = {}
    -- 先1,2 各塞一个
    if #game3_wild_pos > 0 then
        table.insert(playL1,game3_wild_pos[1])
        table.remove(game3_wild_pos,1)
    end
    if #game3_wild_pos > 0 then
        table.insert(playL2,game3_wild_pos[1])
        table.remove(game3_wild_pos,1)
    end
    -- 剩下的随机一二去塞
    for i=1,#game3_wild_pos do
        local col = game3_wild_pos[i]
        local rod = math.random(1,2)
        if rod == 1 then
            table.insert(playL1,col)
        else
            table.insert(playL2,col)
        end
    end

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_34)
    self.m_monkey1:setVisible(true)
    util_spinePlay(self.m_monkey1,"actionframe")
    util_spineEndCallFunc(self.m_monkey1,"actionframe",function()
        self.m_monkey1:setVisible(false)
    end)

    -- 猴一变化
    performWithDelay(self.m_monkey1,function()
        self:symbolChangeAnim(playL1) -- 猴一图标变化
    
        -- 猴二逻辑
        performWithDelay(self.m_monkey2,function()

            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_34)
            self.m_monkey2:setVisible(true)
            util_spinePlay(self.m_monkey2,"actionframe2")
            util_spineEndCallFunc(self.m_monkey2,"actionframe",function()
                self.m_monkey2:setVisible(false)
            end)
            -- 猴二变化
            performWithDelay(self.m_monkey1,function()
                self:symbolChangeAnim(playL2,function()
                    if self.m_endCallFunc then
                        self.m_endCallFunc()
                        self.m_endCallFunc = nil
                    end
                end) -- 猴二图标变化
            end,25/30)
        end,35/30)

    end,25/30)
end


function JungleJauntMonkeyGameControl:symbolChangeAnim(_playL,_endFunc)

    local isPlay = false
    

    for i=1,#_playL do
        local iCol = _playL[i] + 1
        local xj = util_spineCreate("JungleJaunt_base_buff4_xj",true,true)
        self.m_machine:findChild("base_buff4_xj"):addChild(xj)
        xj:setScale(self.m_machine.m_machineRootScale)
        local endPos = util_convertToNodeSpace(self.m_machine:getFixSymbol(iCol, 4, SYMBOL_NODE_TAG), self.m_machine:findChild("base_buff4_xj")) 
        local actionList = {}
        actionList[#actionList+1] = cc.CallFunc:create(function()
            util_spinePlay(xj,"start")
        end)
        actionList[#actionList+1] = cc.MoveTo:create(12/30, cc.p(endPos.x,0))
        actionList[#actionList+1] = cc.DelayTime:create(6/30)
        actionList[#actionList+1] = cc.CallFunc:create(function()
            if i == 1 then
                gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_35)
            end
            -- 图标 row 4 变
            local symbolNode = self.m_machine:getFixSymbol(iCol, 4, SYMBOL_NODE_TAG)
            self.m_machine:changeSymbolType(symbolNode,TAG_SYMBOL_TYPE.SYMBOL_WILD,true)
            symbolNode:runAnim("start")
        end)
        actionList[#actionList+1] = cc.DelayTime:create(3/30)
        actionList[#actionList+1] = cc.CallFunc:create(function()
            if i == 1 then
                gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_35)
            end
            -- 图标 row 3 变
            local symbolNode = self.m_machine:getFixSymbol(iCol, 3, SYMBOL_NODE_TAG)
            self.m_machine:changeSymbolType(symbolNode,TAG_SYMBOL_TYPE.SYMBOL_WILD,true)
            symbolNode:runAnim("start")
        end)
        actionList[#actionList+1] = cc.DelayTime:create(3/30)
        actionList[#actionList+1] = cc.CallFunc:create(function()
            if i == 1 then
                gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_35)
            end
            -- 图标 row 2 变
            local symbolNode = self.m_machine:getFixSymbol(iCol, 2, SYMBOL_NODE_TAG)
            self.m_machine:changeSymbolType(symbolNode,TAG_SYMBOL_TYPE.SYMBOL_WILD,true)
            symbolNode:runAnim("start")
        end)
        actionList[#actionList+1] = cc.DelayTime:create(3/30)
        actionList[#actionList+1] = cc.CallFunc:create(function()
            if i == 1 then
                gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_35)
            end
            -- 图标 row 1 变
            local symbolNode = self.m_machine:getFixSymbol(iCol, 1, SYMBOL_NODE_TAG)
            self.m_machine:changeSymbolType(symbolNode,TAG_SYMBOL_TYPE.SYMBOL_WILD,true)
            symbolNode:runAnim("start")
        end)
        actionList[#actionList+1] = cc.DelayTime:create((65-27)/30)
        if i == #_playL then
            actionList[#actionList+1] = cc.CallFunc:create(function()
                if _endFunc then
                    _endFunc()
                end
            end)
        end
        actionList[#actionList+1] = cc.CallFunc:create(function()
            xj:removeFromParent()
        end)
        xj:runAction(cc.Sequence:create(actionList))
    end
end

return JungleJauntMonkeyGameControl