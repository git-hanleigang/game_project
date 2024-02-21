---
--xcyy
--2018年5月23日
--JungleJauntHippoGameControl.lua
local PBC = require "JungleJauntPublicConfig"
local JungleJauntHippoGameControl = class("JungleJauntHippoGameControl")

function JungleJauntHippoGameControl:initData_(_machine)
    self.m_machine = _machine
end

function JungleJauntHippoGameControl:initSpineUI()
   self.m_hippo = util_spineCreate("JungleJaunt_base_buff5",true,true)
   self.m_machine:findChild("base_buff5"):addChild(self.m_hippo)
   self.m_hippo:setVisible(false)
end

function JungleJauntHippoGameControl:playMonkeyGameStart(_func)

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_36)
    
    self.m_endCallFunc = _func

    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local game4_wild_pos = selfData.game4_wild_pos -- 变化的列

    
    --先把变化的按列
    local playL = {}

    for _iCol = 1, self.m_machine.m_iReelColumnNum do
        if not playL[_iCol] then
            playL[_iCol] = {}
        end
        for _iRow = self.m_machine.m_iReelRowNum, 1, -1 do
            if table_vIn(game4_wild_pos, self.m_machine:getPosReelIdx(_iRow, _iCol)) then
                table.insert(playL[_iCol], {["iRow"] = _iRow, ["iCol"] = _iCol})
            end
        end
    end

    -- 背景狂震
    self.m_machine:runCsbAction("buff5_zhendong")


    self.m_hippo:setVisible(true)
    util_spinePlay(self.m_hippo,"actionframe")
    util_spineEndCallFunc(self.m_hippo,"actionframe",function()
        self.m_hippo:setVisible(false)
    end)

    
    performWithDelay(self.m_hippo,function()
        self:symbolChangeAnim(playL,function()
            if self.m_endCallFunc then
                self.m_endCallFunc()
                self.m_endCallFunc = nil
            end
        end)
    end,60/30)
end


function JungleJauntHippoGameControl:symbolChangeAnim(_playL,_endFunc)
    local actionList = {}
    for iCol=1,self.m_machine.m_iReelColumnNum do
        local list = _playL[iCol]
        actionList[#actionList+1] = cc.CallFunc:create(function()

            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_35)
            
            for i=1,#list do
                local fixPos = list[i]
                local symbolNode = self.m_machine:getFixSymbol(fixPos.iCol, fixPos.iRow, SYMBOL_NODE_TAG)
                self.m_machine:changeSymbolType(symbolNode,TAG_SYMBOL_TYPE.SYMBOL_WILD,true)
                symbolNode:runAnim("start")
            end
        end)
        actionList[#actionList+1] = cc.DelayTime:create(10/60)
    end
    actionList[#actionList+1] = cc.DelayTime:create(0.5)
    actionList[#actionList+1] = cc.CallFunc:create(function()
        if _endFunc then
            _endFunc()
        end
    end)
    self.m_hippo:runAction(cc.Sequence:create(actionList))
end

return JungleJauntHippoGameControl