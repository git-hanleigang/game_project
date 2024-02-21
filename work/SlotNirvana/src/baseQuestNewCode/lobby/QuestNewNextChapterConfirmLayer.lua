----
local QuestNewNextChapterConfirmLayer = class("QuestNewNextChapterConfirmLayer", BaseLayer)


function QuestNewNextChapterConfirmLayer:getCsbNodePath()
    return QUESTNEW_RES_PATH.QuestNewNextChapterConfirmLayer
end

function QuestNewNextChapterConfirmLayer:initDatas(reward)
    self.m_rewards = reward --{coins items}
end
-- 弹窗动画
function QuestNewNextChapterConfirmLayer:playShowAction()
    local userDefAction = function(callFunc)
        gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
        self:runCsbAction(
            "start",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    QuestNewNextChapterConfirmLayer.super.playShowAction(self, userDefAction)
end

function QuestNewNextChapterConfirmLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function QuestNewNextChapterConfirmLayer:initCsbNodes()
    self.m_nodeReward = self:findChild("node_reward")
    self.m_btnCollect = self:findChild("btn_collect")
    self.m_lb_coin = self:findChild("lb_coin")
    
end

function QuestNewNextChapterConfirmLayer:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_start" then
        -- body
    elseif name == "btn_later" or name == "btn_close" then
        if self.m_bTouch then
            return
        end
        self.m_bTouch = true
        self:closeUI()
    end
end

return QuestNewNextChapterConfirmLayer
