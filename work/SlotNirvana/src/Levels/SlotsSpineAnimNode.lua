--
-- slotsNode 的 spine 动画rr
-- Author:{author}
-- Date: 2019-01-17 14:54:06
--
local SlotsSpineAnimNode = class("SlotsSpineAnimNode",cc.Node)

SlotsSpineAnimNode.m_spineNode = nil
SlotsSpineAnimNode.m_currAnimName = nil -- 当前动画名字
SlotsSpineAnimNode.m_defaultAnimName = nil -- spine动画默认名字
SlotsSpineAnimNode.m_defaultAnimLoop = nil -- 默认动画 是否 loop

function SlotsSpineAnimNode:create()
      local slotsNode = SlotsSpineAnimNode.new()
      return slotsNode
  end

function SlotsSpineAnimNode:ctor()
      self.m_spineNode = nil
      local function onNodeEvent(eventName)
          if "enter" == eventName then
              self:onEnter()
          elseif "exit" == eventName then
              self:onExit()
          end
      end
      self:registerScriptHandler(onNodeEvent)
end
--[[
    @desc: 设置 spine的 默认信息
    time:2019-01-17 18:17:35
    --@defaultAnimName: 
    --@isLoop: 动画是否loop 播放
    @return:
]]
function SlotsSpineAnimNode:initSpineInfo( defaultAnimName , isLoop  )
      if defaultAnimName == nil then
            return
      end
      self.m_defaultAnimName = defaultAnimName
      self.m_currAnimName = defaultAnimName
      self.m_defaultAnimLoop = isLoop
end

---
--
function SlotsSpineAnimNode:onEnter()
end
-- 播放默认的动画，
function SlotsSpineAnimNode:runDefaultAnim()
      if self.m_defaultAnimName == nil then
            return
      end
      self:runAnim(self.m_defaultAnimName , self.m_defaultAnimLoop , nil)
end
--
function SlotsSpineAnimNode:onExit()
      
end

function SlotsSpineAnimNode:getCurAnimRunTimes()
      if self.m_currAnimName == nil or self.m_spineNode == nil then
            return 0
      end
      return self.m_spineNode:getAnimationDurationTime(self.m_currAnimName)
end

---
-- 播放动画
-- @return 返回是否播放Anim成功
function SlotsSpineAnimNode:runAnim(animName,loop,func)

      util_spinePlay(self.m_spineNode, animName, loop)
      if func ~= nil then
            util_spineEndCallFunc(self.m_spineNode, animName, func)
      end
      return true
end

---
-- 播放动画
-- @return 返回是否播放Anim成功
function SlotsSpineAnimNode:runAnimFrame(animName,loop,frameName,func, funcEnd)

      util_spinePlay(self.m_spineNode, animName, loop)
      if func ~= nil then
            util_spineFrameCallFunc(self.m_spineNode, animName, frameName, func, funcEnd)
      end
      return true
end

function SlotsSpineAnimNode:isSameCCBName(ccbName)
      return self.m_ccbName == ccbName
end

---
-- 加载 spine 动画
-- @param ccbName string ccb名字
--
function SlotsSpineAnimNode:loadCCBNode(ccbName,symbolType,pngName)
      self.m_ccbName = ccbName
      self.p_symbolType = symbolType

      if pngName then
            self.m_spineNode = util_spineCreateDifferentPath(ccbName ,pngName, true, true)
      else
            self.m_spineNode = util_spineCreate(ccbName , true, true)   
      end
      
      self:addChild(self.m_spineNode)
end

---
-- 获取动画持续时间
--
function SlotsSpineAnimNode:getAnimDurationTime(animName)
      if animName == nil then
          return 0
      end
      -- printInfo("获取时间名字 %s",animName)
      local time= self.m_spineNode:getAnimationDurationTime(animName)
      return time
end

--获取动画播放时间线
function SlotsSpineAnimNode:getCsbAct(isReset)
      if isReset then
          -- do nothing
      end
      return self.m_spineNode
end

function SlotsSpineAnimNode:clear()
      
end

--[[
    重置时间线
]]
function SlotsSpineAnimNode:resetTimeLine()
      if tolua.isnull(self.m_spineNode) then
            return
      end
      self.m_spineNode:resetAnimation()
      util_cancelSpineEventHandler(self.m_spineNode)
end

return  SlotsSpineAnimNode