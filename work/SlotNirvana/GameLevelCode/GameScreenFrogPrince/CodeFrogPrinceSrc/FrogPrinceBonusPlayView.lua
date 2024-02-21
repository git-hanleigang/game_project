---
--xhkj
--2018年6月11日
--FrogPrinceBonusPlayView.lua

local FrogPrinceBonusPlayView = class("FrogPrinceBonusPlayView", util_require("base.BaseView"))

FrogPrinceBonusPlayView.boxVec = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"}

function FrogPrinceBonusPlayView:initUI(data)
    self:createCsbNode("FrogPrince_BonusGame2.csb")
    self:InitBoxView()

    self.m_firstTouch = true
    self.m_selectPosVec = {}
    self.m_selectNum = 0
    local prize = data.prize
    local lab = self:findChild("BitmapFontLabel_2")
    lab:setString(util_formatCoins(prize, 5))
    self:runCsbAction("start1")
end

function FrogPrinceBonusPlayView:InitBoxView()
    self.m_boxVec = {}
    for i, v in ipairs(self.boxVec) do
        local node = self:findChild("Node_" .. i)
        local data = {}
        data._value = v
        local box = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusBox", data)
        local pos = cc.p(node:getPosition())
        box:setScale(0.6)
        self:findChild("Node_32"):addChild(box)
        box:setTag(i)
        local func = function()
            self:clickItemCallFunc(i, box:getTag())
        end
        box:setClickFunc(func)
        box:setParent(self)
        box:setClickFlag(true)
        box:setPosition(pos)
        table.insert(self.m_boxVec, box)
        box:runCsbAction("idleframe1")
    end
    self:InitBonusUi()
    self:showBonusWinLab()
end

function FrogPrinceBonusPlayView:playChooseNun(_num)
    self:findChild("Node_62"):setVisible(true)
    local labNum = self:findChild("BitmapFontLabel_1")
    labNum:setString(_num)
    self:runCsbAction("idle2")
end
--获取位置对应的字母
function FrogPrinceBonusPlayView:getValueByPos(pos)
    return self.boxVec[pos]
end

function FrogPrinceBonusPlayView:clickItemCallFunc(index, pos)
    if self.m_bClickFlag == false then
        return
    end
    local item = self.m_boxVec[index]
    item:setClickFlag(false)
    item:setSelectClick()
    if item:getTag() == pos then
        gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_click_box.mp3")
        self.m_selectNum = self.m_selectNum + 1
        self.m_selectPosVec[self.m_selectNum] = pos
        local num = self.m_parent:getChooseCount() - self.m_selectNum
        if self.m_parent:getChooseRound() == 1 then
            num = num + 1
        end
        self:setChooseNum(num)
        if self.m_parent:getChooseRound() == 1 and self.m_selectNum == 1 then
            self.m_bClickFlag = false
            self:playBoxMovetoWinPos(pos)
        end
        local selectNum = self.m_parent:getChooseCount()
        if self.m_parent:getChooseRound() == 1 then
            selectNum = selectNum + 1
        end
        if self.m_selectNum == selectNum then
            self.m_parent:sendData(self.m_selectPosVec)
            self.m_bClickFlag = false
        end
    end
end

function FrogPrinceBonusPlayView:setChooseNum(_num)
    local labNum = self:findChild("BitmapFontLabel_1")
    labNum:setString(_num)
    if _num <= 0 then
        performWithDelay(
            self,
            function()
                self:findChild("Node_62"):setVisible(false)
            end,
            0.5
        )
    end
end
function FrogPrinceBonusPlayView:setClickFlag(_flag)
    self.m_bClickFlag = _flag
end
function FrogPrinceBonusPlayView:getClickFlag()
    return self.m_bClickFlag
end

--显示基础数值
function FrogPrinceBonusPlayView:InitBonusUi()
    self.m_girl = util_spineCreate("FrogPrince_bonus_gongzhu", true, true)
    util_spinePlay(self.m_girl, "idleframe1", true)
    self:findChild("gongzhu"):addChild(self.m_girl, 100)
end

