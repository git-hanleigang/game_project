---
--xcyy
--2018年5月23日
--PudgyPandaBasketView.lua
local PublicConfig = require "PudgyPandaPublicConfig"
local PudgyPandaBasketView = class("PudgyPandaBasketView",util_require("Levels.BaseLevelDialog"))
PudgyPandaBasketView.m_totalNum = 5
PudgyPandaBasketView.m_curCollectNum = 0

function PudgyPandaBasketView:initUI()

    self:createCsbNode("PudgyPanda_longti.csb")

    -- 集满spine（覆盖）
    self.m_collectFullSpine = util_spineCreate("PudgyPanda_longti",true,true)
    self:findChild("Node_spine"):addChild(self.m_collectFullSpine)
    self.m_collectFullSpine:setVisible(false)

    self:setIdle()

    self.m_baziAniTbl = {}
    for i=1, self.m_totalNum do
        self.m_baziAniTbl[i] = util_createAnimation("PudgyPanda_longti_baozi.csb")
        self:findChild("Node_baozi_"..i):addChild(self.m_baziAniTbl[i])
    end

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function PudgyPandaBasketView:setIdle()
    self:setVisible(true)
    self:runCsbAction("idle", true)
end

-- 当前收集的进度
function PudgyPandaBasketView:setCurCollectProcess(_collectNum, _isInit)
    local collectNum = _collectNum
    local isInit = _isInit
    if isInit then
        self:setIdle()
    end
    self.m_curCollectNum = _collectNum
    for i=1, self.m_totalNum do
        if collectNum >= i then
            self.m_baziAniTbl[i]:runCsbAction("idle", true)
        else
            self.m_baziAniTbl[i]:runCsbAction("idle2", true)
        end
    end
end

-- 收集动画
function PudgyPandaBasketView:playAddCollecteffect()
    self.m_curCollectNum = self.m_curCollectNum + 1
    local curCollectNum = self.m_curCollectNum
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_FatFeature_Basket_Add)
    if self.m_curCollectNum < self.m_totalNum then
        self.m_baziAniTbl[curCollectNum]:runCsbAction("actionframe", false, function()
            self.m_baziAniTbl[curCollectNum]:runCsbAction("idle", true)
        end)
    elseif self.m_curCollectNum == self.m_totalNum then
        self.m_baziAniTbl[curCollectNum]:runCsbAction("actionframe", false, function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_FatFeature_Basket_Full)
            self.m_baziAniTbl[curCollectNum]:runCsbAction("idle", true)

            self.m_curCollectNum = 0
            self:runCsbAction("idle2", true)
            self.m_collectFullSpine:setVisible(true)
            util_spinePlay(self.m_collectFullSpine, "actionframe", false)
            util_spineEndCallFunc(self.m_collectFullSpine, "actionframe", function()
                self:setIdle()
                self.m_collectFullSpine:setVisible(false)
                -- 包子消失
                self:runOverItem()
            end)
        end)
    end
end

-- 包子消失动画
function PudgyPandaBasketView:runOverItem()
    for i=1, self.m_totalNum do
        self.m_baziAniTbl[i]:runCsbAction("over", false, function()
            self.m_baziAniTbl[i]:runCsbAction("idle2", true)
        end)
    end
end

-- 获取当前是否集满了(收集的前一个判断是否挤满)
function PudgyPandaBasketView:getCurIsUpgrade()
    if self.m_curCollectNum == self.m_totalNum - 1 then
        return true
    end
    return false
end

function PudgyPandaBasketView:showOverAni(_onEnter)
    if _onEnter then
        self:setVisible(false)
    else
        self:runCsbAction("over", false, function()
            self:setVisible(false)
        end)
    end
end

return PudgyPandaBasketView
