---
--xcyy
--2018年5月23日
--PandaDeluxeChooseFsItem.lua

local PandaDeluxeChooseFsItem = class("PandaDeluxeChooseFsItem",util_require("base.BaseView"))
PandaDeluxeChooseFsItem.m_index = nil
PandaDeluxeChooseFsItem.m_clickIndex = nil

function PandaDeluxeChooseFsItem:initUI(data)

    self:createCsbNode("PandaDeluxe_cf.csb")
    self.m_index = data.index
    self.m_parent = data.parent
    self.m_clickIndex = data.clickIndex

    local nodeList = {"shu","yu","wugui","he","xiongmao","xiao_rell"}
    for i=1,#nodeList do
        if i ~= self.m_index then
            self:findChild(nodeList[i]):setVisible(false) 
        end
        
    end

    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听

    self.m_clickFlag = true
    util_setCascadeOpacityEnabledRescursion(self, true)
end


function PandaDeluxeChooseFsItem:onEnter()
 

end


function PandaDeluxeChooseFsItem:selected()

    self.m_parent:setClickData( self.m_clickIndex,self.m_index)
    self.m_clickFlag = false
end

function PandaDeluxeChooseFsItem:randomAnimation()


    self:runCsbAction("actionframe", false, function()

       

    end)
end

function PandaDeluxeChooseFsItem:unselected()
    self:runCsbAction("dark")
    self.m_clickFlag = false
end

function PandaDeluxeChooseFsItem:runIdle(func)
    if self.m_clickFlag == false then
        return
    end
    self:runCsbAction("idle", true)
end

function PandaDeluxeChooseFsItem:onExit()
 
end

--默认按钮监听回调
function PandaDeluxeChooseFsItem:clickFunc(sender)
    if self.m_clickFlag == false then
        return
    end
    self.m_clickFlag = false
    local name = sender:getName()
    local tag = sender:getTag()
    self:selected()
    
end


return PandaDeluxeChooseFsItem