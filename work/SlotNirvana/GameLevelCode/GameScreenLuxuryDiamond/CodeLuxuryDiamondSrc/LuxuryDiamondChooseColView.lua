---
--xcyy
--2018年5月23日
--LuxuryDiamondChooseColView.lua

local LuxuryDiamondChooseColView = class("LuxuryDiamondChooseColView",util_require("Levels.BaseLevelDialog"))


function LuxuryDiamondChooseColView:initUI()

    self:createCsbNode("LuxuryDiamond/ChooseGame.csb")
    self.m_col = 5
    self.m_coinLabel = {}
    self.m_itemTab = {}
    self:addClick(self:findChild("zhezhao"))
    for index = 1, self.m_col do
        local item = util_createAnimation("LuxuryDiamond_choosegame.csb")
        self:findChild("tiaojie_"..index):addChild(item)
        self:addClick(item:findChild("click_Btn"))
        item:findChild("Button_1_0"):setTouchEnabled(false)
        item:findChild("click_Btn"):setTag(index)
        self:initItemCol(item, index)
        -- item:playAction("idle")
        table.insert(self.m_coinLabel, item:findChild("m_lb_coin"))
        table.insert(self.m_itemTab, item)

        item:findChild("Particle_1"):stopSystem()
        item:findChild("Particle_2"):stopSystem()
    end
    self.m_canClick = true

    -- gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_chooseView_start.mp3")
end


function LuxuryDiamondChooseColView:onEnter()
 
    LuxuryDiamondChooseColView.super.onEnter(self)
end

function LuxuryDiamondChooseColView:showAdd()
    
end

function LuxuryDiamondChooseColView:onExit()
    LuxuryDiamondChooseColView.super.onExit(self)
end

function LuxuryDiamondChooseColView:initItemCol(item, curIndex)
    for index = 1,self.m_col do
        item:findChild("tanbantiao_"..index):setVisible(index <= curIndex)
    end
end

--默认按钮监听回调
function LuxuryDiamondChooseColView:clickFunc(sender)
    if not self.m_canClick then
        return
    end
    self.m_canClick = false
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "zhezhao" then
        self:hideView()
        gLobalSoundManager:playSound("LuxuryDiamondSounds/LuxuryDiamond_JP_click.mp3")
    else
        gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_chooseView_click.mp3")
    
        self:setUI(tag, false)
    end
end

function LuxuryDiamondChooseColView:setUI(_tag, isOut)
    for i=1,#self.m_itemTab do
        if i == _tag then
            self.m_itemTab[i]:playAction("actionframe", false, function()
                if not isOut then
                    self:hideView(function()
                        gLobalNoticManager:postNotification("CHOOSE_LUXDIA", {_tag})
                    end)
                end
            end)
            if not isOut then
                self.m_itemTab[i]:findChild("Particle_1"):resetSystem()
                self.m_itemTab[i]:findChild("Particle_2"):resetSystem()
            end
        else
            self.m_itemTab[i]:playAction("dark", false, function()
            end)
        end
    end
end


function LuxuryDiamondChooseColView:hideView(callBack)
    gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_chooseView_over.mp3")
    self:runCsbAction("over", false, function()
        if callBack then
            callBack()
        end
        self:setVisible(false)
    end)
end

function LuxuryDiamondChooseColView:showView()
    gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_chooseView_start.mp3")
    self:setVisible(true)
    self:runCsbAction("start", false, function()
        self.m_canClick = true
        self:playIdle()
    end)
end

function LuxuryDiamondChooseColView:initcoins(coinsTab)
    for index = 1, self.m_col do
        local lable = self.m_coinLabel[index]
        local strCoins = util_formatCoins(coinsTab[index],3)
        lable:setString(strCoins)
    end
end

function LuxuryDiamondChooseColView:playIdle()
    self:runCsbAction("idle", true)
end

return LuxuryDiamondChooseColView