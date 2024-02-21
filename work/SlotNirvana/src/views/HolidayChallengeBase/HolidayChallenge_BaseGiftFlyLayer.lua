local BaseView = require("base.BaseView")
local HolidayChallenge_BaseGiftFlyLayer = class("HolidayChallenge_BaseGiftFlyLayer", BaseView)

function HolidayChallenge_BaseGiftFlyLayer:initUI(_addNum)
    HolidayChallenge_BaseGiftFlyLayer.super.initUI(self)
    self:initView(_addNum)
end

function HolidayChallenge_BaseGiftFlyLayer:getCsbName()
    return self.m_activityConfig.RESPATH.GIFTFLY_LAYER
end

function HolidayChallenge_BaseGiftFlyLayer:initDatas()
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
end

function HolidayChallenge_BaseGiftFlyLayer:initCsbNodes()
    self.m_nodeFly = self:findChild("ef_node_star_fly")

    --self.m_nodeSpine = self:findChild("node_spine")
end

function HolidayChallenge_BaseGiftFlyLayer:initView(_addNum)
    local config = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    -- csc 2022-01-20 12:24:06
    -- 创建 过场spine 动画
    -- local flyNpc = util_spineCreate(config.RESPATH.FLY_NPC, false, true)
    -- util_spinePlay(flyNpc, "run", false)
    -- self.m_nodeSpine:addChild(flyNpc)
    -- flyNpc:setPosition(cc.p(0, -display.height /2 - 200  ))

    -- 播放音效
    --gLobalSoundManager:playSound(G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig().RESPATH.NPC_GUOCHANG_MP3)

    local addPlist = function ()
        self.m_flyNode = util_createAnimation(config.RESPATH.GIFTFLY_NODE)
        local starNum = self.m_flyNode:getChildByName("Node"):getChildByName("lb_number"):getChildByName("lb_number")
        starNum:setString("X".._addNum)
        self.m_nodeFly:addChild(self.m_flyNode) 


        self.m_flyNode:playAction(
        "start",
        false,
        function()
            self.m_pilstNode = util_csbCreate(config.RESPATH.FLY_PLISY_NODE)
            self.m_flyNode:addChild(self.m_pilstNode) 
            local plist = self.m_pilstNode:getChildByName("Particle_1")
            self.m_pilstNode = plist
            if plist then
                plist:resetSystem()
                plist:setDuration(1/60 * 60)     --设置拖尾时间(生命周期)
                plist:setPositionType(0)   --设置可以拖尾
            end

            -- 开始移动
            self:playMoveStarFlyNode()
            -- 播放星星飞行动画
            self.m_flyNode:playAction(
                "fly",
                false,
                nil,
                60
            )
        end,
        60
    )
    end
    -- 30 帧左右添加飞行节点
    performWithDelay(self,addPlist,1/60*1)

    -- util_spineEndCallFunc(flyNpc,"run",function()
    --     util_nextFrameFunc(
    --             function()
    --                 -- 超级碗版本问题 spine 动画长度没有 flynode 的显示时间长，所以回调让 飞行动画来控制
    --                 -- if self.m_callback then
    --                 --     self.m_callback()
    --                 -- end
    --                 -- self:removeFromParent()
    --             end
    --         )
    -- end)

    -- 播放本身的动画
    self:runCsbAction("actionframe", false, nil, 60)
 
    gLobalSoundManager:playSound(G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig().RESPATH.GIFT_FLYSHOW_MP3)
end

function HolidayChallenge_BaseGiftFlyLayer:setMoveActionParam(_endPos,_callback)
    self.m_endPos = _endPos
    self.m_callback = _callback
end

function HolidayChallenge_BaseGiftFlyLayer:playMoveStarFlyNode()
    local time = 1 / 60 * 35 -- csb 动画是30帧
    -- local nodePos = self:convertToNodeSpace(self.m_endPos)
    -- nodePos.y = nodePos.y - self.m_nodeFly:getPositionY() + 60
    -- local moveAct = cc.MoveTo:create(time, nodePos)
    -- self.m_flyNode:runAction(cc.Sequence:create({moveAct}))

    local nodePos = self:convertToNodeSpace(self.m_endPos)
    --csb 制作问题，有一个偏移量
    nodePos.y = nodePos.y - self.m_nodeFly:getPositionY() + 30
    local moveAct = cc.MoveTo:create(time, nodePos)
    local delayCall = cc.CallFunc:create(
        function()
            if self.m_pilstNode then
                self.m_pilstNode:stopSystem()
            end
            if self.m_callback then
                self.m_callback()
            end
            -- 播放音效
            --gLobalSoundManager:playSound(G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig().RESPATH.GIFT_LIGHT_MP3)
        end
    ) 
    local delay1 = cc.DelayTime:create(0.4)
    local moveEndCallBack = cc.CallFunc:create(
        function()
            self:removeFromParent()
        end
    )
    self.m_flyNode:runAction(cc.Sequence:create({moveAct,delayCall,delay1,moveEndCallBack}))
end

return HolidayChallenge_BaseGiftFlyLayer
