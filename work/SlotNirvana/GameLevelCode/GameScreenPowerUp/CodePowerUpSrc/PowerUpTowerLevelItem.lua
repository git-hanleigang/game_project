--转轮上面的展示位
--PowerUpTowerLevelItem.lua

local PowerUpTowerLevelItem = class("PowerUpTowerLevelItem",util_require("base.BaseView"))
PowerUpTowerLevelItem.m_index = nil
--小块 {index =1 ,type = 1,num = 2}
function PowerUpTowerLevelItem:initUI(list,isLast)
    self.m_typeList = list
    self.m_isLast = isLast
    self:createCsbNode("PowerUp_bonus_levelItem.csb")

end
function PowerUpTowerLevelItem:getBgWidth()
    local bg = self:findChild("bg")
    local size = bg:getSize()
    return size
end
function PowerUpTowerLevelItem:setViewData(data)
    if self.scoreGenera then
        self.scoreGenera:removeFromParent()
        self.scoreGenera = nil
    end
    self.m_data = data

    self.m_index = data.index
    self.scoreGenera = util_createAnimation("PowerUp_bonus_score"..self.m_typeList[data.num]..".csb")
    self:addChild(self.scoreGenera,1)
    self.scoreGenera:findChild("lbs_content"):setString(util_AutoLineWrap(math.abs(tonumber(data.num))).."")
    -- if self.m_isLast and self.m_typeList[data.num] == 1 then

    -- else
    --     self.scoreGenera:playAction("idle",true)
    -- end
    self.scoreGenera:playAction("idleframe",true)
end

function PowerUpTowerLevelItem:showWinning()
    if self.m_isLast then
        self.scoreGenera:playAction("actionframe2",true)
    else
        self.scoreGenera:playAction("actionframe",true)
    end
    -- if self.m_isLast and self.m_typeList[self.m_data.num] == 1 then

    -- else
    --     self.scoreGenera:playAction("actionframe2",true)
    -- end

end
function PowerUpTowerLevelItem:showIdle()
    self.scoreGenera:playAction("idleframe",true)
    -- if self.m_isLast and self.m_typeList[self.m_data.num] == 1 then
    --     self.scoreGenera:playAction("idle2",true)
    -- else
    --     self.scoreGenera:playAction("idle",true)
    -- end
end
function PowerUpTowerLevelItem:showStop()
    self.scoreGenera:playAction("idleframe",true)
    -- if self.m_isLast and self.m_typeList[self.m_data.num] == 1 then
    --     self.scoreGenera:playAction("stop1",true)
    -- else
    --     self.scoreGenera:playAction("stop",true)
    -- end
end

function PowerUpTowerLevelItem:onEnter()


end

function PowerUpTowerLevelItem:onExit()

end

--默认按钮监听回调
function PowerUpTowerLevelItem:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return PowerUpTowerLevelItem