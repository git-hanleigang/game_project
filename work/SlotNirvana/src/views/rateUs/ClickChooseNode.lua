--点击选择
local ClickChooseNode = class("ClickChooseNode", util_require("base.BaseView"))

function ClickChooseNode:initUI(nameStr,clickCsbName,itemNum)
    local csbName = "RateUs/ClickChooseNode"
    if nameStr then
        csbName = nameStr
    end
    self:createCsbNode(csbName..".csb")

    self.m_unClickList = {}
    self.m_clickedList = {}
    for i=1,itemNum do
        local btn = self:findChild("btn"..i)
        self:addClick(btn)
        local unClick = self:findChild("unClick"..i)
        local clicked = self:findChild("clicked"..i)
        -- clicked:setVisible(false)
        self.m_unClickList[#self.m_unClickList+1] = unClick
        self.m_clickedList[#self.m_clickedList+1] = clicked
    end

    local selectCsbName = "RateUs/ClickChooseNode_bd"
    if clickCsbName then
        selectCsbName = clickCsbName
    end
    self.m_select = util_createAnimation(selectCsbName..".csb")
    self.m_select:setVisible(false)
    self:addChild(self.m_select)
end

function ClickChooseNode:initData(callback,clickCallBack)
    self.m_callback = callback
    self.m_clickCallBack = clickCallBack
    self:runCsbAction("show",true,nil,30)
end

--       口
-- 1  2  3  4  5
function ClickChooseNode:updateHighClicked(index)
    self.m_clickChoose = true
    self:runCsbAction("select",false,function()
        self.m_select:setPosition(cc.p(self.m_unClickList[index]:getPosition()))
        self.m_select:setVisible(true)
        self.m_select:playAction("idle",false,function()
            performWithDelay(self,function()
                if self.m_callback then
                    self.m_callback(index)
                end
            end,0.5)
        end,30)
    end,30)

    for i=1,#self.m_unClickList do
        if i < index then
            self.m_clickedList[i]:setVisible(true)
        else
            self.m_clickedList[i]:setVisible(false)
        end
    end
end

function ClickChooseNode:updateLowClicked(index)
    self.m_clickChoose = true
    self:runCsbAction("select",false,function()
        performWithDelay(self,function()
            if self.m_callback then
                self.m_callback(index)
            end
        end,0.2)
    end,30)
    for i=1,#self.m_unClickList do
        if i <= index then
            self.m_clickedList[i]:setVisible(true)
        else
            self.m_clickedList[i]:setVisible(false)
        end
    end
end

function ClickChooseNode:clearClicked()
    for i=1,#self.m_unClickList do
        self.m_unClickList[i]:setVisible(true)
        self.m_clickedList[i]:setVisible(false)
    end
    self.isClick = false
end

function ClickChooseNode:clickFunc(sender)
    if self.isClick then
        return
    end
    self.isClick = true
    local sBtnName = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if self.m_clickCallBack then
        self.m_clickCallBack()
    end
    local index = tonumber(string.sub(sBtnName,4,string.len(sBtnName)))
    if index == 5 then
        self:updateHighClicked(index)
    else
        self:updateLowClicked(index)
    end
    -- csc firebase 打点
    if globalFireBaseManager.sendFireBaseLogDirect then
        local key = "Rating"..index.."star"
        globalFireBaseManager:sendFireBaseLogDirect(key)
    end
end



return ClickChooseNode