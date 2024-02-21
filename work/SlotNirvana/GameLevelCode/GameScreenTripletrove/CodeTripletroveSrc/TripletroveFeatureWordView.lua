---
--xcyy
--2018年5月23日
--TripletroveFeatureWordView.lua

local TripletroveFeatureWordView = class("TripletroveFeatureWordView",util_require("Levels.BaseLevelDialog"))


function TripletroveFeatureWordView:initUI(index)
    local file = self:changeCaseFile(index)
    self:createCsbNode(file)
    self.m_redWordList = {}

end

function TripletroveFeatureWordView:changeCaseFile(index)
    if index == 1 then
        return "Tripletrove_lanzi.csb"
    elseif index == 2 then
        return "Tripletrove_jinzi.csb"
    elseif index == 3 then
        return "Tripletrove_hongzi.csb"
    end
end

function TripletroveFeatureWordView:updateBlueShow(func)
    self:runCsbAction("actionframe",false)
    performWithDelay(self,function (  )
        if func then
            func()
        end
    end,1/6)
end

function TripletroveFeatureWordView:clearResWordList( )
    for i,v in ipairs(self.m_redWordList) do
        v:removeFromParent()
    end
    self.m_redWordList = {}
end

function TripletroveFeatureWordView:initRedWordShow(index)
    self:clearResWordList()
    for i = 0,index do
        local fork = util_createAnimation("Tripletrove_hongzi_cha.csb")
        local pos = util_convertToNodeSpace(self:findChild("Socre_tripletrove_" .. i),self)
        self:addChild(fork)
        fork:setPosition(pos)
        fork:runCsbAction("idle")
        table.insert(self.m_redWordList,fork)
    end
end

function TripletroveFeatureWordView:updateRedCaseShow(index)
    local fork = util_createAnimation("Tripletrove_hongzi_cha.csb")
    local pos = util_convertToNodeSpace(self:findChild("Socre_tripletrove_" .. index),self)
    self:addChild(fork)
    fork:setPosition(pos)
    fork:runCsbAction("start",false,function (  )
        fork:runCsbAction("idle")
    end)
    table.insert(self.m_redWordList,fork)
end

--不触发free的压黑
function TripletroveFeatureWordView:showDarkEffect( )
    self:runCsbAction("darkstart",false,function (  )
        self:runCsbAction("darkidle")
    end)
    for i,v in ipairs(self.m_redWordList) do
        v:runCsbAction("darkstart",false,function (  )
            v:runCsbAction("darkidle")
        end)
    end
end

function TripletroveFeatureWordView:triggerFreeWordShow()
    self:setVisible(false)
end

function TripletroveFeatureWordView:showLightEffect(isRed)
    self:setVisible(true)
    self:runCsbAction("idle")
    if isRed then
        for i,v in ipairs(self.m_redWordList) do
            v:runCsbAction("idle")
        end
    end
end

return TripletroveFeatureWordView