--显示基础数值
function FrogPrinceBonusPlayView:showBonusWinLab()
    self:findChild("FrogPrince_BonusGame_tb1_1"):setVisible(true)
    self:findChild("FrogPrince_BonusGame2_text2_1"):setVisible(true)
    self:findChild("FrogPrince_BonusGame_tb1_1_0"):setVisible(true)
    self:findChild("FrogPrince_BonusGame_tb2_4"):setVisible(true)
    self:findChild("FrogPrince_BonusGame2_text2_2"):setVisible(true)
    self:findChild("BitmapFontLabel_2"):setVisible(true)
    self:findChild("FrogPrince_baoxiang"):setVisible(true)
    if self.m_winBox ~= nil then
        self.m_winBox:setVisible(true)
    end
    self.m_girl:setVisible(false)
    util_spinePlay(self.m_girl, "over", false)
    self:findChild("FrogPrince_BonusGame_zhuotai_1"):setVisible(false)
    self:findChild("baoxiang"):setVisible(false)
    self:findChild("gongzhu"):setVisible(false)
    self:removeOpenBox()
end

--显示开箱
function FrogPrinceBonusPlayView:showBonusOpenBoxView()

    self:findChild("FrogPrince_BonusGame_zhuotai_1"):setVisible(true)
    self:findChild("baoxiang"):setVisible(true)
    self:findChild("gongzhu"):setVisible(true)
    util_spinePlay(self.m_girl, "start", false)
    util_spineEndCallFunc(
        self.m_girl,
        "start",
        function()
            util_spinePlay(self.m_girl, "idleframe1", false)
        end
    )
    self.m_girl:setVisible(true)
end

function FrogPrinceBonusPlayView:removeOpenBoxPos()
end

--播放一轮打开箱子的动画
function FrogPrinceBonusPlayView:playOpenBoxOneRound()
    self:showBonusOpenBoxView()
    local round = self.m_parent:getChooseRound() - 1
    self.m_OpenNum = self.m_parent:getNeedOpenBoxNum(round)
    self.m_OpenAddNum = 1
    gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_tip_small.mp3")
    self:runCsbAction(
        "suoxiao",
        false,
        function()
            self:playOpenBoxEffect()
        end
    )
end

--播放一个打开箱子
function FrogPrinceBonusPlayView:playOpenBoxEffect()
    if self.m_OpenAddNum > self.m_OpenNum then
        self.m_parent:ChangePlayAndChooseView(false)
        self.m_selectNum = 0
        self.m_selectPosVec = {}
        self:setClickFlag(true)
        return
    end
    local pos = self.m_parent:getDisPiggy(self.m_OpenAddNum)
    local multiples = self.m_parent:getDisMultiples(self.m_OpenAddNum)
    self:removeOpenBox()
    util_spinePlay(self.m_girl, "idleframe1", false)
    self:showBoxMovetoOpenPos(
        pos,
        multiples,
        function()
            self:playOpenBoxEffect()
        end
    )
    self.m_OpenAddNum = self.m_OpenAddNum + 1
end

function FrogPrinceBonusPlayView:playBoxMovetoWinPos(pos)
    local value = self:getValueByPos(pos)
    local data = {}
    data._value = value
    data._pos = pos

    self.m_winBox  = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusBox", data)
    local node = self:findChild("Node_" .. pos)
    local slotParent = node:getParent()
    local posWorld = slotParent:convertToWorldSpace(cc.p(node:getPositionX(), node:getPositionY()))
    local startPos = self:findChild("FrogPrince_baoxiang"):convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
    self.m_winBox:setScale(0.6)
    self:findChild("FrogPrince_baoxiang"):addChild(self.m_winBox , 99)
    self.m_winBox:setClickFlag(false)
    self.m_winBox:setPosition(startPos)
    self.m_winBox:runCsbAction("idleframe7")
    local endpos = cc.p(0,0)
    local moveto = cc.MoveTo:create(0.75, endpos)
    local scaleto = cc.ScaleTo:create(0.75, 0.8)
    local spw = cc.Spawn:create(moveto, scaleto)
    local delay = cc.DelayTime:create(0.5)
    self.m_boxVec[pos]:runCsbAction("idle3")
    gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_box_fly.mp3")
    local movetoFunc =
        cc.CallFunc:create(
        function()
            local round = self.m_parent:getChooseRound()
            local num = self.m_parent:getChooseCount()
            local data = {}
            data.round = round
            data.num = num
            self.m_parent:showBonusRoundView(
                data,
                function()
                    self.m_winBox:runCsbAction("idleframe7")
                    local num = self.m_parent:getChooseCount()
                    self:playChooseNun(num)
                    self.m_bClickFlag = true
                end
            )
        end
    )
    local seq = cc.Sequence:create(delay, spw, movetoFunc)
    self.m_winBox:runAction(seq)
