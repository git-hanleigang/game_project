local LinkFishBnousGameItem = class("LinkFishBnousGameItem", util_require("base.BaseView"))
-- 构造函数
LinkFishBnousGameItem.m_bSelected = nil
LinkFishBnousGameItem.m_bTwice = nil
function LinkFishBnousGameItem:initUI(data)
    self.m_iIndex = data
    local resourceFilename = "FortuneTree_BonusItem.csb"
    self:createCsbNode(resourceFilename)
    self:addClick(self:findChild("click"))
end

function LinkFishBnousGameItem:appear(func)
    self:runCsbAction("buling", false, function()
        self:idle()
        if func ~= nil then
            func()
        end
    end)
end

function LinkFishBnousGameItem:idle()
    self:runCsbAction("idle", true)
end

function LinkFishBnousGameItem:chooseIdle(index)
    self.m_bSelected = true
    self:runCsbAction("choose"..index, true)
end

function LinkFishBnousGameItem:overIdle(index)
    if self.m_bTwice == true then
        self:runCsbAction("choose"..index, true)
    end
    local effect, act = util_csbCreate("FortuneTree_jinbi_over.csb")
    self:addChild(effect, 100)
    util_csbPlayForKey(act, "actionframe", true)
    -- self:runCsbAction("idle"..index, true)
end

function LinkFishBnousGameItem:twiceItem(index)
    if self.m_bTwice ~= true then
        self:runCsbAction("idle"..index, true)
        self.m_bTwice = true
    end
    
end

function LinkFishBnousGameItem:click(index, callback, func)
    -- performWithDelay(self, function()
        gLobalSoundManager:playSound("FortuneTreeSounds/sound_FortuneTree_coin_choose.mp3")
    -- end, 0.2)
    
    self.m_bSelected = true
    self:runCsbAction("actionframe", false, function()
        self:runCsbAction("show"..index, false, function()
            self:chooseIdle(index)
            if callback ~= nil then
                callback()
            end
            if func ~= nil then
                func()
            end
        end)
    end)
end

function LinkFishBnousGameItem:unclick(index)
    self:runCsbAction("show"..index, false)
end


function LinkFishBnousGameItem:setClickFunc(func)
    self.m_clickFunc = func
end

--默认按钮监听回调
function LinkFishBnousGameItem:clickFunc(sender)
    if self.m_bSelected == true then
        return
    end
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_clickFunc ~= nil then
        self.m_clickFunc()
    end
end

function LinkFishBnousGameItem:onEnter()
    
end

function LinkFishBnousGameItem:onExit()
    
end

return LinkFishBnousGameItem