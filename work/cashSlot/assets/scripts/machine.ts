import { _decorator, Component, Event, Node, Button, EventHandler } from 'cc';
import Singleton from './Singleton';
import { reelRoll } from './reelRoll';
const { ccclass, property } = _decorator;

@ccclass('machine')
export class machine extends Component {
    public singleton: Singleton = Singleton.getInstance()
    private buttonSpin: any = null;
    private buttonStop: any = null;
    public colNum: number = null; // 行配置
    public stopIndex: number = null; // 行停止计数
    start() {
        this.colNum = this.singleton.reelColAndRow.length
        this.singleton.setMachineScript(this)
        this.buttonSpin = this.node.getChildByName("spinBtn").getComponent(Button)
        this.buttonStop = this.node.getChildByName("stopBtn").getComponent(Button)

        //设置当前列
        for (let index = 0; index < this.colNum; index++) {
            let rollNode = this.getReelRoll(index)
            let scrip = rollNode.getComponent(reelRoll)
            scrip.setReelIndex(index)
        }

        //初始化按钮状态
        this.setBtnState(true, false)
    }

    update(deltaTime: number) {
        
    }

    callback (event: Event, costomEventData: string) {
        let button = event.target as Node;
        let buttonName = button.name
        if (buttonName == "spinBtn"){
            console.log("开始spin")
            this.startSpin()
        }
        else if (buttonName == "stopBtn"){
            console.log("停止stop")
            this.stopSpin(true)
        }
    }

    getReelRoll(index: number){
        let reelNode = this.node.getChildByName("Mask").getChildByName("reel_"+index)
        return reelNode
    }

    startSpin() {
        this.stopIndex = 0
        for (let index = 0; index < this.colNum; index++){
            let rollNode = this.getReelRoll(index)
            let reelScript = rollNode.getComponent(reelRoll)
            reelScript.beginReel()
        }
        this.setBtnState(false, true)
    }

    reelStopFunc(index: number){
        this.stopIndex = this.stopIndex + index
        if (this.stopIndex >= this.colNum){
            this.stopSpin(false)
            this.setBtnState(true, false)
        }
    }

    stopSpin(isQuickStop: boolean){
        for (let index = 0; index < this.colNum; index++){
            let rollNode = this.getReelRoll(index)
            let reelScript = rollNode.getComponent(reelRoll)
            reelScript.quickStop = isQuickStop
        }
        this.setBtnState(true, false)
    }

    setBtnState(spinBtnState:boolean, stopBtnState:boolean){
        this.buttonSpin.interactable = spinBtnState
        this.buttonStop.interactable = stopBtnState
    }
}

