local BaseView = util_require("base.BaseView")

local GoldenPigCollectRewardItem = class("GoldenPigCollectRewardItem",BaseView )


function GoldenPigCollectRewardItem:initUI(data)
    self:createCsbNode("GoldenPig_jinzhu.csb")
    self:addClick(self:findChild("touch"))

    self.m_index = data.index
    self.m_row = data.row
    self.m_col = data.col
    self.m_isShowItem = true
    self.m_isClick = true
    self.m_result = nil
    self.m_lab_win = self:findChild("m_lab_win")
    self.m_lab_lost = self:findChild("m_lab_lost")

    self:runCsbAction("idleframe")
end

function GoldenPigCollectRewardItem:onEnter()

end

function GoldenPigCollectRewardItem:onExit()

end

function GoldenPigCollectRewardItem:getItemIndex()
    return self.m_index
end

function GoldenPigCollectRewardItem:getItemRow()
    return self.m_row
end

function GoldenPigCollectRewardItem:getItemCol()
    return self.m_col
end

function GoldenPigCollectRewardItem:setClickFunc(func)
    self.m_func = func
end

function GoldenPigCollectRewardItem:getItemResult()
    return self.m_result
end

function GoldenPigCollectRewardItem:showItemStart()
	self.m_isShowItem = false
    self.m_isClick = false

    self:runCsbAction("start", true)
end

function GoldenPigCollectRewardItem:showItemIdle()
    self.m_isShowItem = true
    self.m_isClick = true

    self:runCsbAction("idleframe9")
end

function GoldenPigCollectRewardItem:showChooseResult(result, callBackFun)
    self.m_isShowItem = true
    self.m_isClick = true
    self.m_result = result

    local animation = "click_win"
    if result.type == "allwin" then
        animation = "click_all"
    elseif result.type == "end" then
        animation = "click_end"
    else
        self.m_lab_win:setString(result.value .. "X")
    end
    
    self:runCsbAction(animation, false, function()
        if callBackFun then
            callBackFun()
        end
    end)
end

function GoldenPigCollectRewardItem:showUnChooseResult(result, callBackFun)
    self.m_isShowItem = true
    self.m_isClick = true
    self.m_result = result

    local animation = "over_lost"
    if result.type == "allwin" then
        animation = "over_all"
    elseif result.type == "end" then
        animation = "over_end"
    else
        self.m_lab_lost:setString(result.value .. "X")
    end

    self:runCsbAction(animation, false, function()
        if callBackFun then
            callBackFun()
        end
    end)
end

function GoldenPigCollectRewardItem:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "touch" then
        if self.m_isClick or self.m_isShowItem then
        	return
    	end

        self.m_func()
        
        --放在下面 不然m_result没赋值(m_func里面做的赋值操作)
        if self.m_result then
            if self.m_result.type == "end" then
                gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_collect_click_over.mp3")
            else
                gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_collect_click_pig.mp3")
            end
        end
    end
end

return GoldenPigCollectRewardItem