local ColorfulCircusMapItem = class("ColorfulCircusMapItem",util_require("Levels.BaseLevelDialog"))

function ColorfulCircusMapItem:initUI(_map, _index)
    self.m_map = _map
    self.m_index = _index
    if self.m_index % 5 == 0 then
        self:createCsbNode("ColorfulCircus_map_dadian.csb")
    else
        self:createCsbNode("ColorfulCircus_map_xiaodian.csb")
    end
    
    self:initItem()

end


function ColorfulCircusMapItem:initItem()
    if self.m_index % 5 == 0 then
        for i=1,4 do
            self:findChild("Node_big" .. i):setVisible(false)
        end
        
        
        if self.m_index == 5 then
            self:findChild("Node_big1"):setVisible(true)
            self:createSpineItem( 1 )
        elseif self.m_index == 10 then
            self:findChild("Node_big2"):setVisible(true)
            self:createSpineItem( 2 )
        elseif self.m_index == 15 then
            self:findChild("Node_big3"):setVisible(true)
            self:createSpineItem( 3 )
        elseif self.m_index == 20 then
            self:findChild("Node_big4"):setVisible(true)
            self:createSpineItem( 4 )
        end
    end
end

function ColorfulCircusMapItem:createSpineItem( idx )
    local spineName = {"ColorfulCircus_shouji_1", "ColorfulCircus_shouji_3", "ColorfulCircus_shouji_5", "ColorfulCircus_shouji_4"}
    local nodeName = {"big1_tan", "big2_tan", "big3_tian", "big4_tan"}
    self.m_bigStageSpine =  util_spineCreate(spineName[idx],true,true)
    self:findChild(nodeName[idx]):addChild(self.m_bigStageSpine)
end

function ColorfulCircusMapItem:click(func,LitterGameWin)
    
    -- 
    if self.m_index % 5 ~= 0 then
        self:findChild("m_lb_coins"):setString(util_formatCoins(LitterGameWin,3))
    end
    
    -- gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_collect_small.mp3")
    self.m_map:setNodeOrder(self.m_index, 25)
    if self.m_index % 5 == 0 then
        util_spinePlay(self.m_bigStageSpine,"actionframe",false)
        util_spineEndCallFunc(self.m_bigStageSpine, "actionframe", function()
            -- self:idle()
        end)
        if self.m_index ~= 20 then
            self:runCsbAction("actionframe", false)
        end
        
        gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_collect_big.mp3")
    else
        gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_collect_small.mp3")
        self:runCsbAction("actionframe",false, function()
            self:idle()
        end)
    end
    
    -- performWithDelay(self,function (  )
        -- gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_collect_shipDown.mp3")
    -- end,1/3)
    performWithDelay(self,function (  )
        self.m_map:setNodeOrder(self.m_index, self.m_index)
        if func then
            func()
        end
    end,60/60)

end

function ColorfulCircusMapItem:idle(isFinish)
    if self.m_index % 5 == 0 then
        
        if isFinish then
            self:runCsbAction("yaan", false)
            if self.m_bigStageSpine then
                util_spinePlay(self.m_bigStageSpine,"yaan_idle", true)
            end
        else
            self:runCsbAction("idleframe", true)
            if self.m_bigStageSpine then
                util_spinePlay(self.m_bigStageSpine,"idleframe", true)
            end
        end
    else
        if isFinish then
            self:runCsbAction("idle_gou", true)
        else
            self:runCsbAction("idleframe2", true)
        end
        
    end
    
end

function ColorfulCircusMapItem:completed()
    -- self:findChild("m_lb_coins"):setString("")
    -- self:findChild("gou"):setVisible(true)
    self:runCsbAction("idle_gou", true)
end

function ColorfulCircusMapItem:runComplete()
    -- self:findChild("gou"):setVisible(true)
    self:runCsbAction("idleframe", false, function (  )
        self:runCsbAction("idle_gou", true)
    end)
    
end

function ColorfulCircusMapItem:runBeginAnim( isFinish )
    if self.m_index % 5 == 0 then
        if isFinish then
            self:runCsbAction("yaan", false, function (  )
                -- self:idle(isFinish)
            end)
        else
            self:runCsbAction("start", false, function (  )
                self:idle(isFinish)
            end)
        end
        
        if self.m_bigStageSpine then
            if isFinish then
                util_spinePlay(self.m_bigStageSpine,"yaan",false)
                util_spineEndCallFunc(self.m_bigStageSpine, "yaan", function()
                    util_spinePlay(self.m_bigStageSpine,"yaan_idle",true)
                end)
            else
                util_spinePlay(self.m_bigStageSpine,"start",false)
                util_spineEndCallFunc(self.m_bigStageSpine, "start", function()
                    util_spinePlay(self.m_bigStageSpine,"idleframe",true)
                end)
            end
            
        end
        
    else
        if isFinish then
            self:runCsbAction("yaan", false, function (  )
                self:idle(isFinish)
            end)
        else
            self:runCsbAction("start_qiqiu", false, function (  )
                self:idle(isFinish)
            end)
        end
    end
    
end

-- function ColorfulCircusMapItem:overAnim(  )
--     if self.m_index % 5 == 0 then
--         self:runCsbAction("over", false, function (  )
--         end)
--         if self.m_bigStageSpine then
--             util_spinePlay(self.m_bigStageSpine,"over",false)

--         end
        
--     else

--     end
-- end

function ColorfulCircusMapItem:onEnter()
    ColorfulCircusMapItem.super.onEnter(self)
end

function ColorfulCircusMapItem:onExit()
    ColorfulCircusMapItem.super.onExit(self)
end


return ColorfulCircusMapItem