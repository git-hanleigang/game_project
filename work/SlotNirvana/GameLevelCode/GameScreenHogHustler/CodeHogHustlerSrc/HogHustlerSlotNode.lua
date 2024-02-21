
local HogHustlerSlotNode = class("HogHustlerSlotNode",util_require("Levels.SlotsNode"))

---
-- 播放连线时的动画
--
function HogHustlerSlotNode:runLineAnim()

      HogHustlerSlotNode.super.runLineAnim(self)

      --连线时隐藏score
      if self.p_symbolType == 93 then
            local aniNode = self:checkLoadCCbNode()
            local spine = aniNode.m_spineNode
            if spine then
                  if spine.m_scoreViewNode then
                        if tolua.isnull(spine.m_scoreViewNode) then
                              release_print("HogHustlerSlotNode:runLineAnim null 11 Error!!!")
                        else
                              if tolua.isnull(spine.m_scoreViewNode.m_csbAct) then
                                    release_print("HogHustlerSlotNode:runLineAnim null 22 Error!!!")
                              else
                                    spine.m_scoreViewNode:runCsbAction("actionframe", false)
                              end

                              -- util_nodeFadeIn(spine.m_scoreViewNode, 0.1, 255, 0)
                              -- util_playFadeOutAction(spine.m_scoreViewNode, 0.1)
                        end
                  end
            end
      end
      
end

function HogHustlerSlotNode:runIdleAnim()
      if self.p_idleIsLoop == nil then
            self.p_idleIsLoop = false
      end

      local csbNode = self:getCCBNode()
      if csbNode ~= nil then  -- 不用图片代替时才会直接播放默认动画
            self:runAnim(self:getIdleAnimName(),self.p_idleIsLoop)


            --改
            --不连线时显示score
            if self.p_symbolType == 93 then
                  local aniNode = self:checkLoadCCbNode()
                  local spine = aniNode.m_spineNode
                  if spine then
                        if spine.m_scoreViewNode then
                              if tolua.isnull(spine.m_scoreViewNode) then
                                    release_print("HogHustlerSlotNode:runIdleAnim null 11 Error!!!")
                              else
                                    if tolua.isnull(spine.m_scoreViewNode.m_csbAct) then
                                          release_print("HogHustlerSlotNode:runIdleAnim null 22 Error!!!")
                                    else
                                          spine.m_scoreViewNode:runCsbAction("idleframe", true)
                                    end

                                    -- spine.m_scoreViewNode:setOpacity(255)
                              end
                        end
                  end
            end
      end

end

return HogHustlerSlotNode