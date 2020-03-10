import React, { Component } from "react";
import { findNodeHandle, requireNativeComponent, UIManager } from "react-native";
const AliyunPlayer = requireNativeComponent("AliyunPlay", AliyunPlayView);
export var EAliYunVideoEventType;
(function (EAliYunVideoEventType) {
    EAliYunVideoEventType[EAliYunVideoEventType["AliyunVodPlayerEventPrepareDone"] = 0] = "AliyunVodPlayerEventPrepareDone";
    EAliYunVideoEventType[EAliYunVideoEventType["AliyunVodPlayerEventPlay"] = 1] = "AliyunVodPlayerEventPlay";
    EAliYunVideoEventType[EAliYunVideoEventType["AliyunVodPlayerEventFirstFrame"] = 2] = "AliyunVodPlayerEventFirstFrame";
    EAliYunVideoEventType[EAliYunVideoEventType["AliyunVodPlayerEventPause"] = 3] = "AliyunVodPlayerEventPause";
    EAliYunVideoEventType[EAliYunVideoEventType["AliyunVodPlayerEventStop"] = 4] = "AliyunVodPlayerEventStop";
    EAliYunVideoEventType[EAliYunVideoEventType["AliyunVodPlayerEventFinish"] = 5] = "AliyunVodPlayerEventFinish";
    EAliYunVideoEventType[EAliYunVideoEventType["AliyunVodPlayerEventBeginLoading"] = 6] = "AliyunVodPlayerEventBeginLoading";
    EAliYunVideoEventType[EAliYunVideoEventType["AliyunVodPlayerEventEndLoading"] = 7] = "AliyunVodPlayerEventEndLoading";
    EAliYunVideoEventType[EAliYunVideoEventType["AliyunVodPlayerEventSeekDone"] = 8] = "AliyunVodPlayerEventSeekDone";
})(EAliYunVideoEventType || (EAliYunVideoEventType = {}));
export default class AliyunPlayView extends Component {
    constructor() {
        super(...arguments);
        this.stop = () => {
            this.sendCommand("stop");
        };
        this.pause = () => {
            this.sendCommand("pause");
        };
        this.resume = () => {
            this.sendCommand("resume");
        };
        this.reset = () => {
            this.sendCommand("reset");
        };
        this.rePlay = () => {
            this.sendCommand("rePlay");
        };
        this.seekToTime = time => {
            this.sendCommand("seekToTime", [time]);
        };
    }
    sendCommand(command, params = []) {
        UIManager.dispatchViewManagerCommand(findNodeHandle(this), UIManager.getViewManagerConfig("AliyunPlay").Commands[command], params);
    }
    render() {
        return <AliyunPlayer {...this.props}/>;
    }
}
export * from "./AliyunVodDownloader";
//# sourceMappingURL=AliyunPlayView.js.map