
local LuxuryDiamondChooseView = class("LuxuryDiamondChooseView", util_require("Levels.BaseLevelDialog"))
LuxuryDiamondChooseView.JACKPOT_NAME_LIST = {"super","grand", "major", "minor","mini" }

function LuxuryDiamondChooseView:initUI(data, callBack)
    self.m_click = true
    self.m_max = 5
    self.m_jackpot = data
    self.m_boxItemTab = {}
    self.m_endCall = callBack
    local resourceFilename = "LuxuryDiamond/SuperFreeSpinStart.csb"
    self:createCsbNode(resourceFilename)
    self:addClick(self:findChild("Panel_9"))
    -- self:findChild("pickResult"):setVisible(false)
    -- self:findChild("pickOne"):setVisible(true)
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
        self.m_click = false
    end, 60)

    for i=1,self.m_max do
        local boxItem = self:createBoxItem(i)
        self:findChild("baoxiang_"..i):addChild(boxItem)
        table.insert(self.m_boxItemTab, boxItem)
    end
    util_setCascadeOpacityEnabledRescursion(self:findChild("root"),true)
    gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_Choose_show.mp3")
end

function LuxuryDiamondChooseView:onEnter()
    LuxuryDiamondChooseView.super.onEnter(self)
    self:randomIdleBox()
end

function LuxuryDiamondChooseView:onExit()
    LuxuryDiamondChooseView.super.onExit(self)
end

function LuxuryDiamondChooseView:clickFunc(sender)
    if self.m_click == true then
        return
    end
    self.m_click = true
    local tag = sender:getTag()
    local item = self.m_boxItemTab[tag]
    item.m_isClick = true
    self:showBox(item, self.m_jackpot[1])
    self:findChild("baoxiang_1"):stopAllActions()
    gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_superFree_choose.mp3")
    self:waitWithDelay(3, function()
        self:removeSelf()
    end)
end

function LuxuryDiamondChooseView:removeSelf()
    self.m_click = true
    self:runCsbAction("over", false, function()
        gLobalSoundManager:playSound("LuxuryDiamondSounds/sound_LuxuryDiamond_superFree_choose_end.mp3")
        if self.m_endCall then
            self.m_endCall()
        end
        self:removeFromParent()
    end)
end

function LuxuryDiamondChooseView:createBoxItem(index)
    local box = util_createAnimation("LuxuryDiamond_super_baoxiang.csb")
    box.box_spine = util_spineCreate("LuxuryDiamond_SuperFreeSpin", true, true)
    box:findChild("box_spine"):addChild(box.box_spine)
    util_spinePlay(box.box_spine, "idle")

    -- box.jackpot_spine = util_spineCreate("Socre_LuxuryDiamond_Baoshi", true, true)
    -- box:findChild("jackpot_spine"):addChild(box.jackpot_spine)
    -- box.jackpot_spine:setVisible(false)
    box:findChild("btn_click"):setTag(index)
    box.m_isClick = false
    self:addClick( box:findChild("btn_click") )
    return box
end

function LuxuryDiamondChooseView:showBox(item, jackpot_str)
    local box_spine = item.box_spine
    -- local jackpot_spine = item.jackpot_spine
    local skin_str = self:getJackpotSymbolSkin(jackpot_str)
    -- jackpot_spine:setSkin(skin_str)
    box_spine:setSkin(skin_str)
    for i,v in ipairs(self.JACKPOT_NAME_LIST) do
        self:findChild(v):setVisible(v == jackpot_str )
    end
    util_spinePlay(box_spine, "actionframe", false)
    util_spineEndCallFunc(box_spine, "actionframe", function()

        -- local time = 0.5
        -- self:findChild("pickResult"):setVisible(true)
        -- self:findChild("pickResult"):setOpacity(0)
        -- self:findChild("pickResult"):runAction(cc.FadeIn:create(time))
        -- self:findChild("pickOne"):runAction(cc.FadeOut:create(time))
        self:runCsbAction("switch", false, function()

        end)
    end)
    -- self:waitWithDelay(16/30, function()
    --     -- util_spinePlay(jackpot_spine, "buling")
    --     -- jackpot_spine:setVisible(true)
    --     util_spineEndCallFunc(jackpot_spine, "buling", function()
    --         util_spinePlay(jackpot_spine, "actionframe")
    --         local time = 0.5
    --         self:findChild("pickResult"):setVisible(true)
    --         self:findChild("pickResult"):setOpacity(0)
    --         self:findChild("pickResult"):runAction(cc.FadeIn:create(time))
    --         self:findChild("pickOne"):runAction(cc.FadeOut:create(time))
    --     end)
    -- end)
end

--皮肤名字
function LuxuryDiamondChooseView:getJackpotSymbolSkin(Jackpot_str)
    local skin_str = "mini"
    if Jackpot_str == "minor" then
        skin_str = "minor"
    elseif Jackpot_str == "major" then
        skin_str = "major"
    elseif Jackpot_str == "grand" then
        skin_str = "grand"
    elseif Jackpot_str == "super" then
        skin_str = "super"
    end
    return skin_str
end

function LuxuryDiamondChooseView:waitWithDelay(time, endFunc)
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

function LuxuryDiamondChooseView:randomIdleBox(  )
    local callFunc = function()
        local idleIndex = util_random(1,5)
        for index=1,self.m_max do
            local box = self.m_boxItemTab[index]
            local isIdle = index == idleIndex  --随机的idle动画
            if isIdle and box.m_isClick == false then
                util_spinePlay(box.box_spine, "idle")
            end
        end
    end
    util_schedule(self:findChild("baoxiang_1"), callFunc, 2)
end

return LuxuryDiamondChooseView