end

function FrogPrinceBonusPlayView:showBoxMovetoOpenPos(pos, multiples, func)
    
    local value = self:getValueByPos(pos)
    local data = {}
    data._value = value
    data._pos = pos
    data._multiples = multiples

    self.m_openBox  = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusBox", data)
    local node = self:findChild("Node_" .. pos)
   
    local slotParent = node:getParent()
    local posWorld = slotParent:convertToWorldSpace(cc.p(node:getPositionX(), node:getPositionY()))
    local startPos = self:findChild("baoxiang"):convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
    self.m_openBox :setScale(0.6*0.5)
   
    self:findChild("baoxiang"):addChild(self.m_openBox)
    self.m_openBox:setClickFlag(false)
    self.m_openBox:setPosition(startPos)
    self.m_openBox:runCsbAction("idleframe2")

    gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_box_fly.mp3")
    local endpos = cc.p(0,0)
    local moveto = cc.MoveTo:create(0.75, endpos)
    local scaleto = cc.ScaleTo:create(0.75, 1)
    local spw = cc.Spawn:create(moveto, scaleto)
    local delay = cc.DelayTime:create(0.25)
    self.m_boxVec[pos]:runCsbAction("idle3")
    local movetoFunc =
        cc.CallFunc:create(
        function()
            self.m_openBox:runCsbAction("idleframe2")
            local str = "actionframe1"
            if multiples > 50 then
                str = "actionframe2"
                gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_girl_hui2.mp3")
            else
                gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_girl_hui.mp3")
            end
            util_spinePlay(self.m_girl, str, false)
            util_spineFrameEvent(
                self.m_girl,
                str,
                "Open",
                function()
                    self.m_openBox:runCsbAction(
                        "actionframe3",
                        false,
                        function()
                            self.m_parent:showMultipleOver(multiples)
                            gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_box_open.mp3")
                            self.m_openBox:runCsbAction("idleframe5", false)
                            performWithDelay(
                                self,
                                function()
                                    if func ~= nil then
                                        func()
                                    end
                                end,
                                1.0
                            )
                        end
                    )
                end
            )
            -- util_spineEndCallFunc(
            --     self.m_girl,
            --     "actionframe1",
            --     function()

            --     end
            -- )
        end
    )
    local seq = cc.Sequence:create(delay, spw, movetoFunc)
    self.m_openBox:runAction(seq)
end

function FrogPrinceBonusPlayView:removeOpenBox()
    if self.m_openBox ~= nil then
        self.m_openBox:removeFromParent()
        self.m_openBox = nil
    end
end

function FrogPrinceBonusPlayView:setCollectBox(num)
    for i = 1, num do
        local box = self.m_boxVec[i]
        box:runCsbAction("idleframe2")
    end
end

function FrogPrinceBonusPlayView:onEnter()
end

function FrogPrinceBonusPlayView:setParent(parent)
    self.m_parent = parent
end

function FrogPrinceBonusPlayView:onExit()
end

function FrogPrinceBonusPlayView:InitUIData(spinData)
    local leftPiggy = spinData.p_selfMakeData.bonusPickData.leftPiggy
    if leftPiggy then
        local function isOpenPiggy(_multiple)
            for i = 1, #leftPiggy do
                if _multiple == leftPiggy[i] then
                    return false
                end
            end
            return true
        end

        for i = 1, #self.m_boxVec do
            local box = self.m_boxVec[i]
            box:runCsbAction("idle3")
            box:setClickFlag(false)
            if isOpenPiggy(i) == false then
                box:setClickFlag(true)
                box:runCsbAction("idleframe1")
            end
        end
        local pos = spinData.p_selfMakeData.bonusPickData.yourPiggy
        if pos ~= -1 then
            local data = {}
            data._pos = pos
            local value = self:getValueByPos(pos)
            data._value = value
            self.m_winBox = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusBox", data)
            self.m_winBox:setScale(0.8)
            self:findChild("FrogPrince_baoxiang"):addChild(self.m_winBox)
            self.m_winBox:runCsbAction("idleframe7")
            local endpos = cc.p(self:findChild("FrogPrince_baoxiang"):getPosition())
            -- self.m_winBox:setPosition(endpos)
        end
        local prize = spinData.p_selfMakeData.bonusPickData.collectCoins
        local lab = self:findChild("BitmapFontLabel_2")
        lab:setString(util_formatCoins(prize, 5))
    end
end

return FrogPrinceBonusPlayView
