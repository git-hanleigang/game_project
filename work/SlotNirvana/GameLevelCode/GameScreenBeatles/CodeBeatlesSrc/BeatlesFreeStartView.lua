
--BeatlesFreeStartView.lua
local BaseGame = util_require("base.BaseGame")
local BeatlesFreeStartView = class("BeatlesFreeStartView",BaseGame )

function BeatlesFreeStartView:onEnter()

end

function BeatlesFreeStartView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function BeatlesFreeStartView:initUI(machine)
    self.m_machine = machine

    self.func1 = self.m_machine.freeStartFunc1 or nil
    -- self.func2 = self.m_machine.freeStartFunc2 or nil

    local levels = self.m_machine.m_runSpinResultData.p_selfMakeData.level

    self:createCsbNode("Beatles/FreeSpinStart.csb")
    self:runCsbAction("idle", false)
    
    self.FreeSpinStartSpine = util_spineCreate("FreeSpinStart", true, true)
    self:findChild("spine"):addChild(self.FreeSpinStartSpine)

    -- 文字
    self.num_bar = util_createAnimation("Beatles_fonts_FGstart.csb")
    util_spinePushBindNode(self.FreeSpinStartSpine,"wenzi",self.num_bar)
    self.num_bar:findChild("m_lb_nums"):setString(self.m_machine.m_iFreeSpinTimes)
    self.num_bar:runCsbAction("start", false, function()
        self.num_bar:runCsbAction("idle", true)
    end)

    --按钮
    self.button_bar = util_createAnimation("Beatles_button_FGstart.csb")
    util_spinePushBindNode(self.FreeSpinStartSpine,"anniu",self.button_bar)
    self.button_bar:runCsbAction("start", false, function()
        self.button_bar:runCsbAction("idle", true)
    end)

    -- 玩法说明文字
    self.tips_bar = util_createAnimation("Beatles_Shop_FreeStartTips.csb")
    util_spinePushBindNode(self.FreeSpinStartSpine,"wenzi2",self.tips_bar)

    util_setCascadeOpacityEnabledRescursion(self.tips_bar:findChild("Node_root"), true)
    util_setCascadeColorEnabledRescursion(self.tips_bar:findChild("Node_root"), true)

    self.tips_bar:runCsbAction("start", false, function()
        self.tips_bar:runCsbAction("idle", true)
    end)
    
    self:showTips(levels)

    -- self:addClick(self.button_bar:findChild("Button_1"))
    self:addClick(self:findChild("anniuClick"))

    util_spinePlay(self.FreeSpinStartSpine, "start", false)
    util_spineEndCallFunc(self.FreeSpinStartSpine, "start", function()
        util_spinePlay(self.FreeSpinStartSpine, "idle", true)
        -- self.m_mask:setVisible(true)
    end)

end

function BeatlesFreeStartView:showTips(levels )
    local selfMakeData = self.m_machine.m_runSpinResultData.p_selfMakeData
    local storeData = selfMakeData and selfMakeData.store.storeData or nil

    local tipsNum = 0
    local tipsTable = {}
    for i,v in ipairs(levels) do
        if i > 1 and v > 0 then
            tipsNum = tipsNum + 1
            table.insert(tipsTable, i-1)
        end
    end

    for i=1,5 do
        self.tips_bar:findChild(i.."kinds"):setVisible(false)
    end
    if tipsNum == 0 then
        self.tips_bar:findChild("1kinds"):setVisible(true)
        self.tips_bar:findChild("tip1_1"):addChild(util_createAnimation("Beatles_shop_FeatureTips0.csb"))

    else
        self.tips_bar:findChild(tipsNum.."kinds"):setVisible(true)
        for index, id in ipairs(tipsTable) do
            local tipsNode = util_createAnimation("Beatles_shop_FeatureTips"..id..".csb")
            if tipsNum == 1 and id == 3 then
                self.tips_bar:findChild("Node_SymbolReplaced"):addChild(tipsNode)
            else
                self.tips_bar:findChild("tip"..tipsNum.."_"..index):addChild(tipsNode)
            end
            if id == 1 then
                tipsNode:findChild("m_lb_nums"):setString(storeData.buy_num["bonusType"..id][levels[id+1]+1].."X")
            else
                tipsNode:findChild("m_lb_nums"):setString(storeData.buy_num["bonusType"..id][levels[id+1]+1])
            end
        end
    end
end

--默认按钮监听回调
function BeatlesFreeStartView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name ==  "anniuClick" then
        if self.func1 then
            local actionList={}
            actionList[#actionList+1] = cc.ScaleTo:create(0.05, 0.9)
            actionList[#actionList+1] = cc.ScaleTo:create(0.05, 1)
            self.button_bar:findChild("Button_1"):runAction(cc.Sequence:create(actionList))

            self:findChild("anniuClick"):setTouchEnabled(false)

            performWithDelay(self,function( )
                self.func1()

                performWithDelay(self,function( )
                    util_spinePlay(self.FreeSpinStartSpine, "over", false)
                    self.button_bar:runCsbAction("over", false)
                    self.num_bar:runCsbAction("over", false)
                    self.tips_bar:runCsbAction("over", false)

                    performWithDelay(self,function( )
                        self.m_machine:showOpenOrCloseShop(false)
                    end,8/60)
                end,45/60)
            end,0.1)
            
        end
    end

end

return BeatlesFreeStartView