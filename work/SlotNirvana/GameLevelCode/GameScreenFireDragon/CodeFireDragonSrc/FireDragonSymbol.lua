--
-- 泰山打小怪兽战斗条
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local FireDragonSymbol = class("FireDragonSymbol", util_require("base.BaseView"))


function FireDragonSymbol:initUI( csbpath,symbolType )
   
    self.m_spineAction = self:createSpineSymbolInFs(symbolType)
    
    self:playSpinSpinAction("idleframe", true) 
end

function FireDragonSymbol:appear(animation)
    gLobalSoundManager:playSound("FireDragonSounds/sound_FireDragon_change.mp3")
    self:playSpinSpinAction("chuxian", false, function()
        self:playSpinSpinAction(animation, true)
    end)
end

function FireDragonSymbol:playSpinSpinAction(animation, isloop, func)
    if self.m_spineAction then
        util_spinePlay(self.m_spineAction, animation, isloop)
        if func then
            util_spineEndCallFunc(self.m_spineAction, animation, func)
        end
    end
end

function FireDragonSymbol:createSpineSymbolInFs(symbolType )
    local symbolpath = nil
    local symbolSpr = nil
    local actionType = nil
    local pngPath = "Spine/Socre_FireDragon_SmallDragon"

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then  
        symbolpath = "Spine/Socre_FireDragon_small_8"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7  then
        symbolpath = "Spine/Socre_FireDragon_small_7"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6  then
        symbolpath = "Spine/Socre_FireDragon_small_6"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5  then
        symbolpath = "Spine/Socre_FireDragon_small_5"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        symbolpath = "Socre_FireDragon_0"
        pngPath = "Socre_FireDragon_9"
    end
    symbolSpr = util_spineCreateDifferentPath(symbolpath, pngPath, true, true)
    
    symbolSpr:setScale(1)
    if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        symbolSpr:setScale(0.92)
    end
    -- symbolSpr:setPositionY(-65)
    self:addChild(symbolSpr)
    
    return symbolSpr

end

function FireDragonSymbol:setSymbolPosition(pos)
    self.m_spineAction:setPosition(pos)
end

return  FireDragonSymbol