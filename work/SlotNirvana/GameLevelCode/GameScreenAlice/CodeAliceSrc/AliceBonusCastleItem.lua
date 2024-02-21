---
--xcyy
--2018年5月23日
--AliceView.lua

local AliceBonusCastleItem = class("AliceBonusCastleItem",util_require("base.BaseView"))

-- show  -开场的
-- idleframe
-- down  --点击
-- black --
-- 


function AliceBonusCastleItem:initUI(data)
    self:createCsbNode("Alice_BonusJp_card.csb")
    local touch=self:findChild("touch")
    self:addClick(touch)
    self.m_index = data
    self.isClick = false
    self.isShowItem = false

    self.m_nodeNum = self:findChild("Node_num")
    self.m_nodeJackpot = self:findChild("Node_jackpot")

    self:findChild("jp_30"):setVisible(false)
    self:findChild("jp_60"):setVisible(false)
    self:findChild("jp_90"):setVisible(false)
    self:findChild("jp_30an"):setVisible(false)
    self:findChild("jp_60an"):setVisible(false)
    self:findChild("jp_90an"):setVisible(false)

    util_setCascadeOpacityEnabledRescursion(self,true)
end

function AliceBonusCastleItem:updateUi(result)
    if result ~= "jackpot" then
        self.m_nodeNum:setVisible(true)
        self.m_nodeJackpot:setVisible(false)
        self:findChild("jp_"..result):setVisible(true)
        self:findChild("jp_"..result.."an"):setVisible(true)
    else
        self.m_nodeNum:setVisible(false)
        self.m_nodeJackpot:setVisible(true)
        
    end
end

function AliceBonusCastleItem:setClickFunc(func)
    self.m_func = func
end

function AliceBonusCastleItem:showItemStart()

    self:runCsbAction("start", true)
end

function AliceBonusCastleItem:showItemIdle()
    self:runCsbAction("idleframe1")
end

function AliceBonusCastleItem:showResult(result, func, callback)
    self.isShowItem = true
    self.isClick = true
    self:updateUi(result)
    self:runCsbAction("idle1", false, function()
        if func ~= nil then 
            func()
        end
        if callback ~= nil then
            callback()
        end
        if result == "jackpot" then
            self:findChild("Node_hui"):runAction(cc.FadeOut:create(0.3))
        end
    end)
    
    -- gLobalSoundManager:playSound("AZTECSounds/music_AZTEC_item_open.mp3")
end

function AliceBonusCastleItem:showSelected(result)
    self.isShowItem = true
    self.isClick = true
    if result ~= nil then
        self:updateUi(result)
    end
    self:runCsbAction("idleframe4")
end


function AliceBonusCastleItem:showUnselected(result)
    self.isShowItem = true
    self.isClick = true
    if result ~= "jackpot" then
        self.m_nodeNum:setVisible(true)
        self.m_nodeJackpot:setVisible(false)
        self:findChild("jp_"..result.."an"):setVisible(true)
    else
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_jackpot_heart.mp3")
        self.m_nodeNum:setVisible(false)
        self.m_nodeJackpot:setVisible(true)
        self:findChild("Node_hui"):setVisible(false)
    end
    self:runCsbAction("idle2")
end

function AliceBonusCastleItem:animationSelected2()
    self:runCsbAction("actionframe1")
end

function AliceBonusCastleItem:animationReward()
    self:runCsbAction("actionframe2", true)
end

function AliceBonusCastleItem:idleSeleted2()
    self:runCsbAction("idleframe3")
end

function AliceBonusCastleItem:showFailed()
    self.isShowItem = true
    self.isClick = true
    self:runCsbAction("idle4")
end

function AliceBonusCastleItem:onEnter()

end

function AliceBonusCastleItem:onExit()

end


function AliceBonusCastleItem:clickFunc(sender )
    if self.isClick or self.isShowItem then
        return
    end
    
    self.m_func(self.m_index)
end

function AliceBonusCastleItem:showItemStatus()
    return self.isShowItem
end

return AliceBonusCastleItem