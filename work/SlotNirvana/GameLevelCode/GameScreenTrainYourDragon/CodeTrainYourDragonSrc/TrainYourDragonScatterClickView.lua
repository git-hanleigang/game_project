
-- FIX IOS 139 1
local TrainYourDragonScatterClickView = class("TrainYourDragonScatterClickView",util_require("base.BaseView"))

function TrainYourDragonScatterClickView:initUI()
    self:createCsbNode("Socre_TrainYourDragon_ScatterClicked.csb")
    self:addClick(self:findChild("scatterClicked"))
end

function TrainYourDragonScatterClickView:onEnter()

end
function TrainYourDragonScatterClickView:onExit()
 
end
function TrainYourDragonScatterClickView:initColRow(col,row)
    self.m_col = col
    self.m_row = row
end

--默认按钮监听回调
function TrainYourDragonScatterClickView:clickFunc(sender)
    local name = sender:getName()
    gLobalNoticManager:postNotification("CodeGameScreenTrainYourDragonMachine_scatterClicked",{self.m_col,self.m_row}) 
end

return TrainYourDragonScatterClickView