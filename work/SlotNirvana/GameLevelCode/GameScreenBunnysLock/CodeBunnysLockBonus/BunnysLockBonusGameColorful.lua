---
--smy
--2018年4月26日
--BunnysLockBonusGameColorful.lua
--多福多彩玩法
local BunnysLockBonusGameColorful = class("BunnysLockBonusGameColorful",util_require("Levels.BaseLevelDialog") )

function BunnysLockBonusGameColorful:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("BunnysLock/BonusGame_Colorful.csb")
    self:setVisible(false)
    self.m_isWaitting = false

    self.m_egg_items = {}
    for index = 1,12 do
        local item = util_createView("CodeBunnysLockBonus.BunnysLockColorfulItem",{parentView = self})
        self:findChild("Node_dan_"..(index - 1)):addChild(item)
        self.m_egg_items[index] = item
    end

    self.m_jackpotBar = util_createView("CodeBunnysLockBonus.BunnysLockJackpotBar",{parentView = self,machine = self.m_machine})
    self:findChild("JackPotBarBunnysLock"):addChild(self.m_jackpotBar)

    self.m_curIndex = 1
    --正在飞行的粒子数量
    self.m_flyCount = 0
    self.m_isShowWinView = false

    self.m_brush = util_spineCreate("BunysLock_shuazi",true,true)
    self:addChild(self.m_brush)
    self.m_brush:setVisible(false)

    self.m_leftCollectCount = {
        grand = 3,
        major = 3,
        minor = 3,
        mini = 3
    }
end

function BunnysLockBonusGameColorful:showView(bonusData,func)
    self:setVisible(true)
    self:setEndCallFunc(func)
    self.m_curIndex = 1
    self.m_flyCount = 0
    self.m_isShowWinView = false

    self.m_leftCollectCount = {
        grand = 3,
        major = 3,
        minor = 3,
        mini = 3
    }

    self.m_bonusData = bonusData
    self.m_isWaitting = false
    for k,eggItem in pairs(self.m_egg_items) do
        eggItem:resetStatus()
    end

    self.m_jackpotBar:resetView()
end


function BunnysLockBonusGameColorful:hideView()
    self:setVisible(false)
end

--[[
    设置结束回调
]]
function BunnysLockBonusGameColorful:setEndCallFunc(func)
    self.m_endFunc = func
end

--获取剩余的类型
function BunnysLockBonusGameColorful:getLeftJackpotType()
    for jackpotType,count in pairs(self.m_leftCollectCount) do
        if count > 0 then
            self.m_leftCollectCount[jackpotType] = self.m_leftCollectCount[jackpotType] - 1
            return jackpotType
        end
    end
    return ""
end

--[[
    按钮回调
]]
function BunnysLockBonusGameColorful:clickFunc(eggItem)

    if self.m_isWaitting then
        return
    end
    self.m_isWaitting = true

    local process = self.m_bonusData.jackpot.process
    if self.m_curIndex > #process then
       return 
    end

    local jackpotType = process[self.m_curIndex]
    self.m_leftCollectCount[jackpotType] = self.m_leftCollectCount[jackpotType] - 1

    --刷子动画
    self.m_brush:setVisible(true)
    self.m_brush:setPosition(util_convertToNodeSpace(eggItem,self))
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_colorful_brush.mp3")
    util_spinePlay(self.m_brush,"actionframe")
    util_spineEndCallFunc(self.m_brush,"actionframe",function()
        self.m_brush:setVisible(false)
    end)

    self.m_curIndex = self.m_curIndex + 1
    eggItem:refreshUI(jackpotType,function()
        self.m_isWaitting = false

        local endNode = self.m_jackpotBar:getCurJackpotNode(jackpotType)
        self.m_flyCount = self.m_flyCount + 1
        self:flyChooseAni(eggItem,endNode,function()
            self.m_flyCount = self.m_flyCount - 1
            --刷新jackpot
            local isEnd = self.m_jackpotBar:refreshUI(jackpotType)
            --未中奖的蛋变黑
            if isEnd then
                for k,item in pairs(self.m_egg_items) do
                    if item.m_isClicked then
                        item:turnToDark(jackpotType)
                    else
                        --获取剩余的类型
                        local leftType = self:getLeftJackpotType()
                        item:turnToDark(jackpotType,leftType)
                    end
                end
                self.m_machine:delayCallBack(1.5,function()
                    self:showJackpotWin(function()
                        self:showWinCoinsView()
                    end)
                    
                end)
            end
            --等粒子都飞完
            if self.m_curIndex > #process and self.m_flyCount <= 0 then
                
            end
        end)
    end)
    
end

function BunnysLockBonusGameColorful:showJackpotWin(func)
    if self.m_isShowWinView then
        return
    end
    self.m_isShowWinView = true
    local jackpotType = self.m_bonusData.jackpot.winJackpot[1]
    self.m_machine:showJackpotWin(jackpotType,self.m_bonusData.jackpot_money,func)
end

function BunnysLockBonusGameColorful:showWinCoinsView()
    local params = {
        baseCoins = (self.m_bonusData.winAmount - self.m_bonusData.jackpot_money), --地图上的钱
        bonusCoins = self.m_bonusData.jackpot_money, --topdollar的钱
        winCoins = self.m_bonusData.winAmount
    }

    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_colorful_show_win.mp3")
    self.m_machine:showBonusWinView("colorful",params,function()
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_change_scene_colorful_exit.mp3")
        self.m_machine:showBonusStart("colorful",false,function()
            if type(self.m_endFunc) == "function" then
                self.m_endFunc()
                self.m_endFunc = nil
            end
            self:hideView()
        end)
    end)
end

--[[
    飞粒子动画
]]
function BunnysLockBonusGameColorful:flyChooseAni(startNode,endNode,func)
    --粒子
    local particle = util_createAnimation("BonusGameEgg_lizi.csb")
    particle:findChild("Particle_1"):setPositionType(0)


    local startPos = util_convertToNodeSpace(startNode,self)
    local endPos = util_convertToNodeSpace(endNode,self)

    self:addChild(particle,1000)
    particle:setPosition(startPos)

    local seq = cc.Sequence:create({
        cc.MoveTo:create(0.3,endPos),
        cc.CallFunc:create(function()
            if type(func) == "function" then
                func()
            end
            gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_colorful_fly_jp_feedback.mp3")
            particle:findChild("Particle_1"):stopSystem()
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_colorful_fly_jp.mp3")
    particle:runAction(seq)
end

return BunnysLockBonusGameColorful