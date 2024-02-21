---
--xcyy
--2018年5月23日
--DragonsChooseTypeView.lua

local DragonsChooseTypeView = class("DragonsChooseTypeView",util_require("base.BaseView"))


function DragonsChooseTypeView:initUI(data)
    local _type = data._type
    local strName = "Dragons_xuanze_" .. _type .. ".csb"
    self:createCsbNode(strName)
    
    self:runCsbAction("idleframe",true) -- 播放时间线
    
    self:findChild("xuanze_guang_00_1"):setVisible(false)
    local touch =self:findChild("Panel_2")
    if touch then
        self:addClick(touch)
    end
    self.m_type = data._type

end

function DragonsChooseTypeView:showTypeBg(_bShow)
    self:findChild("xuanze_guang_00_1"):setVisible(_bShow)
end

function DragonsChooseTypeView:onEnter()
 
end


function DragonsChooseTypeView:onExit()
 
end

function DragonsChooseTypeView:playChangeNumEffect(_num)


    self:runCsbAction("add",false,function(  )
        self:runCsbAction("idleframe",true)
    end) 
    performWithDelay(
        self,
        function()
            self:findChild("BitmapFontLabel_1"):setString("x" .. _num)
        end,
       1/3
    )

    -- local eventFrameCall = function(frame)
    --     local eventName = frame:getEvent()
    --     if eventName == "change" then
    --        
    --     end
    -- end
  
    -- -- self.m_csbAct
    -- -- self.m_csbAct:clearFrameEventCallFunc()
    -- self.m_csbAct:setFrameEventCallFunc(eventFrameCall)
    -- self.m_csbAct:play("add", false)
    -- self.m_csbAct:gotoFrameAndPlay(350, 450, false)
    -- self.m_csbAct:runAction(nodeAction)
end

function DragonsChooseTypeView:setParent(parent)
    self.m_parent = parent
end

--默认按钮监听回调
function DragonsChooseTypeView:clickFunc(sender)

    local name = sender:getName()
    if name == "Panel_2" then
        self.m_parent:chooseFreeSpinType(self.m_clickPos)
    end
end

function DragonsChooseTypeView:setClickPos(_pos)
    self.m_clickPos = _pos
end

function DragonsChooseTypeView:getClickPos()
   return self.m_clickPos
end

function DragonsChooseTypeView:setViewData(_data)
    if _data then
        self:findChild("BitmapFontLabel_1"):setString("x" .. _data[1])
        self:findChild("BitmapFontLabel_2"):setString("x" .. _data[2])
        self:findChild("BitmapFontLabel_3_0"):setString("x" .. _data[3])
        self:findChild("BitmapFontLabel_3"):setString("x" .. _data[4])
        self.m_num = _data[1]
    end
end


return DragonsChooseTypeView