import { _decorator, Component, Node, resources, Sprite, SpriteFrame } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('symbolNode')
export class symbolNode extends Component {
    public symbolType: number = 0
    public sprite: any = null
    public iRow: any = 0
    public iCol: any = 0
    public removePosY: any = 0

    init() {
        this.node.addComponent(Sprite)
    }

    changeSymbolNode(symbolType: number){
        let img = this.node.getComponent(Sprite)
        let path = "symbolRes/" + String(symbolType) + "/spriteFrame"
        resources.load(path, SpriteFrame, (err, spriteFrame) => {
            this.node.getComponent(Sprite).spriteFrame = spriteFrame;
        });
    }
}

