---
--xcyy
--2018年5月23日
--MermaidLoadingBarView.lua

local MermaidLoadingBarView = class("MermaidLoadingBarView",util_require("base.BaseView"))

MermaidLoadingBarView.m_MaxQiPaoNum = 20
MermaidLoadingBarView.m_CurrQiPaoNum = 0

function MermaidLoadingBarView:initUI()

    self:createCsbNode("Mermaid_Jidutiao.csb")

    self.m_actPos = {}

    self:addClick(self:findChild("click"))
end

function MermaidLoadingBarView:onEnter()
 

end

function MermaidLoadingBarView:onExit()
 
end

function MermaidLoadingBarView:initMachine(machine)
    self.m_machine = machine
end

function MermaidLoadingBarView:initBarQiPao( )

    

    for i = 1, self.m_MaxQiPaoNum do
        self["qipao"..i] = util_createAnimation("Mermaid_Jidutiao_qipao.csb")
        self:findChild("jindutiao_qipao_" .. i):addChild(self["qipao"..i],i)
        self["qipao"..i].m_isOpen = false
        self["qipao"..i]:runCsbAction("idleframe1") 
        -- self["qipao"..i]:setVisible(false)
    end
end

function MermaidLoadingBarView:restLoadingQiPao( )

    for i = 1, self.m_MaxQiPaoNum do
        self["qipao"..i]:runCsbAction("idleframe1") 
        self["qipao"..i].m_isOpen = false
    end

end

function MermaidLoadingBarView:updateLoadingQiPao( collectTimes )

    local maxCollectTimes = collectTimes

    for i = 1, self.m_MaxQiPaoNum do
        
        self["qipao"..i]:runCsbAction("idleframe1") 
        if i <= maxCollectTimes then
            self["qipao"..i]:runCsbAction("idleframe2") 
            self["qipao"..i].m_isOpen = true
        end
    end
end

function MermaidLoadingBarView:updateActLoadingQiPao(collectTimes )
    local currShowTimes = 0
    local maxCollectTimes = collectTimes
    self.m_actPos = {}

    for i = 1, self.m_MaxQiPaoNum do
        if self["qipao"..i].m_isOpen == false then
            if currShowTimes < maxCollectTimes then
                currShowTimes = currShowTimes + 1
                -- self["qipao"..i]:runCsbAction("actionframe") 
                self["qipao"..i].m_isOpen = true
                local data = {}
                data.node = self["qipao"..i]
                data.pos = i
                table.insert(self.m_actPos,data)
                
            end
            
        end
    end

end

--默认按钮监听回调
function MermaidLoadingBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    

    if name == "click" then
        
        self.m_machine:checkShowTipView()

    end
end

return MermaidLoadingBarView