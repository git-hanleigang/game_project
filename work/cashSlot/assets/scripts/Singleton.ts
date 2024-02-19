export default class Singleton
{
    private static instance: Singleton;
    public machineScript: any = null;
    public static getInstance(): Singleton
    {
        if (!this.instance)
        {
            this.instance = new Singleton();
        }
        return this.instance;
    }

    public setMachineScript (script: any){
        this.machineScript = script
    }

    public getRandomInt(min: number, max: number): number {
        return Math.floor(Math.random() * (max - min) + min);
    }

    public checkIsSameKey(dictionary: any ,currKey: any): boolean{

        for (let i = 0; i < dictionary.length ; i++) {
          let info = dictionary[i]
          let key = info.key
          let value = info.value
          if (currKey && (currKey == key)) {
            return true
          }
        }
        return false
    }

    public getBigRow(currKey: any): number{

        for (let i = 0; i < this.bigSymbols.length ; i++) {
          let info = this.bigSymbols[i]
          let key = info.key
          let value = info.value
          if (currKey && (currKey == key)) {
            return value
          }
        }
       
        return null
    }

    public rollList: number[][] = [
        [0,1,2,3,4,5,6,7,8,90,92], // col_1
        [0,1,2,3,4,5,6,7,8,90,92], // col_2
        [0,1,2,3,4,5,6,7,8,90,92], // col_3
        [0,1,2,3,4,5,6,7,8,90,92], // col_4
        [0,1,2,3,4,5,6,7,8,90,92], // col_5
    ]
   
    public reelColAndRow: number[] = [
        3, // col_1 行数
        3, // col_2 行数
        3, // col_3 行数
        3, // col_4 行数
        3, // col_5 行数
    ];

    public bigSymbols: { key: number, value: number }[] = [
        { key: 94, value: 3 },
    ];
}


