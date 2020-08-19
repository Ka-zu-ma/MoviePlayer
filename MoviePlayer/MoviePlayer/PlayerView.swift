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
    var body: some View {
        return PlayerContainerView()
    }
}

struct MoviePlayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> UIView {
        return MoviewPlayerUIView(player: player)
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<MoviePlayerView>) {
    }
}

struct SeekBar: UIViewRepresentable {
    let player: AVPlayer
    let slider: UISlider
    
    func makeUIView(context: Context) -> UIView {
        return Slider(player: player, slider: slider)
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<SeekBar>) {
    }
}

class Slider: UIView {
    private let player: AVPlayer
    private let slider: UISlider
    
    init(player: AVPlayer, slider: UISlider){
        self.player = player
        self.slider = slider
        super.init(frame: .zero)
        self.addSubview(slider)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 画面幅いっぱいに広がる
        slider.frame = bounds
    }
}

class MoviewPlayerUIView: UIView {
    private let player: AVPlayer
    private let playerLayer = AVPlayerLayer()
    
    init(player: AVPlayer){
        self.player = player
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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

struct MoviePlayerControlsView : View {
//    @Binding private(set) var videoPos: Double
//    @Binding private(set) var videoDuration: Double
//    @Binding private(set) var seeking: Bool
    
    let player: AVPlayer
    let skipInterval: Double = 15
    
    @State private var playerPaused = true
    
    var body: some View {
        HStack {
            
            // 早戻しボタン
            Button(action: { self.skip(interval: -self.skipInterval) }) {
                Text("早戻し")
            }
            
            Spacer()
            
            // 再生/一時停止ボタン
            Button(action: togglePlayPause) {
                Image(systemName: playerPaused ? "play" : "pause")
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
        pausePlayer(!playerPaused)
    }
    
    private func pausePlayer(_ pause: Bool) {
        playerPaused = pause
        if playerPaused {
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
        })
    }
    
    //TODO:ここから
//    func addPeriodicTimeObserver() {
//        // Notify every half second
//        let timeScale = CMTimeScale(NSEC_PER_SEC)
//        let time = CMTime(seconds: 0.5, preferredTimescale: timeScale)
//
//        timeObserverToken = player.addPeriodicTimeObserver(forInterval: time,
//                                                           queue: .main)
//        { [weak self] time in
//            // update player transport UI
//            DispatchQueue.main.async {
//                print("update timer:\(CMTimeGetSeconds(time))")
//                // sliderを更新
//                self?.updateSlider()
//            }
//        }
//    }
    
//    private func sliderEditingChanged(editingStarted: Bool) {
//        if editingStarted {
//            // Set a flag stating that we're seeking so the slider doesn't
//            // get updated by the periodic time observer on the player
//            seeking = true
//            pausePlayer(true)
//        }
//
//        // Do the seek if we're finished
//        if !editingStarted {
//            let targetTime = CMTime(seconds: videoPos * videoDuration,
//                                    preferredTimescale: 600)
//            player.seek(to: targetTime) { _ in
//                // Now the seek is finished, resume normal operation
//                self.seeking = false
//                self.pausePlayer(false)
//            }
//        }
//    }
}





struct PlayerContainerView : View {
//    // The progress through the video, as a percentage (from 0 to 1)
//    @State private var videoPos: Double = 0
//    // The duration of the video in seconds
//    @State private var videoDuration: Double = 0
//    // Whether we're currently interacting with the seek bar or doing a seek
//    @State private var seeking = false
    
    private let player: AVPlayer
    private let slider: UISlider
  
    init?() {
        // ファイル名
        let fileName = "steinsgateop"
        let fileExtension = "mp4"
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            print("Url is nil")
            return nil
        }
        player = AVPlayer(url: url)
        slider = UISlider()
        slider.minimumValue = 0;
        slider.maximumValue = 100;
        slider.value = 0;
    }
  
    var body: some View {
        VStack {
            MoviePlayerView(player: player)
            SeekBar(player: player, slider: slider)
            MoviePlayerControlsView(player: player)
        }
//        .onDisappear {
//            // When this View isn't being shown anymore stop the player
//            self.player.replaceCurrentItem(with: nil)
//        }
    }
}


struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView()
    }
}


