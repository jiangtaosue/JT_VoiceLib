//
//  PlayCacheHandler.swift
//  JT_VoiceLib
//
//  Created by 江涛 on 2017/12/7.
//  Copyright © 2017年 江涛. All rights reserved.
//

import Foundation
import Moya
import RxSwift

/*
 1. 下载网络音乐文件
 2. 完整的下载则持久化在本地, 不完整的下载则放弃 并删除本地缓存
 3. 将下载的数据传输给 播放器进行播放
**/
class PlayCacheHandler: NSObject {
    
    // 进度
    var progress = Variable<Float>(0)
    
    // 路径
    var localPath = Variable<String>("")
    
    var playModel: TracksJsonModel? {
        didSet {
            if let model = playModel {
                self.checkLocal(model: model)
            }
        }
    }
    
    // MARK: - singleton
    internal static let sharedInstance = {
        return PlayCacheHandler()
    }()
    
    /// 查询本地是否有当前music 如果有，则返回本地filepath，如果没有则开始缓存
    func checkLocal(model: TracksJsonModel) {
        guard let playStr = model.playUrl32 else { return }
        
        let dataPath = JTFilePathHelper.sharedInstance.cacheFileExist(playURL: playStr)
        
        if let filePath = dataPath {
            self.localPath.value = filePath
        } else {
            // 本地无音频文件 开启下载
            self.cacheMusicData(model: model)
        }
    }
    
    /// 下载音频文件
    func cacheMusicData(model: TracksJsonModel) {
        
        let progressClosure: ProgressBlock = { response in
            // 将进度通过delegate传出
            print(response.progress)
            self.progress.value = Float(response.progress)
        }
        
        let progressCompletionClosure: Completion = { result in
            // 将下载的结果传出
            switch result {
            case .success:
                print("success")
                
                self.moveMusicToCachedFile()
            case .failure:
                print("failure")
                
                // 弹出提示框提示加载失败
            }
        }
        
        let provider = MoyaProvider<MultiTarget>()
        
        provider.request(MultiTarget.init(MusicMoya.downloadMusic(str: model.playUrl32!)), callbackQueue: DispatchQueue.main, progress: progressClosure, completion: progressCompletionClosure)
        
    }
    
    /// 将下载的音频移到缓存文件夹
    private func moveMusicToCachedFile() {
        
        if let playUrl = playModel?.playUrl32 {
            let url = URL.init(string: playUrl)!
            
            // 刚下载的音频文件路径
            let musicPath = DocDir + "/" + url.lastPathComponent
            
            // 移到缓存文件夹
            if !FileManager.default.fileExists(atPath: CachedFilePath) {
                try! FileManager.default.createDirectory(atPath: CachedFilePath, withIntermediateDirectories: true, attributes: nil)
            }
            let goalPath = CachedFilePath + "/" + url.lastPathComponent
    
            try! FileManager.default.moveItem(atPath: musicPath, toPath: goalPath)
            
            self.localPath.value = goalPath
            
        } else {
            return
        }
        
    }
    
    
}
