---
--xcyy
--2018年5月23日
--OZCollectMainView.lua

local OZCollectMainView = class("OZCollectMainView",util_require("base.BaseView"))


function OZCollectMainView:initUI()

    self:createCsbNode("OZ_jindutiao.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)

    
    self.m_OZCollectGirl = util_createView("CodeOZSrc.CollectGame.OZCollectGirl")
    self:findChild("girl"):addChild(self.m_OZCollectGirl)

    self.m_OZCollectDoor = util_createView("CodeOZSrc.CollectGame.OZCollectDoor")
    self:findChild("men"):addChild(self.m_OZCollectDoor)

    self.m_OZCollectDoorLight = util_createView("CodeOZSrc.CollectGame.OZCollectDoorLight")
    self:findChild("menlight"):addChild(self.m_OZCollectDoorLight)

end


function OZCollectMainView:onEnter()
 

end

function OZCollectMainView:initGirlPos(pos )
    local endPos = cc.p(self:findChild("girlEnd_" .. pos):getPosition())
    self:findChild("girl"):setPosition(endPos)

    if pos ==  1 or pos ==  3  then
    
        util_spinePlay(self.m_OZCollectGirl.m_girl,"idleframe2",true)

    elseif pos ==  2 or pos ==  4 or pos ==  5  then

        util_spinePlay(self.m_OZCollectGirl.m_girl,"idleframe",true)

    end

    self:runCsbAction("dian_" .. pos + 1)

end

function OZCollectMainView:RunGirlAct(pos,func)
    self.m_OZCollectGirl.m_FanKuiView:setLocalZOrder(100)
    self.m_OZCollectGirl.m_FanKuiView:runCsbAction("shouji_fankui_1",false,function(  )
        
        if pos ==  1 or pos ==  3 then
            util_spinePlay(self.m_OZCollectGirl.m_girl,"actionframe",false)
            util_spineEndCallFunc(self.m_OZCollectGirl.m_girl, "actionframe", function(  )
                performWithDelay(self,function(  )
                    util_spinePlay(self.m_OZCollectGirl.m_girl,"idleframe2",true)
                end,0)
                
            end)
    
        elseif pos ==  2 or pos ==  4 then
            util_spinePlay(self.m_OZCollectGirl.m_girl,"actionframe2",false)
    
            util_spineEndCallFunc(self.m_OZCollectGirl.m_girl, "actionframe2", function(  )
                performWithDelay(self,function(  )
                    util_spinePlay(self.m_OZCollectGirl.m_girl,"idleframe",true)
                end,0)
    
            end)
    
        elseif pos ==  5 then
            util_spinePlay(self.m_OZCollectGirl.m_girl,"actionframe3",false)
            util_spineEndCallFunc(self.m_OZCollectGirl.m_girl, "actionframe3", function(  )
                performWithDelay(self,function(  )
                    util_spinePlay(self.m_OZCollectGirl.m_girl,"idleframe",true)
                end,0)
            end)
    
            
        end
    
        local endPos = cc.p(self:findChild("girlEnd_" .. pos):getPosition()) 
        local moveTime = 0.5
        local actionList = {}
        actionList[#actionList + 1 ] = cc.DelayTime:create(0.2)
        actionList[#actionList + 1 ] = cc.JumpTo:create(moveTime, cc.p(endPos),10, 1)
        actionList[#actionList + 1 ] = cc.CallFunc:create(function(  )
    
            

            self:runCsbAction("dian_" .. pos .. "_" .. (pos + 1),false,function(  )
                self.m_OZCollectGirl.m_FanKuiView:setLocalZOrder(-1)
                self.m_OZCollectGirl.m_FanKuiView:runCsbAction("shouji_fankui_2")
                if func then
                    func()
                end
            end)
    
        end)
        local sq = cc.Sequence:create(actionList)
        self:findChild("girl"):runAction(sq)

    end)

   
end
function OZCollectMainView:onExit()
 
end

--默认按钮监听回调
function OZCollectMainView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return OZCollectMainView