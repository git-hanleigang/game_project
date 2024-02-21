---
--xhkj
--2018年6月11日
--FrogPrinceBonusLastChooseView.lua

local FrogPrinceBonusLastChooseView = class("FrogPrinceBonusLastChooseView", util_require("base.BaseView"))

function FrogPrinceBonusLastChooseView:initUI(data)
    self:createCsbNode("FrogPrince_BonusGame6.csb")
    self:createGirl()
    local  bestOffer = data.bestOffer
    local lab = self:findChild("BitmapFontLabel_1")
    lab:setString(bestOffer .. "X")
    self.m_bClickFlag = false
    self:runCsbAction("start",false,function(  )
        self.m_bClickFlag = true
    end)
end

function FrogPrinceBonusLastChooseView:onEnter()

end

function FrogPrinceBonusLastChooseView:onExit()

end


function FrogPrinceBonusLastChooseView:createBox(data1,data2,myPos)
    self.m_myPos = myPos
    self.box1 = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusBox",data1)
    -- self.box1:setScale(0.6)
    self:findChild("baoxiang_0"):addChild(self.box1)
    self.box1:setParent(self)
    self.box1:setTag(data1._pos)
    self.box1:setClickFlag(false)
    self:findChild("Button_1"):setTag(data1._pos)
    -- local func1 = function ()
    --     self:clickItemCallFunc(1,self.box1:getTag())
    -- end
    -- self.box1:setClickFunc(func1)
    if myPos == data1._pos then
        self.box1:runCsbAction("idleframe7")
    end

    self.box2 = util_createView("CodeFrogPrinceSrc.FrogPrinceBonusBox",data2)
    -- self.box2:setScale(0.6)
    self.box2:setParent(self)
    self:findChild("baoxiang"):addChild( self.box2)
    self.box2:setTag(data2._pos)
    self.box2:setClickFlag(false)
    -- local func2 = function ()
    --     self:clickItemCallFunc(2,self.box2:getTag())
    -- end
    -- self.box2:setClickFunc(func2)
    self:findChild("Button_2"):setTag(data2._pos)
    if myPos == data2._pos then
        self.box2:runCsbAction("idleframe7")
    end
end

function FrogPrinceBonusLastChooseView:clickItemCallFunc(index, pos)
    
    if self.m_bClickFlag == false then
        return 
    end
    self.m_bClickFlag = false
    gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_click_box.mp3")
    local item = nil 
    if index ==1 then
        item = self.box1
    else
        item = self.box2
    end
    self.m_selectItem = item
    item:setClickFlag(false)
    item:setSelectClick()
    if item:getTag() == pos then
        local data = {}
        table.insert(data,pos)
        self.m_parent:sendData(data)
    end
end

function FrogPrinceBonusLastChooseView:setClickFlag(_flag)
    self.m_bClickFlag = _flag
end

function FrogPrinceBonusLastChooseView:getClickFlag()
    return  m_bClickFlag
end

function FrogPrinceBonusLastChooseView:createGirl()
    self.m_girl = util_spineCreate("FrogPrince_bonus_gongzhu", true, true)
    self:findChild("gongzhu"):addChild(self.m_girl)
    self.m_girl:setScale(0.9)
    util_spinePlay(self.m_girl, "idleframe2", true)
end

function FrogPrinceBonusLastChooseView:setParent(parent)
    self.m_parent = parent
end

function FrogPrinceBonusLastChooseView:openBox(_num)
    self.m_selectItem:setLabNum(_num)
    gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_box_open.mp3")
    if  self.m_selectItem:getTag() == self.m_myPos then
        self.m_selectItem:runCsbAction(
            "actionframe",
            false,
            function()
                self.m_selectItem:runCsbAction("idleframe3", false)
                performWithDelay(
                    self,
                    function() 
                        self.m_parent:showBonusOverView()
                        self:removeFromParent()
                    end,
                    1.0
                )
            end
        )
    else
        self.m_selectItem:runCsbAction(
            "actionframe4",
            false,
            function()
                self.m_selectItem:runCsbAction("idleframe6", false)
                performWithDelay(
                    self,
                    function() 
                        self.m_parent:showBonusOverView()
                        self:removeFromParent()
                    end,
                    1.0
                )
            end
        )
    end

end

--默认按钮监听回调
function FrogPrinceBonusLastChooseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    local index = 1
    if name == "Button_1" then
        index = 1
    elseif name == "Button_2" then
        index = 2
    end
    self:clickItemCallFunc(index, tag)
end

return FrogPrinceBonusLastChooseView
