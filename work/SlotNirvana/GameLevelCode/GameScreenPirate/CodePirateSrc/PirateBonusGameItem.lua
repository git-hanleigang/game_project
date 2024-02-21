local PirateBonusGameItem = class("PirateBonusGameItem", util_require("base.BaseView"))
-- 构造函数
PirateBonusGameItem.m_bSelected = nil
PirateBonusGameItem.m_bUnSelected = nil
function PirateBonusGameItem:initUI(data)
    self.m_type = data.type
    self.m_iLevel = data.levelID
    local resourceFilename = "Bonus_Pirate_"..self.m_type..".csb"
    self:createCsbNode(resourceFilename)
    self.m_clickFlag = false
    self.m_bText = false
    self:addClick(self:findChild("click"))
    self.m_bUnSelected = false
end

function PirateBonusGameItem:idle()
    self:runAnim("idleframe1", true)
end

function PirateBonusGameItem:click(coin, unselectFunc, callback, func)
    -- gLobalSoundManager:playSound("PirateSounds/sound_Pirate_bonusgame_choose.mp3")
    self.m_bSelected = true
    self.m_csbOwner["font_shu"]:setString(util_formatCoins(coin, 3, false, true, true))
    if coin == 0 then
        self.m_csbOwner["font_shu"]:setString("")
        local extraGame = util_createView("CodePirateSrc.PirateBonusExtraGamesChoose")
        self.m_csbOwner["Node_1"]:addChild(extraGame)
        extraGame:animation(self.m_iLevel)
    end
    self:runAnim("click", false, function()
        if coin ~= 0 and unselectFunc ~= nil then
            unselectFunc()
        end
        self:runAnim("over1", false, function()
            self:runAnim("idleframe2", false, function()
                if callback ~= nil then
                    callback()
                end
            end)
        end)
    end)

    if func ~= nil then
        performWithDelay(self, function()
            func()
        end, 3)
    end
end

function PirateBonusGameItem:unclick(coin)
    if self.m_bUnSelected == true then
        return
    end
    self.m_csbOwner["font_shu"]:setString(util_formatCoins(coin, 3, false, true, true))
    if coin == 0 then
        self.m_csbOwner["font_shu"]:setString("")
        local extraGame = util_createView("CodePirateSrc.PirateBonusExtraGamesChoose")
        extraGame:unselected(self.m_iLevel)
        self.m_csbOwner["Node_1"]:addChild(extraGame)
    end
    self:runAnim("over2", false, function()
        self:unselect()
    end)
end

function PirateBonusGameItem:unselect()
    self.m_bUnSelected = true
    self:runAnim("unselect", false)
end

function PirateBonusGameItem:showSelected(coin)
    self.m_bSelected = true
    self.m_csbOwner["font_shu"]:setString(util_formatCoins(coin, 3, false, true, true))
    if coin == 0 then
        self.m_csbOwner["font_shu"]:setString("")
        local extraGame = util_createView("CodePirateSrc.PirateBonusExtraGamesChoose")
        self.m_csbOwner["Node_1"]:addChild(extraGame)
        extraGame:selected(self.m_iLevel)
    end
    self:runAnim("idleframe2", false)
end

function PirateBonusGameItem:canNotClick()
    self:runAnim("dark", false)
end

function PirateBonusGameItem:setClickFunc(func)
    self.m_clickFunc = func
end

--默认按钮监听回调
function PirateBonusGameItem:clickFunc(sender)
    if self.m_clickFlag == false then
        return
    end
    self.m_clickFlag = false
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_clickFunc ~= nil then
        self.m_clickFunc()
    end
end

function PirateBonusGameItem:runAnim(action, loop, func)
    self:runCsbAction(action, loop, func, 60)
end

function PirateBonusGameItem:getIsSelected()
    return self.m_bSelected
end

function PirateBonusGameItem:onEnter()

end

function PirateBonusGameItem:onExit()

end

function PirateBonusGameItem:setClickFlag(flag)
    self.m_clickFlag = flag
end
function PirateBonusGameItem:setText(flag)
    self.m_bText = flag
end

return PirateBonusGameItem