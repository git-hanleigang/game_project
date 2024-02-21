local LinkFishBnousGameItem = class("LinkFishBnousGameItem", util_require("base.BaseView"))
-- 构造函数
LinkFishBnousGameItem.m_bSelected = nil
function LinkFishBnousGameItem:initUI(data)
    self.m_iRow = data.row
    self.m_iLevel = data.levelID
    local resourceFilename = "Bonus_LinkFish_"..self.m_iRow..".csb"
    self:createCsbNode(resourceFilename)
    self.m_clickFlag = true
    self:addClick(self:findChild("click"))
end

function LinkFishBnousGameItem:idle()
    self:runCsbAction("actionframe", true)
end

function LinkFishBnousGameItem:click(coin, callback, func)
    gLobalSoundManager:playSound("LinkFishSounds/sound_LinkFish_bonusgame_choose.mp3")
    self.m_bSelected = true
    self.m_csbOwner["font_shu"]:setString(util_formatCoins(coin, 3, false, true, true))
    if coin == 0 then
        self.m_csbOwner["font_shu"]:setVisible(false)
        local extraGame = util_createView("CodeLinkFishSrc.LinkFishBnousExtraGamesChoose")
        self.m_csbOwner["Node_2"]:addChild(extraGame)
        extraGame:animation(self.m_iLevel)
    end
    self:runCsbAction("click", false, function()
        self:runCsbAction("idleframe1", true)
        if callback ~= nil then
            callback()
        end
        if func ~= nil then
            performWithDelay(self, function()
                func()
            end, 2)
        end
    end)
end

function LinkFishBnousGameItem:unclick(coin)
    self.m_csbOwner["font_shu"]:setString(util_formatCoins(coin, 3, false, true, true))
    if coin == 0 then
        self.m_csbOwner["font_shu"]:setVisible(false)
        local extraGame = util_createView("CodeLinkFishSrc.LinkFishBnousExtraGamesChoose")
        extraGame:unselected(self.m_iLevel)
        self.m_csbOwner["Node_2"]:addChild(extraGame)
    end
    self:runCsbAction("actionframe2", false)
end

function LinkFishBnousGameItem:showSelected(coin)
    self.m_bSelected = true
    self.m_csbOwner["font_shu"]:setString(util_formatCoins(coin, 3, false, true, true))
    if coin == 0 then
        self.m_csbOwner["font_shu"]:setVisible(false)
        local extraGame = util_createView("CodeLinkFishSrc.LinkFishBnousExtraGamesChoose")
        self.m_csbOwner["Node_2"]:addChild(extraGame)
        extraGame:selected(self.m_iLevel)
    end
    self:runCsbAction("idleframe1", false)
end

function LinkFishBnousGameItem:unselected(coin)
    self.m_csbOwner["font_shu"]:setString(util_formatCoins(coin, 3, false, true, true))
    if coin == 0 then
        self.m_csbOwner["font_shu"]:setVisible(false)
        local extraGame = util_createView("CodeLinkFishSrc.LinkFishBnousExtraGamesChoose")
        extraGame:unselected(self.m_iLevel)
        self.m_csbOwner["Node_2"]:addChild(extraGame)
    end
    self:runCsbAction("unselect", false)
end

function LinkFishBnousGameItem:canNotClick()
    self:runCsbAction("Dark", false)
end

function LinkFishBnousGameItem:setClickFunc(func)
    self.m_clickFunc = func
end

--默认按钮监听回调
function LinkFishBnousGameItem:clickFunc(sender)
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

function LinkFishBnousGameItem:getIsSelected()
    return self.m_bSelected
end

function LinkFishBnousGameItem:onEnter()
    
end

function LinkFishBnousGameItem:onExit()
    
end

function LinkFishBnousGameItem:setClickFlag(flag)
    self.m_clickFlag = flag
end

return LinkFishBnousGameItem