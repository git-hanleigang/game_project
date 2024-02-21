---
--xhkj
--2018年6月11日
--FrogPrinceBonusChooseView.lua

local FrogPrinceBonusChooseView = class("FrogPrinceBonusChooseView", util_require("base.BaseView"))

function FrogPrinceBonusChooseView:initUI(data)
    self:createCsbNode("FrogPrince_BonusGame5.csb")
    self.m_clickFlag = false
    self:playStartAni()
end

function FrogPrinceBonusChooseView:playStartAni()
    self:runCsbAction(
        "start",
        false,
        function()
            self:createQingWa()
        end
    )
end

function FrogPrinceBonusChooseView:createQingWa()
  
    if  self.m_qingWa ~= nil then
        self.m_qingWa:setVisible(true)
    else
        self.m_qingWa = util_spineCreate("Socre_FrogPrince_Wild", true, true)
        self:findChild("Node_1"):addChild(self.m_qingWa)
    end
    util_spinePlay(self.m_qingWa, "start2", false)
    util_spineEndCallFunc(
        self.m_qingWa,
        "start2",
        function()
            self.m_clickFlag = true
            util_spinePlay(self.m_qingWa, "idleframe3", true)
        end
    )
end

function FrogPrinceBonusChooseView:showCollectWinLab(_multiple, _base)
    local lab1 = self:findChild("BitmapFontLabel_1")
    local lab2 = self:findChild("BitmapFontLabel_2")
    lab1:setString(_multiple .. "X")
    local winNum = _multiple * _base
    local win = util_formatCoins(winNum, 5)
    local base = util_formatCoins(_base, 3)
    lab2:setString(_multiple .. "X" .. base .. "=" .. win)
end

function FrogPrinceBonusChooseView:onEnter()
end

function FrogPrinceBonusChooseView:onExit()
end

--默认按钮监听回调
function FrogPrinceBonusChooseView:clickFunc(sender)
    if self.m_clickFlag == false then
        return
    end
    self.m_clickFlag = false
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    local name = sender:getName()
    if name == "Button_1" then
        util_spinePlay(self.m_qingWa, "over2", false)
        util_spineEndCallFunc(
            self.m_qingWa,
            "over2",
            function()
                self.m_qingWa:setVisible(false)
                self:runCsbAction(
                    "over",
                    false,
                    function()
                        self.m_parent:sendChooseMessage()
                    end
                )
            end
        )
    elseif name == "Button_1_0" then
        util_spinePlay(self.m_qingWa, "over2", false)
        util_spineEndCallFunc(
            self.m_qingWa,
            "over2",
            function()
                self.m_qingWa:setVisible(false)
                self:runCsbAction(
                    "over",
                    false,
                    function()
                        self.m_parent:ChangePlayAndChooseView(true)
                    end
                )
            end
        )
    end
end

function FrogPrinceBonusChooseView:setParent(parent)
    self.m_parent = parent
end

function FrogPrinceBonusChooseView:inintUIData()
end
return FrogPrinceBonusChooseView
