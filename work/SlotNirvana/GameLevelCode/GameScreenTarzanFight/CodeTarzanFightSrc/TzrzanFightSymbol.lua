--
-- 泰山打小怪兽战斗条
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local TzrzanFightSymbol = class("TzrzanFightSymbol", util_require("base.BaseView"))


function TzrzanFightSymbol:initUI( csbpath,symbolType )
    
    if csbpath == "Socre_TarzanFight_9" then
        self.m_spineAction =util_spineCreate("Socre_TarzanFight_9", true,true)
        self:addChild( self.m_spineAction)
        if self.m_spineAction then
            util_spinePlay(self.m_spineAction, "idle2", true)
        end
    else
        self:createCsbNode(csbpath..".csb")
        self.m_spineAction = self:createSpineSymbolInFs(symbolType)
        self.m_node_hide = self:findChild("node_hide")
        self.m_node_hide:setVisible(false)
        self:playSpinSpinAction(true)
    end
    self.m_SymbolType = symbolType
end

function TzrzanFightSymbol:playAction(name,isloop,func )
    if self.m_node_hide then
        self.m_node_hide:setVisible(true)
    end

    if  self.m_SymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        if self.m_spineAction then
            util_spinePlay(self.m_spineAction, name, isloop)
            util_spineEndCallFunc(
                self.m_spineAction,
                name,
                function()
                    if func then
                        func()
                    end
                end
            )
        end
    else
        self:runCsbAction(name,isloop,func)
    end
   
end

function TzrzanFightSymbol:hideSpine( )
    if self.m_spineAction then
        self.m_spineAction:setVisible(false)
    end
end

function TzrzanFightSymbol:playSpinSpinAction(isloop)
    if self.m_spineAction then
        util_spinePlay(self.m_spineAction, "animation", isloop)
    end
end

function TzrzanFightSymbol:createSpineSymbolInFs(symbolType )
    local symbolpath = nil
    local symbolSpr = nil
    local actionType = nil


    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then  
          symbolpath = "Spine/xingxing"
          symbolSpr =util_spineCreate(symbolpath, true)
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7  then
          symbolpath = "Spine/Shizi"
          symbolSpr =util_spineCreate(symbolpath, true)
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6  then
          symbolpath = "Spine/daxiang"
          symbolSpr =util_spineCreate(symbolpath, true)
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5  then
          symbolpath = "Spine/eyu"
          symbolSpr =util_spineCreate(symbolpath, true)
    end

    -- util_spinePlay(spNode, "animation", false)
    symbolSpr:setScale(1)
    symbolSpr:setPositionY(-65)
    self:addChild(symbolSpr)
    
    return symbolSpr

end

function TzrzanFightSymbol:setSymbolPosition(pos)
    
    if  self.m_SymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        if self.m_spineAction then
           self.m_spineAction:setPosition(pos)
        end
    else
        self.m_csbNode:setPosition(pos)
    end
end

return  TzrzanFightSymbol