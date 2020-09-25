//
//  PlayerView.swift
//  MoviePlayer
//
//  Created by 宮崎数磨 on 2020/06/19.
//  Copyright © 2020 宮崎数磨. All rights reserved.
//

import SwiftUI
import AVKit

struct PlayerView: View {
    
//    // Whether we're currently interacting with the seek bar or doing a seek
//    @State private var seeking = false
    
    private let player: AVPlayer
    var timeObserverToken: Any?
    var videoDuration: Double = 0    //  動画ファイルの長さを示す秒数
    @State private var videoPos: Double = 0
    @State private var isRepeat = false
  
    init?() {
        // ファイル名
        let fileName = "plane"
        let fileExtension = "mp4"
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            print("Url is nil")
            return nil
        }
        player = AVPlayer(url: url)
        
        let asset = AVAsset(url: url)
        videoDuration = CMTimeGetSeconds(asset.duration) //  CMTimeを秒に変換
        
    }
  
    var body: some View {
        
        VStack {
            MoviePlayerView(player: player, isRepeat: $isRepeat)
            
            // リピートボタン
            Button(action: toggleRepeat) {
                Image(systemName: "repeat")
            }.foregroundColor(isRepeat ? .green : .gray)
            
            Slider(value: self.$videoPos,
                   in: 0...videoDuration,
                   onEditingChanged: sliderEditingChanged,
                   minimumValueLabel: Text(Utility.timeToString(time: videoPos)),
                   maximumValueLabel: Text(Utility.timeToString(time: videoDuration - videoPos)),
                   label: { EmptyView() }
            ).onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()){ _ in
                self.videoPos = Double(CMTimeGetSeconds(self.player.currentTime()))
            }
            
            MoviePlayerControlsView(itemDuration: videoDuration, player: player, videoPos: $videoPos)
        }
//        .onDisappear {
//            // When this View isn't being shown anymore stop the player
//            self.player.replaceCurrentItem(with: nil)
//        }
    }
    
    private func sliderEditingChanged(editingStarted: Bool) {
        if editingStarted {
            // Set a flag stating that we're seeking so the slider doesn't
            // get updated by the periodic time observer on the player
//            seeking = true
//            pausePlayer(true)
        }
        
        // Do the seek if we're finished
//        if !editingStarted {
            let targetTime = CMTime(seconds: videoPos,
                                    preferredTimescale: 600)
            player.seek(to: targetTime) { _ in
                // Now the seek is finished, resume normal operation
//                self.seeking = false
//                self.pausePlayer(false)
            }
//        }
    }
    
    private func toggleRepeat(){
        self.isRepeat.toggle()
    }
}

struct MoviePlayerView: UIViewRepresentable {
    let player: AVPlayer
    @Binding var isRepeat: Bool
    
    func makeUIView(context: Context) -> UIView {
        return MoviewPlayerUIView(player: player, isRepeat: $isRepeat)
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<MoviePlayerView>) {
    }
}

class MoviewPlayerUIView: UIView {
    private let player: AVPlayer
    private let playerLayer = AVPlayerLayer()
    var isRepeat:Binding<Bool>
    
    init(player: AVPlayer, isRepeat: Binding<Bool>){
        self.player = player
        self.isRepeat = isRepeat
        //他のアプリが音楽再生中であっても、その音楽は停止しない。スクリーンロックやサイレントにした場合にはこのアプリが再生するサウンドは聞こえなくなる
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [])
        } catch {
            print("Setting category to AVAudioSessionCategoryAmbient failed.")
        }
        
        super.init(frame: .zero)
        
        // はじめから再生しておきたい場合はコメントアウト外す
//        player.play()

        playerLayer.player = player
        layer.addSublayer(playerLayer)
        
        // 動画の終了時に巻き戻し再生する
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
    
    @objc private func playerItemDidReachEnd(_ notification: Notification) {
        if isRepeat.wrappedValue {
            // 動画を最初に巻き戻す
            player.currentItem?.seek(to: CMTime.zero, completionHandler: nil)
            player.play()
        }
    }
}

struct MoviePlayerControlsView : View {
//    @Binding private(set) var seeking: Bool
    
    var itemDuration: Double
    
    let player: AVPlayer
    let skipInterval: Double = 15
    
    @State private var isPaused = true
    @Binding private(set) var videoPos: Double
    
    var body: some View {
        HStack {
            
            // 早戻しボタン
            Button(action: { self.skip(interval: -self.skipInterval) }) {
                Text("早戻し")
            }
            
            Spacer()
            
            // 再生/一時停止ボタンplayerPaused ? "play" : "pause"
            Button(action: togglePlayPause) {
                Image(systemName: isPaused ? "play" : "pause")
                    .padding(.trailing, 10)
            }
            
            Spacer()
            
            // 早送りボタン
            Button(action: { self.skip(interval: self.skipInterval) }) {
                Text("早送り")
            }
            
            // Current video time
//            Text("\(Utility.formatSecondsToHMS(videoPos * videoDuration))")
            // Slider for seeking / showing video progress
//            Slider(value: $videoPos, in: 0...1, onEditingChanged: sliderEditingChanged)
            // Video duration
//            Text("\(Utility.formatSecondsToHMS(videoDuration))")
        }
        .padding(.leading, 10)
        .padding(.trailing, 10)
        .padding(.bottom, 100)
    }
    
    private func togglePlayPause() {
        pausePlayer(!isPaused)
    }
    
    private func pausePlayer(_ pause: Bool) {
        isPaused = pause
        if isPaused {
            player.pause()
        }
        else {
            player.play()
        }
    }
    
    private func skip(interval: Double) {
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let rhs = CMTimeMakeWithSeconds(interval, preferredTimescale: timeScale)
        let time = CMTimeAdd(player.currentTime(), rhs)
        
        changePosition(time: time)
    }
    
    private func changePosition(time: CMTime) {
        let rate = player.rate
        // 一旦playerをとめる
        player.rate = 0
        // 指定した時間へ移動
        player.seek(to: time, completionHandler: {_ in
            // playerをもとのrateに戻す(0より大きいならrateの速度で再生される)
            self.player.rate = rate
            self.videoPos = Double(CMTimeGetSeconds(time))
        })
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView()
    }
}


